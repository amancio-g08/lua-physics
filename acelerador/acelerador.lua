-- acelerador.lua
-- magnetiza uma barra, monta um solenoide no foguete, passa por varios
-- aneis magneticos e no fim compara com o estilingue gravitacional
-- como rodar (no terminal, dentro da pasta lua-physics):
--   lua acelerador/acelerador.lua
--
-- dica de lua pra quem ta comecando:
--   "--" comeca um comentario. o lua ignora tudo depois dele na linha.
--   "local x = 5" cria uma variavel chamada x valendo 5.
--   "function nome(a) ... end" cria uma funcao (uma conta que da pra reusar).
--   "x^2" eh x ao quadrado. "math.sqrt(x)" eh a raiz quadrada de x.


-- ===================================================================
-- constantes da natureza
-- ===================================================================

-- velocidade da luz em metros por segundo.
-- o ".0" no final deixa o numero "com virgula" (float). se fosse inteiro,
-- uma conta tipo C * C ficaria grande demais e daria resultado errado no lua 5.4.
local C = 299792458.0

-- permeabilidade do vacuo: o quanto o espaco vazio "deixa passar" campo magnetico
local MU0 = 4e-7 * math.pi   -- 4e-7 quer dizer 4 x 10^-7


-- ===================================================================
-- parametros (mexe aqui pra testar outros valores)
-- ===================================================================
-- uma "tabela" no lua eh uma caixa com varios valores com nome.
-- depois a gente acessa com ponto: solenoide.n, solenoide.I ...

local solenoide = {
  n = 1000,       -- espiras (voltas de fio) por metro
  I = 1000,       -- corrente eletrica no fio, em amperes
  mur = 1,        -- material dentro da bobina (1 = ar; ferro seria ~1000)
  raio = 0.1,     -- raio do anel, em metros
  comp = 0.5,     -- comprimento do anel, em metros
  eta = 0.30,     -- eficiencia: so 30% da energia do campo vira movimento
  massa = 1000,   -- massa do foguete, em kg
}

-- jupiter, pro estilingue gravitacional
local jupiter = {
  U = 13.07e3,    -- velocidade de jupiter em volta do sol (m/s)
  GM = 1.267e17,  -- constante da gravidade x massa de jupiter
  R = 6.991e7,    -- raio de jupiter (m)
}


-- ===================================================================
-- funcoes
-- ===================================================================

-- campo magnetico dentro do solenoide: B = n * mu * I
-- mais voltas de fio (n), mais corrente (I) ou material melhor (mu) = campo maior
local function campo(s)
  local B = MU0 * s.mur * s.n * s.I
  -- o ferro "enche" (satura) perto de 2 tesla: dali pra cima nao ajuda mais
  if s.mur > 1 and B > 2 then
    B = 2
  end
  return B
end

-- fluxo magnetico: quanto campo "atravessa" o buraco do anel
--   fluxo = B * A * cos(theta)
--   A     = area do buraco do anel (pi * raio^2)
--   theta = inclinacao do anel. 0 = de frente pro campo (fluxo maximo),
--           90 = de lado (nenhuma linha de campo atravessa, fluxo zero)
-- a unidade eh o weber (Wb) = tesla x metro quadrado
local function fluxo(B, raio, theta)
  local A = math.pi * raio^2
  return B * A * math.cos(math.rad(theta))   -- math.rad: graus -> radianos
end

-- energia guardada no campo de um anel:
--   energia = eta * B^2 / (2 * mu0) * volume
-- B^2 / (2 * mu0) eh quanta energia cabe em cada metro cubico de campo
local function energia_anel(s)
  local B = campo(s)
  local volume = math.pi * s.raio^2 * s.comp   -- volume de um cilindro
  return s.eta * B^2 / (2 * MU0) * volume
end

-- velocidade (beta = v/c) do jeito certo, com relatividade.
-- x = energia que o foguete ganhou dividida por m*c^2 (a "energia de repouso")
-- gamma = 1 + x   (gamma eh o fator de lorentz)
-- beta  = raiz(1 - 1/gamma^2)
-- escrevi a mesma conta de outro jeito pra nao dar erro de arredondamento
-- quando x eh muito pequeno. o resultado NUNCA passa de 1 (a luz eh o limite).
local function beta(x)
  return math.sqrt(x * (x + 2)) / (1 + x)
end

-- a mesma coisa do jeito antigo (newton): (1/2) m v^2 = energia -> beta = raiz(2x)
-- serve so pra comparar: esse passa de 1, o que eh impossivel na vida real
local function beta_newton(x)
  return math.sqrt(2 * x)
end

-- quantos aneis precisa pra chegar numa velocidade b,
-- se cada anel da uma fracao "eps" de m*c^2
local function aneis_para(b, eps)
  local gamma = 1 / math.sqrt(1 - b^2)
  return (gamma - 1) / eps
end

