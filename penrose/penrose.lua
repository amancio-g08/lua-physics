-- penrose.lua
-- processo de penrose: tirar energia de um buraco negro girando (kerr)
-- uso: lua penrose/penrose.lua
--
-- unidades: G = c = M = 1, tudo no plano do equador
-- E e L por unidade de massa da nave (que chega do infinito parada, E = 1)

-- metrica de kerr no equador
local function metrica(r, a)
  local gtt = -(1 - 2 / r)
  local gtp = -2 * a / r
  local gpp = r * r + a * a + 2 * a * a / r
  local delta = r * r - 2 * r + a * a
  return gtt, gtp, gpp, delta
end

local function horizonte(a) return 1 + math.sqrt(1 - a * a) end

-- (dr/dtau)^2 = V / r^2, V = gpp E^2 + 2 gtp E L + gtt L^2 - delta
local function V(r, a, E, L)
  local gtt, gtp, gpp, delta = metrica(r, a)
  return gpp * E * E + 2 * gtp * E * L + gtt * L * L - delta
end

-- da pra ir de r ate longe (rmax) sem bater num ponto de retorno?
local function caminho_livre(r, a, E, L, rmax)
  local n = 20000
  for i = 1, n do
    local rr = r + (rmax - r) * (i / n) ^ 2
    if V(rr, a, E, L) < 0 then return false end
  end
  return true
end

-- L de quem tem energia E e para em r (ponto de retorno, dr = 0)
-- das duas raizes, fica a que consegue ter vindo de longe
local function L_retorno(r, a, E)
  local gtt, gtp, gpp, delta = metrica(r, a)
  local c = gpp * E * E - delta
  local raizes
  if math.abs(gtt) < 1e-12 then
    raizes = { -c / (2 * gtp * E) }
  else
    local disc = gtp * gtp * E * E - gtt * c
    if disc < 0 then return nil end
    raizes = { (-gtp * E + math.sqrt(disc)) / gtt, (-gtp * E - math.sqrt(disc)) / gtt }
  end
  for _, L in ipairs(raizes) do
    if caminho_livre(r * 1.0001, a, E, L, 1000) then return L end
  end
  return nil
end

-- u^t e u^phi a partir de E e L
local function contra(r, a, E, L)
  local gtt, gtp, gpp, delta = metrica(r, a)
  return (gpp * E + gtp * L) / delta, -(gtp * E + gtt * L) / delta
end

-- a nave (E0 = 1) se parte em r: duas metades a -v e +v no referencial dela
local function quebra(r, a, v)
  local E0 = 1
  local L0 = L_retorno(r, a, E0)
  if not L0 then return nil end
  local gtt, gtp, gpp = metrica(r, a)
  local ut, up = contra(r, a, E0, L0)
  -- e1: vetor unitario ortogonal a u0, apontando a favor da rotacao
  local x = L0 / E0
  local n = math.sqrt(gtt * x * x + 2 * gtp * x + gpp)
  local et, ep = x / n, 1 / n
  if gtp * et + gpp * ep < 0 then et, ep = -et, -ep end   -- e1_phi > 0
  local g = 1 / math.sqrt(1 - v * v)
  local m = 1 / (2 * g)    -- massa de cada metade
  local function pedaco(s)
    local vt, vp = g * (ut + s * v * et), g * (up + s * v * ep)
    local E = -m * (gtt * vt + gtp * vp)
    local L = m * (gtp * vt + gpp * vp)
    return { E = E, L = L, m = m }
  end
  return { L0 = L0, tras = pedaco(-1), frente = pedaco(1) }
end

-- confere se a quebra funciona: nave chega do infinito, metade da frente escapa
local function valida(r, a, q)
  local f = q.frente
  return caminho_livre(r * 1.0001, a, 1, q.L0, 1000)
    and caminho_livre(r * 1.0001, a, f.E / f.m, f.L / f.m, 1000)
end

local a = 0.99
local rh = horizonte(a)
print(string.format("buraco negro com a = %.2f (rotacao, 1 = maxima)", a))
print(string.format("   horizonte em r = %.3f, ergosfera ate r = 2 (no equador)", rh))

print()
print("1. a nave cai do infinito e se parte em r = 1.5 (dentro da ergosfera), v = 0.9")
local r = 1.5
local q = quebra(r, a, 0.9)
print(string.format("   nave: E = 1, L = %.3f, chega ate r = %.1f: %s", q.L0, r,
  tostring(caminho_livre(r * 1.0001, a, 1, q.L0, 1000))))
print(string.format("   metade de tras:   E = %7.4f  L = %7.4f", q.tras.E, q.tras.L))
print(string.format("   metade da frente: E = %7.4f  L = %7.4f  escapa: %s", q.frente.E, q.frente.L,
  tostring(valida(r, a, q))))
print(string.format("   E da frente + E de tras = %.6f (conserva)", q.frente.E + q.tras.E))
print(string.format("   ganho: %.1f%% a mais de energia do que a nave tinha", 100 * (q.frente.E - 1)))

print()
print("2. o buraco paga a conta")
local OmH = a / (rh * rh + a * a)
print(string.format("   massa do buraco muda %.4f, momento angular muda %.4f", q.tras.E, q.tras.L))
print(string.format("   area do horizonte: dM - OmegaH dJ = %.4f (>= 0, a area nao diminui)",
  q.tras.E - OmH * q.tras.L))

print()
print("3. ganho conforme o lugar da quebra (a = 0.99, v = 0.9)")
for _, rr in ipairs({ 1.95, 1.8, 1.6, 1.4, 1.25, 1.2 }) do
  local qq = quebra(rr, a, 0.9)
  if qq and valida(rr, a, qq) then
    print(string.format("   r = %.2f  E de tras %7.4f  ganho %6.2f%%%s", rr, qq.tras.E,
      100 * (qq.frente.E - 1), qq.tras.E < 0 and "" or "  (tras ainda tem E > 0: perde)"))
  else
    print(string.format("   r = %.2f  nao da: a nave nao consegue parar nesse raio", rr))
  end
end

print()
print("4. limite: buraco maximo (a = 1), quebra no horizonte, metades na velocidade da luz")
for _, rr in ipairs({ 1.5, 1.1, 1.01, 1.001 }) do
  local qq = quebra(rr, 1, 1 - 1e-9)
  print(string.format("   r = %.3f  ganho %6.2f%%", rr, 100 * (qq.frente.E - 1)))
end
print(string.format("   teoria: (sqrt(2) - 1) / 2 = %.2f%%", 100 * (math.sqrt(2) - 1) / 2))

print()
print("5. quanto da massa eh rotacao (da pra tirar): 1 - massa irredutivel")
for _, aa in ipairs({ 0, 0.5, 0.9, 0.99, 1 }) do
  local mirr = math.sqrt(horizonte(aa) ^ 2 + aa * aa) / 2
  print(string.format("   a = %.2f  ->  %5.1f%%", aa, 100 * (1 - mirr)))
end
