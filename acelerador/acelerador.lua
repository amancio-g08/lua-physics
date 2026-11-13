-- acelerador.lua
-- foguete passando por aneis magneticos (solenoides) vs estilingue gravitacional
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


-- ===================================================================
-- 1) modo video: cada anel da 5% de m*c^2 (exagerado de proposito)
-- ===================================================================
-- "for k = 1, 20 do" repete o bloco 20 vezes, com k = 1, 2, 3 ... 20
-- string.format monta o texto: %d = inteiro, %.3f = numero com 3 casas

print("-- 1) aneis (5% de mc2 por anel) --")
local eps_video = 0.05
for k = 1, 20 do
  local x = k * eps_video
  -- "relogio": quantos segundos passam pro foguete enquanto passam 30 s aqui
  print(string.format("anel %2d  gamma %.3f  beta %.4f  newton %.4f  relogio %.2f s/30s",
    k, 1 + x, beta(x), beta_newton(x), 30 / (1 + x)))
end
-- math.ceil arredonda pra cima (nao existe meio anel)
print(string.format("beta 0.8 no anel %d", math.ceil(aneis_para(0.8, eps_video))))


-- ===================================================================
-- 2) solenoide de verdade (com os numeros la de cima)
-- ===================================================================

local E = energia_anel(solenoide)
local mc2 = solenoide.massa * C^2   -- energia de repouso do foguete (E = mc^2)
local eps = E / mc2

print("\n-- 2) solenoide real --")   -- "\n" pula uma linha
print(string.format("B = %.3f T  E/anel = %.1f J  dv/anel = %.2f m/s",
  campo(solenoide), E, math.sqrt(2 * E / solenoide.massa)))
-- %.2e = notacao cientifica (ex: 1.23e+15 = 1,23 x 10^15)
print(string.format("aneis pra beta 0.8: %.2e", aneis_para(0.8, eps)))


-- ===================================================================
-- 3) estilingue em jupiter, 20 sobrevoos seguidos de frente
-- ===================================================================

print("\n-- 3) estilingue (jupiter) --")
local v = 10000   -- comeca a 10 km/s
for k = 1, 20 do
  -- passa a 1.1 raio de jupiter do centro (10% acima da "superficie")
  local novo, d = sobrevoo(v, jupiter, 1.1 * jupiter.R, 0)
  print(string.format("sobrevoo %2d  %.2f -> %.2f km/s  deflexao %.1f graus",
    k, v / 1000, novo / 1000, math.deg(d)))
  v = novo
end
print(string.format("beta final %.2e (nao chega nem perto de 0.8)", v / C))
