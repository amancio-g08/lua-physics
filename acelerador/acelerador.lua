-- acelerador.lua
-- barra magnetizada, solenoide, aneis magneticos e estilingue gravitacional
-- uso: lua acelerador/acelerador.lua

local C = 299792458.0       -- velocidade da luz (m/s)
local MU0 = 4e-7 * math.pi  -- permeabilidade do vacuo

local solenoide = {
  n = 1000,       -- espiras por metro
  I = 1000,       -- corrente (A)
  mur = 1,        -- mu relativo (1 = ar, ferro ~1000)
  raio = 0.1,     -- m
  comp = 0.5,     -- m
  eta = 0.30,     -- eficiencia
  massa = 1000,   -- kg do foguete
}

local jupiter = { U = 13.07e3, GM = 1.267e17, R = 6.991e7 }  -- U = vel orbital

-- B = n * mu * I
local function campo(s)
  local B = MU0 * s.mur * s.n * s.I
  if s.mur > 1 and B > 2 then B = 2 end  -- ferro satura perto de 2 T
  return B
end

-- fluxo = B * A * cos(theta)
local function fluxo(B, raio, theta)
  return B * math.pi * raio^2 * math.cos(math.rad(theta))
end

-- energia por anel = eta * B^2 / (2 * mu0) * volume
local function energia_anel(s)
  local B = campo(s)
  local vol = math.pi * s.raio^2 * s.comp
  return s.eta * B^2 / (2 * MU0) * vol
end

-- x = energia cinetica / mc^2 = gamma - 1
-- beta = sqrt(1 - 1/gamma^2), escrito assim pra nao perder precisao com x pequeno
local function beta(x)
  return math.sqrt(x * (x + 2)) / (1 + x)
end

-- newton: (1/2)mv^2 = E -> beta = sqrt(2x). passa de 1
local function beta_newton(x)
  return math.sqrt(2 * x)
end

-- quantos aneis pra chegar em beta b, com eps = E_anel / mc^2
local function aneis_para(b, eps)
  local gamma = 1 / math.sqrt(1 - b^2)
  return (gamma - 1) / eps
end

-- sobrevoo: no referencial do planeta a nave so muda de direcao (angulo d),
-- no referencial do sol isso vira ganho de velocidade
local function sobrevoo(v, P, rp, theta)
  local ux = -v * math.cos(theta) - P.U
  local uy = v * math.sin(theta)
  local u = math.sqrt(ux^2 + uy^2)
  local e = 1 + rp * u^2 / P.GM   -- excentricidade da hiperbole
  local d = 2 * math.asin(1 / e)  -- deflexao maxima
  local melhor = 0
  for _, s in ipairs({1, -1}) do
    local c, sn = math.cos(s * d), math.sin(s * d)
    local wx = ux * c - uy * sn + P.U
    local wy = ux * sn + uy * c
    melhor = math.max(melhor, math.sqrt(wx^2 + wy^2))
  end
  return melhor, d
end

-- vf = (vi + 2U) * sqrt(1 - 4 vi U (1 - cos theta) / (vi + 2U)^2)
-- theta = 0: volta completa, vf = vi + 2U
local function estilingue(vi, U, theta)
  local t = math.rad(theta)
  return (vi + 2 * U) * math.sqrt(1 - 4 * vi * U * (1 - math.cos(t)) / (vi + 2 * U)^2)
end


-- 1) barra: 1000 dominios com direcao sorteada.
-- cada passada do ima gira cada dominio metade do caminho ate alinhar.
-- alinhamento = media de cos(angulo), B = 2 T * alinhamento
print("-- 1) magnetizando a barra --")
math.randomseed(42)
local dominios = {}
for i = 1, 1000 do
  dominios[i] = (math.random() * 2 - 1) * math.pi
