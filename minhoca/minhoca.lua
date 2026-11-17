-- minhoca.lua
-- buraco de minhoca atravessavel (ellis / morris-thorne) e a energia negativa que ele pede
-- uso: lua minhoca/minhoca.lua
--
-- metrica: ds^2 = -c^2 dt^2 + dl^2 + (l^2 + b0^2) dOmega^2
-- l = distancia andando pelo tunel (negativo de um lado, positivo do outro), b0 = raio da garganta

local C = 299792458.0
local G = 6.674e-11
local HBAR = 1.054571817e-34
local g = 9.81                 -- aceleracao que a pessoa aguenta (1 g)
local XI = 2                   -- tamanho da pessoa (m)
local M_JUP, M_SOL = 1.898e27, 1.989e30

local function raio(l, b0) return math.sqrt(l * l + b0 * b0) end

-- formato no diagrama de imersao: z = b0 asinh(l / b0) (uma catenoide)
local function altura(l, b0)
  local x = l / b0
  return b0 * math.log(x + math.sqrt(x * x + 1))
end

-- densidade de energia (J/m^3): rho c^2 = -c^4 b0^2 / (8 pi G r^4)
local function densidade(l, b0)
  local r = raio(l, b0)
  return -C ^ 4 * b0 * b0 / (8 * math.pi * G * r ^ 4)
end

-- massa total: soma de rho 4 pi r^2 dl de um lado ao outro, dividida por c^2
local function massa_total(b0)
  local n, lmax = 200000, 2000 * b0
  local dl, soma = 2 * lmax / n, 0
  for i = 0, n - 1 do
    local l = -lmax + (i + 0.5) * dl
    local r = raio(l, b0)
    soma = soma + densidade(l, b0) * 4 * math.pi * r * r * dl
  end
  return soma / (C * C)
end

print("1. formato (diagrama de imersao, tudo em unidades de b0)")
print("    l/b0    r/b0    z/b0")
for _, x in ipairs({ -4, -2, -1, 0, 1, 2, 4 }) do
  print(string.format("   %5.1f  %6.3f  %6.3f", x, raio(x, 1), altura(x, 1)))
end
print("   na garganta (l = 0) o raio eh minimo e nao vai a zero: da pra passar")

print()
print("2. densidade de energia (b0 = 1 m)")
local agua = 1000 * C * C
for _, x in ipairs({ 0, 1, 3, 10 }) do
  local d = densidade(x, 1)
  print(string.format("   l = %4.1f m  ->  %10.3e J/m^3  (%.1e vezes a agua, negativo)", x, d, -d / agua))
end

print()
print("3. quanta massa negativa no total")
for _, b0 in ipairs({ 1, 1000, 1.496e11 }) do
  local m = massa_total(b0)
  local conta = -math.pi / 2 * b0 * C * C / G
  print(string.format("   b0 = %8.3g m  ->  %10.3e kg (conta: %10.3e)  = %.3g jupiters = %.3g sois",
    b0, m, conta, -m / M_JUP, -m / M_SOL))
end

print()
print("4. passar sem ser esticado (mare lateral na garganta: gamma^2 v^2 xi / b0^2 <= g)")
for _, b0 in ipairs({ 1, 100, 1e4, 1e8 }) do
  local w = b0 * math.sqrt(g / XI)         -- gamma v
  local v = w / math.sqrt(1 + (w / C) ^ 2)
  local tau = 20 * b0 / w                  -- de l = -10 b0 ate 10 b0, no relogio de quem passa
  print(string.format("   b0 = %6.0e m  ->  v max = %10.4g m/s (%.4f c), atravessa em %.2f s", b0, v, v / C, tau))
end

print()
print("5. efeito casimir (energia negativa medida de verdade): -pi^2 hbar c / (720 d^4)")
for _, b0 in ipairs({ 1, 1000 }) do
  -- distancia entre placas que daria a densidade da garganta
  local d = (math.pi ^ 2 * HBAR * C / (720 * -densidade(0, b0))) ^ 0.25
  print(string.format("   b0 = %5g m  ->  placas a %.2e m (um proton tem ~1e-15 m)", b0, d))
end
