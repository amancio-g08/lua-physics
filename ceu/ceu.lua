-- ceu.lua
-- o ceu visto de uma nave quase na velocidade da luz: aberracao, doppler e brilho
-- uso: lua ceu/ceu.lua
--
-- theta = angulo com a direcao do movimento (0 = frente, 180 = tras)
-- theta0 = angulo no referencial das estrelas, theta = o que a nave ve

local WIEN = 2.898e-3   -- constante de wien (m K)

local function gamma(b) return 1 / math.sqrt(1 - b * b) end

-- aberracao: cos theta = (cos theta0 + b) / (1 + b cos theta0)
local function aberracao(theta0, b)
  local c0 = math.cos(theta0)
  return math.acos((c0 + b) / (1 + b * c0))
end

-- doppler: D = 1 / (gamma (1 - b cos theta))
local function doppler(theta, b)
  return 1 / (gamma(b) * (1 - b * math.cos(theta)))
end

local function graus(x) return math.deg(x) end

print("1. aberracao: onde aparece uma estrela que estava de lado (90 graus)")
for _, b in ipairs({ 0, 0.1, 0.5, 0.9, 0.99, 0.999 }) do
  print(string.format("   v = %5.3f c  ->  %5.1f graus", b, graus(aberracao(math.pi / 2, b))))
end

print()
print("2. quanto do ceu cai na metade da frente: (1 + v) / 2")
for _, b in ipairs({ 0, 0.5, 0.9, 0.99 }) do
  local limite = graus(math.acos(-b))
  print(string.format("   v = %4.2f c  ->  %5.1f%% das estrelas (ate %5.1f graus pra tras)",
    b, 100 * (1 + b) / 2, limite))
end

print()
print("3. sorteio de 100000 estrelas: quantas num cone de 30 graus na frente")
math.randomseed(1)
local n = 100000
local frente = {}
for _, b in ipairs({ 0, 0.5, 0.9, 0.99 }) do frente[b] = 0 end
for _ = 1, n do
  local theta0 = math.acos(2 * math.random() - 1)   -- uniforme na esfera
  for b in pairs(frente) do
    if aberracao(theta0, b) < math.rad(30) then frente[b] = frente[b] + 1 end
  end
end
for _, b in ipairs({ 0, 0.5, 0.9, 0.99 }) do
  -- conta: cos theta0 > (cos 30 - v) / (1 - v cos 30)
  local c = (math.cos(math.rad(30)) - b) / (1 - b * math.cos(math.rad(30)))
  print(string.format("   v = %4.2f c  ->  %5.1f%%  (conta: %5.1f%%)", b, 100 * frente[b] / n, 100 * (1 - c) / 2))
end

print()
print("4. uma estrela como o sol (5800 K) a 0.9c")
local b, T = 0.9, 5800
for _, lado in ipairs({ { "frente", 0 }, { "lado", math.pi / 2 }, { "tras", math.pi } }) do
  local D = doppler(lado[2], b)
  print(string.format("   %-6s  D = %5.3f  T = %6.0f K  pico em %6.0f nm  brilho x %8.3f",
    lado[1], D, T * D, WIEN / (T * D) * 1e9, D ^ 4))
end

print()
print("5. fundo de micro-ondas (2.725 K): quando a frente brilha que nem brasa (1000 K)")
local D = 1000 / 2.725
-- D = sqrt((1 + b) / (1 - b)) na frente -> b = (D^2 - 1) / (D^2 + 1)
local bm = (D * D - 1) / (D * D + 1)
print(string.format("   D = %.0f  ->  v = 1 - %.2e c  (gamma = %.0f)", D, 1 - bm, gamma(bm)))