-- estilingue gravitacional: a nave passa raspando no planeta.
-- visto pelo planeta, a nave chega e sai com a MESMA velocidade, so muda de direcao.
-- mas o planeta ta se movendo em volta do sol, entao visto pelo sol
-- essa curva vira ganho de velocidade (a nave "pega carona" no planeta).
--   v     = velocidade da nave antes
--   P     = o planeta (tabela com U, GM, R)
--   rp    = quao perto ela passa do centro do planeta
--   theta = angulo de chegada (0 = de frente)
local function sobrevoo(v, P, rp, theta)
  -- velocidade da nave vista pelo planeta (x e y)
  local ux = -v * math.cos(theta) - P.U
  local uy = v * math.sin(theta)
  local u = math.sqrt(ux^2 + uy^2)

  -- o quanto a gravidade consegue entortar o caminho
  local e = 1 + rp * u^2 / P.GM   -- excentricidade: formato da curva (hiperbole)
  local d = 2 * math.asin(1 / e)  -- angulo maximo que ela vira

  -- testa virar pra um lado e pro outro, e fica com o que der mais velocidade
  local melhor = 0
  for _, lado in ipairs({1, -1}) do
    local c = math.cos(lado * d)
    local sn = math.sin(lado * d)
    -- gira o vetor velocidade e volta pro ponto de vista do sol (+ P.U)
    local wx = ux * c - uy * sn + P.U
    local wy = ux * sn + uy * c
    melhor = math.max(melhor, math.sqrt(wx^2 + wy^2))
  end
  return melhor, d   -- o lua deixa devolver dois valores de uma vez
end

-- formula pronta do estilingue gravitacional (imagens/estilingue.webp):
--   vf = (vi + 2U) * raiz( 1 - 4*vi*U*(1 - cos(theta)) / (vi + 2U)^2 )
--   vi    = velocidade da nave antes (m/s)
--   U     = velocidade do planeta (m/s)
--   theta = angulo em graus. com theta = 0 a nave da a volta completa e sai
--           com vi + 2U, o maximo possivel
local function estilingue(vi, U, theta)
  local t = math.rad(theta)   -- o lua faz cos em radianos, entao converte
  return (vi + 2 * U) * math.sqrt(1 - 4 * vi * U * (1 - math.cos(t)) / (vi + 2 * U)^2)
end


-- ===================================================================
-- 1) magnetizando a barra (metodo de inducao)
-- ===================================================================
-- uma barra de ferro eh cheia de "dominios": pedacinhos que funcionam como
-- mini imas. no comeco cada um aponta pra um lado e um cancela o outro.
-- passando um ima pela barra, os dominios vao girando pro mesmo lado.
--
-- aqui a barra tem 1000 dominios com direcao sorteada.
-- a cada passada do ima, cada dominio gira metade do caminho ate ficar alinhado.
-- alinhamento = media de cos(angulo) de todos:
--   0 = baguncado (nao eh ima), 1 = todos alinhados (ima no maximo)
-- o ferro todo alinhado da uns 2 tesla, entao B da barra = 2 * alinhamento

print("-- 1) magnetizando a barra --")
math.randomseed(42)   -- fixa o sorteio, pra saida ser sempre a mesma
local dominios = {}   -- tabela vazia que vai guardar o angulo de cada dominio
for i = 1, 1000 do
  -- math.random() sorteia um numero entre 0 e 1.
  -- assim o angulo fica entre -180 e +180 graus (em radianos: -pi e +pi)
  dominios[i] = (math.random() * 2 - 1) * math.pi
end

-- "for passada = 0, 5 do" repete o bloco 6 vezes, com passada = 0, 1, 2 ... 5
-- string.format monta o texto: %d = inteiro, %.3f = numero com 3 casas
for passada = 0, 5 do
  local soma = 0
  for i = 1, #dominios do   -- #dominios = quantos itens tem na tabela (1000)
    soma = soma + math.cos(dominios[i])
  end
  local alinhamento = soma / #dominios
  print(string.format("passada %d  alinhamento %.3f  B da barra = %.2f T",
    passada, alinhamento, 2 * alinhamento))

  -- passa o ima: cada dominio gira metade do caminho ate o angulo 0
  for i = 1, #dominios do
    dominios[i] = dominios[i] / 2
  end
end


-- ===================================================================
-- 2) solenoide: 2 voltas de fio em volta do foguete
-- ===================================================================
-- B = n * mu * I. com o fio enrolado so no ar o campo eh fraquinho.
-- colocando a barra de ferro magnetizada dentro (o "nucleo"), mu fica ~1000
-- vezes maior e o campo vai la pra cima (ate o ferro saturar em 2 T).
-- eh isso que transforma o foguete num ima.

