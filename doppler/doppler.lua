-- doppler.lua
-- muda a cor da luz quando voce anda muito rapido ou cai num buraco negro
-- como rodar (no terminal, dentro da pasta lua-physics):
--   lua doppler/doppler.lua
--
-- dica de lua pra quem ta comecando:
--   "--" comeca um comentario. o lua ignora tudo depois dele na linha.
--   "local x = 5" cria uma variavel chamada x valendo 5.
--   "function nome(a) ... end" cria uma funcao (uma conta que da pra reusar).


-- ===================================================================
-- a luz de partida
-- ===================================================================

-- H-alfa: a luz vermelha que o hidrogenio solta. aparece em todo canto do
-- universo, entao os astronomos usam ela como "regua" de cor.
-- o numero eh o comprimento de onda em nanometros (nm).
-- 1 nm = 1 bilionesimo de metro.
local H_ALFA = 656.28


-- ===================================================================
-- as duas formulas
-- ===================================================================

-- beta = sua velocidade dividida pela velocidade da luz.
--   beta 0.5 = metade da velocidade da luz.
--   beta positivo = indo NA DIRECAO da luz (encontrando ela de frente)
--   beta negativo = FUGINDO da luz
--
-- a funcao devolve um "fator": quanto o comprimento de onda fica multiplicado.
--   fator menor que 1 -> onda mais curta -> cor puxa pro azul (blueshift)
--   fator maior que 1 -> onda mais longa -> cor puxa pro vermelho (redshift)
--
-- formula: fator = raiz( (1 - beta) / (1 + beta) )
-- ela junta duas coisas: o doppler normal (o mesmo da sirene da ambulancia)
-- e a dilatacao do tempo (o relogio de quem anda rapido anda mais devagar).
local function doppler(beta)
  return math.sqrt((1 - beta) / (1 + beta))
end

-- redshift gravitacional: a luz que sai de perto de um buraco negro gasta
-- energia "subindo" pra fora da gravidade, e chega aqui mais vermelha.
--
-- r = distancia ate o centro do buraco negro, medida em "raios de schwarzschild".
--   o raio de schwarzschild eh o tamanho do horizonte (de onde nada volta).
--   r = 1 eh o horizonte, r = 2 eh o dobro dessa distancia, e assim por diante.
--
-- formula: fator = 1 / raiz(1 - 1/r)
-- quanto mais perto do horizonte (r chegando em 1), maior o fator.
local function gravitacional(r)
  return 1 / math.sqrt(1 - 1 / r)
end


-- ===================================================================
-- funcoes pra mostrar o resultado bonitinho
-- ===================================================================

-- recebe um comprimento de onda (nm) e diz o nome da cor.
-- o olho humano so enxerga de ~380 nm (violeta) ate ~750 nm (vermelho).
local function cor(nm)
  if nm < 380 then return "ultravioleta (invisivel)"
  elseif nm < 450 then return "violeta"
  elseif nm < 495 then return "azul"
  elseif nm < 570 then return "verde"
  elseif nm < 590 then return "amarelo"
  elseif nm < 620 then return "laranja"
  elseif nm <= 750 then return "vermelho"
  else return "infravermelho (invisivel)"
  end
end

-- imprime uma linha tipo:   indo na direcao, beta 0.3    482.1 nm  azul
-- string.format monta o texto:
--   %-34s = texto alinhado a esquerda ocupando 34 espacos
--   %8.1f = numero com 1 casa depois da virgula
--   %s    = texto
local function mostra(descricao, nm)
  print(string.format("  %-34s %8.1f nm  %s", descricao, nm, cor(nm)))
end


-- ===================================================================
-- 1) nave indo na direcao de uma luz vermelha, e fugindo dela
-- ===================================================================
-- "for _, b in ipairs({...})" = repete o bloco uma vez pra cada numero da
-- lista, e cada vez o numero fica guardado em b.

print("-- 1) nave e luz vermelha (H-alfa) --")
for _, b in ipairs({0.1, 0.3, 0.5, 0.8}) do
  mostra(string.format("indo na direcao, beta %.1f", b), H_ALFA * doppler(b))
  mostra(string.format("fugindo, beta %.1f", b), H_ALFA * doppler(-b))
end


-- ===================================================================
-- 2) caindo num buraco negro, olhando pras estrelas que ficaram pra tras
-- ===================================================================
-- imagina que voce estava parado bem longe e se soltou.
-- quando chega na distancia r, sua velocidade eh beta = raiz(1/r).
--
-- dois efeitos brigando:
--   - a luz das estrelas CAI junto no buraco e ganha energia -> fica mais azul
--   - mas voce ta fugindo dela (ela vem por tras)          -> fica mais vermelha
-- o doppler ganha. juntando os dois a conta vira so: fator = 1 + beta

print("\n-- 2) caindo no buraco negro, olhando as estrelas de tras --")
for _, r in ipairs({100, 10, 4, 2, 1.2, 1.01}) do
  local b = math.sqrt(1 / r)
  -- aqui a gravidade AZULA (a luz ta caindo, nao subindo), entao divide
  local fator = doppler(-b) / gravitacional(r)
  mostra(string.format("r = %.2f rs, beta %.3f", r, b), H_ALFA * fator)
end
print("  (chegando no horizonte beta vai pra 1, e a luz fica com o dobro do comprimento)")


-- ===================================================================
-- 3) disco de acrecao: o gas girando em volta do buraco negro
-- ===================================================================
-- em r = 3 fica a ultima orbita estavel. ali o gas gira a metade da
-- velocidade da luz (beta 0.5). olhando o disco de lado, de bem longe:
--   - um lado do disco vem na nossa direcao -> blueshift
--   - o outro lado vai embora               -> redshift
--   - e toda a luz ainda perde energia saindo da gravidade
-- (eh por isso que nas fotos de buraco negro um lado do disco brilha mais)

print("\n-- 3) disco de acrecao em r = 3 rs, visto de longe --")
local r_disco = 3
local beta_disco = 0.5
local fator_grav = gravitacional(r_disco)
mostra("so a gravidade", H_ALFA * fator_grav)
mostra("lado que vem na nossa direcao", H_ALFA * fator_grav * doppler(beta_disco))
mostra("lado que vai embora", H_ALFA * fator_grav * doppler(-beta_disco))


-- ===================================================================
-- 4) jato relativistico
-- ===================================================================
-- alguns buracos negros cospem materia pelos polos quase na velocidade da luz.
-- sai um jato pra cada lado: um vem pra gente, o outro vai embora.

print("\n-- 4) jato relativistico --")
for _, b in ipairs({0.5, 0.9, 0.99}) do
  mostra(string.format("jato vindo pra ca, beta %.2f", b), H_ALFA * doppler(b))
  mostra(string.format("contra-jato indo embora, beta %.2f", b), H_ALFA * doppler(-b))
end


-- e a frequencia? eh so o contrario do comprimento de onda: f = c / lambda.
-- se o comprimento de onda dobra, a frequencia cai pela metade.
