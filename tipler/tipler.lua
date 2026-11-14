-- tipler.lua
-- cilindro girando (poeira de van stockum): cone de luz tombando e viagem pro passado
-- uso: lua tipler/tipler.lua
--
-- unidades: c = G = 1, comprimento em L = 1/a (a = rotacao)
-- tomando L = 1 hora-luz, os tempos saem em horas

local a = 1.0

-- metrica: ds2 = -(dt + a r^2 dphi)^2 + r^2 dphi^2 + exp(-a^2 r^2) (dr^2 + dz^2)
local function ds2(r, dt, dr, dphi)
  local g = dt + a * r * r * dphi
  return -g * g + r * r * dphi * dphi + math.exp(-a * a * r * r) * dr * dr
end

-- g_phiphi = r^2 (1 - a^2 r^2): negativo depois de r = 1/a
local function g_phiphi(r) return r * r * (1 - a * a * r * r) end

-- arrasto: omega = -g_tphi / g_phiphi
local function arrasto(r) return a / (1 - a * a * r * r) end

-- volta mais rapida possivel (luz indo a favor): dt = 2 pi r (1 - a r)
local function dt_volta_luz(r) return 2 * math.pi * r * (1 - a * r) end

-- volta a velocidade v (em relacao a poeira): dt/dphi = r (1/v - a r)
local function volta(r, v, n)
  local t, tau, dphi = 0, 0, 2 * math.pi / n
  local dt = r * (1 / v - a * r) * dphi
  local ok = true
  for _ = 1, n do
    local s = ds2(r, dt, 0, dphi)
    if s >= 0 then ok = false end
    t = t + dt
    tau = tau + math.sqrt(-s)
  end
  return t, tau, ok
end

-- ida radial de r0 ate r1 a velocidade v: dt = exp(-a^2 r^2 / 2) dr / v
local function radial(r0, r1, v, n)
  local t, tau, dr = 0, 0, (r1 - r0) / n
  for i = 1, n do
    local r = r0 + (i - 0.5) * dr
    local dt = math.exp(-a * a * r * r / 2) * math.abs(dr) / v
    local s = ds2(r, dt, dr, 0)
    t = t + dt
    tau = tau + math.sqrt(-s)
  end
  return t, tau
end

print("1. cone de luz ao redor do cilindro")
print("   a r   g_phiphi/r^2   arrasto/a   borda do cone   volta da luz (h)")
for _, ar in ipairs({ 0, 0.25, 0.5, 0.75, 0.9, 1.0, 1.25, 1.5, 2.0 }) do
  local r = ar / a
  local gpp = ar > 0 and g_phiphi(r) / (r * r) or 1
  local arr = ar == 1 and "   infinito" or string.format("%11.3f", arrasto(r) / a)
  local inc = math.deg(math.atan(1 - ar))
  print(string.format("  %4.2f  %13.3f  %s  %10.1f graus  %14.3f",
    ar, gpp, arr, inc, dt_volta_luz(r)))
end
print("   borda abaixo de 0 graus: da pra dar a volta voltando no tempo")

print()
print("2. curva fechada do tipo tempo (r = 2/a, dt = 0)")
local r = 2 / a
local tau_ctc = 2 * math.pi * r * math.sqrt(a * a * r * r - 1)
print(string.format("   ds2 por passo: %.4f (negativo = tipo tempo)", ds2(r, 0, 0, 0.01)))
print(string.format("   volta completa: t muda 0 h, o viajante envelhece %.2f h", tau_ctc))

print()
print("3. velocidade minima pra voltar no tempo: a r > 1/v")
for _, v in ipairs({ 0.1, 0.5, 0.8, 0.99 }) do
  print(string.format("   v = %.2f c  ->  r > %.3f L", v, 1 / (v * a)))
end

print()
print("4. maquina do tempo (L = 1 hora-luz)")
local v_r, v_o, ro = 0.5, 0.8, 2 / a
local t1, tau1 = radial(0, ro, v_r, 10000)
local tl, taul, ok = volta(ro, v_o, 10000)
local voltas = math.ceil((2 * t1 + 24) / -tl)
local t_total = 2 * t1 + voltas * tl
local tau_total = 2 * tau1 + voltas * taul
print(string.format("   sai do eixo a %.1f c ate r = %.0f L: %.3f h (envelhece %.3f h)", v_r, ro, t1, tau1))
print(string.format("   cada volta a %.1f c: t muda %.3f h, envelhece %.3f h, tipo tempo: %s",
  v_o, tl, taul, tostring(ok)))
print(string.format("   %d voltas e volta pro eixo", voltas))
print(string.format("   chega %.2f h ANTES de sair, tendo envelhecido %.2f h", -t_total, tau_total))