end
for passada = 0, 5 do
  local soma = 0
  for i = 1, #dominios do
    soma = soma + math.cos(dominios[i])
  end
  local alinhamento = soma / #dominios
  print(string.format("passada %d  alinhamento %.3f  B da barra = %.2f T",
    passada, alinhamento, 2 * alinhamento))
  for i = 1, #dominios do
    dominios[i] = dominios[i] / 2
  end
end

-- 2) solenoide com 2 espiras, no ar e com a barra de ferro de nucleo
print("\n-- 2) solenoide (n = 2, I = 1000 A) --")
local so_ar = { n = 2, I = 1000, mur = 1 }
local com_ferro = { n = 2, I = 1000, mur = 1000 }
print(string.format("so ar:            B = %.4f T", campo(so_ar)))
print(string.format("com nucleo ferro: B = %.4f T (satura em 2 T)", campo(com_ferro)))

-- 3) fluxo no anel. quando o foguete-ima passa, o fluxo muda e induz corrente (faraday)
print("\n-- 3) fluxo no anel (raio 0.1 m) --")
local B_anel = campo(solenoide)
for _, theta in ipairs({0, 30, 45, 60, 90}) do
  print(string.format("theta %2d graus  fluxo = %.4f Wb", theta, fluxo(B_anel, solenoide.raio, theta)))
end

-- 4) foguete a 4197261 m/s: so 1.4% de c, relatividade quase nao aparece
print("\n-- 4) foguete a 4197261 m/s --")
local v_foguete = 4197261
local b_foguete = v_foguete / C
local gamma_foguete = 1 / math.sqrt(1 - b_foguete^2)
print(string.format("v = %d m/s  beta = %.3f%%  gamma = %.8f", v_foguete, 100 * b_foguete, gamma_foguete))
print(string.format("relogio do foguete: %.4f s a cada 30 s aqui", 30 / gamma_foguete))
local eps_real = energia_anel(solenoide) / (solenoide.massa * C^2)
print(string.format("aneis do solenoide real pra chegar nisso: %.1e", aneis_para(b_foguete, eps_real)))

-- 5) cada anel da 5% de mc^2 (exagerado de proposito, pra chegar em 0.8)
print("\n-- 5) aneis exagerados (5% de mc2 por anel) --")
local eps_exagerado = 0.05
for k = 1, 20 do
  local x = k * eps_exagerado
  print(string.format("anel %2d  gamma %.3f  beta %.4f  newton %.4f  relogio %.2f s/30s",
    k, 1 + x, beta(x), beta_newton(x), 30 / (1 + x)))
end
print(string.format("beta 0.8 no anel %d", math.ceil(aneis_para(0.8, eps_exagerado))))

-- 6) solenoide de verdade
local E = energia_anel(solenoide)
local mc2 = solenoide.massa * C^2
local eps = E / mc2
print("\n-- 6) solenoide real --")
print(string.format("B = %.3f T  E/anel = %.1f J  dv/anel = %.2f m/s",
  campo(solenoide), E, math.sqrt(2 * E / solenoide.massa)))
print(string.format("aneis pra beta 0.8: %.2e", aneis_para(0.8, eps)))

-- 7) estilingue com a formula pronta
print("\n-- 7) estilingue (U = 10000 m/s, vi = 150 m/s) --")
for _, theta in ipairs({0, 45, 90, 135, 180}) do
  print(string.format("theta %3d graus  vf = %.0f m/s", theta, estilingue(150, 10000, theta)))
end

-- 8) jupiter, 20 sobrevoos de frente a 1.1 raio do centro
print("\n-- 8) estilingue (jupiter) --")
local v = 10000
for k = 1, 20 do
  local novo, d = sobrevoo(v, jupiter, 1.1 * jupiter.R, 0)
  print(string.format("sobrevoo %2d  %.2f -> %.2f km/s  deflexao %.1f graus",
    k, v / 1000, novo / 1000, math.deg(d)))
  v = novo
end
print(string.format("beta final %.2e (nao chega nem perto de 0.8)", v / C))
