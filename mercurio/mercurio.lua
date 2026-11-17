-- mercurio.lua
-- precessao do perielio: newton fecha a elipse, a relatividade geral faz ela girar
-- uso: lua mercurio/mercurio.lua

local C = 299792458.0        -- velocidade da luz (m/s)
local GM = 1.32712440018e20  -- sol (m^3/s^2)
local SEG_ARCO = 180 / math.pi * 3600

local planetas = {
  { nome = "mercurio", a = 5.7909e10, e = 0.205630, T = 87.9691 },   -- a em m, T em dias
  { nome = "venus", a = 1.08209e11, e = 0.006772, T = 224.701 },
  { nome = "terra", a = 1.49598e11, e = 0.016709, T = 365.256 },
  { nome = "marte", a = 2.27939e11, e = 0.093400, T = 686.980 },
}

-- binet (u = 1/r, derivada em phi): u'' + u = GM/h^2 + k * 3 GM u^2 / c^2
-- k = 0: newton, k = 1: relatividade geral
local function deriv(u, du, h2, k)
  return du, GM / h2 + k * 3 * GM * u * u / (C * C) - u
end

-- integra uma volta a partir do perielio e devolve o angulo do proximo perielio
local function proximo_perielio(p, k, n)
  local h2 = GM * p.a * (1 - p.e * p.e)
  local u, du = 1 / (p.a * (1 - p.e)), 0
  local phi, dphi = 0, 2 * math.pi / n
  while true do
    local a1, b1 = deriv(u, du, h2, k)
    local a2, b2 = deriv(u + dphi / 2 * a1, du + dphi / 2 * b1, h2, k)
    local a3, b3 = deriv(u + dphi / 2 * a2, du + dphi / 2 * b2, h2, k)
    local a4, b4 = deriv(u + dphi * a3, du + dphi * b3, h2, k)
    local du_novo = du + dphi / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
    u = u + dphi / 6 * (a1 + 2 * a2 + 2 * a3 + a4)
    phi = phi + dphi
    -- perielio: u maximo, u' passa de + pra -
    if phi > math.pi and du > 0 and du_novo <= 0 then
      local _, ddu = deriv(u, du_novo, h2, k)
      return phi - du_novo / ddu
    end
    du = du_novo
  end
end

-- formula: 6 pi GM / (c^2 a (1 - e^2)) por volta
local function formula(p)
  return 6 * math.pi * GM / (C * C * p.a * (1 - p.e * p.e))
end

local merc = planetas[1]

print("1. mercurio, uma volta (100000 passos)")
local pn = proximo_perielio(merc, 0, 100000) - 2 * math.pi
local pr = proximo_perielio(merc, 1, 100000) - 2 * math.pi
print(string.format("   newton:       o perielio anda %.3e rad (zero, a elipse fecha)", pn))
print(string.format("   relatividade: anda %.6e rad = %.4f segundos de arco", pr, pr * SEG_ARCO))
print(string.format("   formula:      %.6e rad", formula(merc)))

print()
print("2. por seculo (36525 dias)")
print("   planeta     codigo     formula")
for _, p in ipairs(planetas) do
  local d = proximo_perielio(p, 1, 100000) - 2 * math.pi
  local voltas = 36525 / p.T
  print(string.format("   %-9s %7.2f\"   %7.2f\"", p.nome, d * voltas * SEG_ARCO, formula(p) * voltas * SEG_ARCO))
end

print()
print("3. a conta que nao fechava (mercurio, segundos de arco por seculo)")
print("   observado (contra as estrelas):         ~575")
print("   puxao dos outros planetas (newton):     ~532")
print("   sobra sem explicacao ate 1915:           ~43")
print(string.format("   relatividade geral:                    %6.2f", pr * 36525 / merc.T * SEG_ARCO))