print("\n-- 2) solenoide (n = 2, I = 1000 A) --")   -- "\n" pula uma linha
local so_ar = { n = 2, I = 1000, mur = 1 }
local com_ferro = { n = 2, I = 1000, mur = 1000 }
print(string.format("so ar:            B = %.4f T", campo(so_ar)))
print(string.format("com nucleo ferro: B = %.4f T (satura em 2 T)", campo(com_ferro)))


-- ===================================================================
-- 3) fluxo magnetico no anel (imagens/anel.webp)
-- ===================================================================
-- usando o anel do solenoide real la de cima.
-- quando o foguete-ima passa pelo anel, esse fluxo muda, e campo que muda
-- gera corrente (lei de faraday). eh essa interacao que empurra o foguete.

print("\n-- 3) fluxo no anel (raio 0.1 m) --")
local B_anel = campo(solenoide)
for _, theta in ipairs({0, 30, 45, 60, 90}) do
  print(string.format("theta %2d graus  fluxo = %.4f Wb", theta, fluxo(B_anel, solenoide.raio, theta)))
end


-- ===================================================================
-- 4) foguete saindo dos aneis a 4197261 m/s
-- ===================================================================
-- 4197261 m/s (uns 4200 km por segundo) parece muito, mas eh
-- so 1.4% da velocidade da luz. nessa velocidade a relatividade quase nao
-- aparece: newton e einstein dao praticamente o mesmo numero.

print("\n-- 4) foguete a 4197261 m/s --")
local v_foguete = 4197261
local b_foguete = v_foguete / C
local gamma_foguete = 1 / math.sqrt(1 - b_foguete^2)
-- %% dentro do string.format escreve o simbolo % de verdade
print(string.format("v = %d m/s  beta = %.3f%%  gamma = %.8f", v_foguete, 100 * b_foguete, gamma_foguete))
print(string.format("relogio do foguete: %.4f s a cada 30 s aqui", 30 / gamma_foguete))
local eps_real = energia_anel(solenoide) / (solenoide.massa * C^2)
print(string.format("aneis do solenoide real pra chegar nisso: %.1e", aneis_para(b_foguete, eps_real)))


-- ===================================================================
-- 5) e se cada anel desse MUITO mais? 5% de m*c^2 por anel
-- ===================================================================
-- isso eh exagerado de proposito, pra chegar em beta 0.8 e ver a
-- relatividade aparecer de verdade (relogio andando a 60%).

print("\n-- 5) aneis exagerados (5% de mc2 por anel) --")
local eps_exagerado = 0.05
for k = 1, 20 do
  local x = k * eps_exagerado
  -- "relogio": quantos segundos passam pro foguete enquanto passam 30 s aqui
  print(string.format("anel %2d  gamma %.3f  beta %.4f  newton %.4f  relogio %.2f s/30s",
    k, 1 + x, beta(x), beta_newton(x), 30 / (1 + x)))
end
-- math.ceil arredonda pra cima (nao existe meio anel)
print(string.format("beta 0.8 no anel %d", math.ceil(aneis_para(0.8, eps_exagerado))))


-- ===================================================================
-- 6) solenoide de verdade (com os numeros la de cima)
-- ===================================================================

local E = energia_anel(solenoide)
local mc2 = solenoide.massa * C^2   -- energia de repouso do foguete (E = mc^2)
local eps = E / mc2

print("\n-- 6) solenoide real --")
print(string.format("B = %.3f T  E/anel = %.1f J  dv/anel = %.2f m/s",
  campo(solenoide), E, math.sqrt(2 * E / solenoide.massa)))
-- %.2e = notacao cientifica (ex: 1.23e+15 = 1,23 x 10^15)
print(string.format("aneis pra beta 0.8: %.2e", aneis_para(0.8, eps)))


-- ===================================================================
-- 7) estilingue com a formula pronta: U = 10000 m/s, vi = 150 m/s
-- ===================================================================
-- a nave chega quase parada e sai com quase o dobro da velocidade do planeta.
-- quanto mais ela contorna o planeta (theta menor), mais velocidade ganha.

print("\n-- 7) estilingue (U = 10000 m/s, vi = 150 m/s) --")
for _, theta in ipairs({0, 45, 90, 135, 180}) do
  print(string.format("theta %3d graus  vf = %.0f m/s", theta, estilingue(150, 10000, theta)))
end


-- ===================================================================
-- 8) estilingue em jupiter de verdade, 20 sobrevoos seguidos de frente
-- ===================================================================

print("\n-- 8) estilingue (jupiter) --")
local v = 10000   -- comeca a 10 km/s
for k = 1, 20 do
  -- passa a 1.1 raio de jupiter do centro (10% acima da "superficie")
  local novo, d = sobrevoo(v, jupiter, 1.1 * jupiter.R, 0)
  print(string.format("sobrevoo %2d  %.2f -> %.2f km/s  deflexao %.1f graus",
    k, v / 1000, novo / 1000, math.deg(d)))
  v = novo
end
print(string.format("beta final %.2e (nao chega nem perto de 0.8)", v / C))
