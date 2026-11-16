-- main.lua
-- processo de penrose visto de cima (love2d)
-- uso: love penrose
--
-- G = c = M = 1, plano do equador, coordenadas de boyer-lindquist
-- a nave cai do infinito (E = 1), se parte na ergosfera e uma metade sai com mais energia

local W, H = 1100, 700
local CX, CY, ESC = 360, 360, 42   -- centro do buraco e px por M
local R0 = 8.3                     -- de onde a nave comeca (M)

local a, rq, v = 0.99, 1.4, 0.9    -- rotacao, raio da quebra, velocidade das metades
local ritmo = 1
local pausado = false
local corpos, q, erro
local fontes = {}

local function metrica(r)
  local gtt = -(1 - 2 / r)
  local gtp = -2 * a / r
  local gpp = r * r + a * a + 2 * a * a / r
  local delta = r * r - 2 * r + a * a
  return gtt, gtp, gpp, delta
end

local function horizonte() return 1 + math.sqrt(1 - a * a) end

-- (dr/dtau)^2 = V / r^2, com E e L por unidade de massa
local function Wr(r, E, L)
  local gtt, gtp, gpp, delta = metrica(r)
  return (gpp * E * E + 2 * gtp * E * L + gtt * L * L - delta) / (r * r)
end

local function livre(r, E, L)
  for i = 1, 4000 do
    if Wr(r + (1000 - r) * (i / 4000) ^ 2, E, L) < 0 then return false end
  end
  return true
end

local function L_retorno(r, E)
  local gtt, gtp, gpp, delta = metrica(r)
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
    if livre(r * 1.0001, E, L) then return L end
  end
end

-- nave (E0 = 1) se partindo em r: metades a -v e +v no referencial dela
local function quebra(r)
  local L0 = L_retorno(r, 1)
  if not L0 then return nil, "a nave nao chega nesse raio" end
  local gtt, gtp, gpp, delta = metrica(r)
  local ut, up = (gpp + gtp * L0) / delta, -(gtp + gtt * L0) / delta
  local x = L0
  local n = math.sqrt(gtt * x * x + 2 * gtp * x + gpp)
  local et, ep = x / n, 1 / n
  if gtp * et + gpp * ep < 0 then et, ep = -et, -ep end
  local g = 1 / math.sqrt(1 - v * v)
  local m = 1 / (2 * g)
  local function pedaco(s)
    local vt, vp = g * (ut + s * v * et), g * (up + s * v * ep)
    return { E = -(gtt * vt + gtp * vp), L = gtp * vt + gpp * vp, m = m }   -- por unidade de massa
  end
  local res = { L0 = L0, tras = pedaco(-1), frente = pedaco(1) }
  if not livre(r * 1.0001, res.frente.E, res.frente.L) then
    return res, "a metade da frente nao escapa"
  end
  return res
end

-- d(r, ur, phi)/dtau
local function deriv(c, r, ur)
  local h = 1e-5
  local acel = (Wr(r + h, c.E, c.L) - Wr(r - h, c.E, c.L)) / (4 * h)
  local gtt, gtp, _, delta = metrica(r)
  local uphi = -(gtp * c.E + gtt * c.L) / delta
  return ur, acel, uphi
end

local function passo(c, h)
  local r, ur, p = c.r, c.ur, c.phi
  local a1, b1, c1 = deriv(c, r, ur)
  local a2, b2, c2 = deriv(c, r + h / 2 * a1, ur + h / 2 * b1)
  local a3, b3, c3 = deriv(c, r + h / 2 * a2, ur + h / 2 * b2)
  local a4, b4, c4 = deriv(c, r + h * a3, ur + h * b3)
  c.r = r + h / 6 * (a1 + 2 * a2 + 2 * a3 + a4)
  c.ur = ur + h / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
  c.phi = p + h / 6 * (c1 + 2 * c2 + 2 * c3 + c4)
end

local function novo(nome, E, L, r, ur, phi, cor)
  return { nome = nome, E = E, L = L, r = r, ur = ur, phi = phi, cor = cor, rastro = {}, vivo = true }
end

local function reinicia()
  q, erro = quebra(rq)
  corpos = {}
  if q and not erro then
    local ur = -math.sqrt(math.max(Wr(R0, 1, q.L0), 0))
    corpos[1] = novo("nave", 1, q.L0, R0, ur, math.pi * 0.85, { 1, 1, 1 })
  end
end

function love.load()
  love.window.setTitle("processo de penrose")
  love.window.setMode(W, H)
  fontes.p = love.graphics.newFont(13)
  fontes.m = love.graphics.newFont(17)
  fontes.g = love.graphics.newFont(26)
  reinicia()
end

function love.keypressed(k)
  if k == "up" then rq = math.min(rq + 0.05, 1.95)
  elseif k == "down" then rq = math.max(rq - 0.05, 1.05)
  elseif k == "right" then v = math.min(v + 0.02, 0.99)
  elseif k == "left" then v = math.max(v - 0.02, 0.5)
  elseif k == "1" then a = math.max(a - 0.01, 0.5)
  elseif k == "2" then a = math.min(a + 0.01, 0.999)
  elseif k == "=" or k == "kp+" then ritmo = math.min(ritmo * 2, 8) return
  elseif k == "-" or k == "kp-" then ritmo = math.max(ritmo / 2, 0.125) return
  elseif k == "space" then pausado = not pausado return
  elseif k == "escape" then love.event.quit() return
  elseif k ~= "r" then return
  end
  rq = math.floor(rq * 100 + 0.5) / 100
  reinicia()
end

local function xy(c) return CX + ESC * c.r * math.cos(c.phi), CY - ESC * c.r * math.sin(c.phi) end

function love.update(dt)
  if pausado then return end
  local rh = horizonte()
  local novos = {}
  for _, c in ipairs(corpos) do
    if c.vivo then
      for _ = 1, 40 do
        -- passo menor perto do horizonte
        local h = 6 * ritmo * dt / 40 * math.min(1, (c.r - rh) * 1.5)
        local ur0 = c.ur
        passo(c, h)
        if c.nome == "nave" and (c.r <= rq or (ur0 < 0 and c.ur >= 0)) then
          c.vivo = false
          novos[#novos + 1] = novo("tras", q.tras.E, q.tras.L, rq, 0, c.phi, { 1, 0.35, 0.3 })
          novos[#novos + 1] = novo("frente", q.frente.E, q.frente.L, rq, 0, c.phi, { 0.4, 1, 0.5 })
          break
        end
        if c.r < rh + 0.02 or c.r > 9.5 then c.vivo = false break end
      end
      local x, y = xy(c)
      local ult = c.rastro[#c.rastro]
      if not ult or (x - ult[1]) ^ 2 + (y - ult[2]) ^ 2 > 4 then
        c.rastro[#c.rastro + 1] = { x, y }
      end
    end
  end
  for _, n in ipairs(novos) do corpos[#corpos + 1] = n end
end

local function buraco()
  local rh = horizonte()
  -- ergosfera (no equador vai ate r = 2)
  love.graphics.setColor(0.35, 0.2, 0.55, 0.35)
  love.graphics.circle("fill", CX, CY, 2 * ESC)
  love.graphics.setColor(0.7, 0.5, 1, 0.8)
  love.graphics.circle("line", CX, CY, 2 * ESC)
  love.graphics.setColor(0, 0, 0)
  love.graphics.circle("fill", CX, CY, rh * ESC)
  love.graphics.setColor(1, 1, 1, 0.3)
  love.graphics.circle("line", CX, CY, rh * ESC)
  -- raio da quebra
  love.graphics.setColor(1, 0.85, 0.3, 0.35)
  love.graphics.circle("line", CX, CY, rq * ESC)
  -- sentido do giro (anti-horario)
  love.graphics.setColor(0.7, 0.5, 1, 0.8)
  love.graphics.arc("line", "open", CX, CY, 2.35 * ESC, -0.3, -1.3)
  local ang = -1.3
  local px, py = CX + 2.35 * ESC * math.cos(ang), CY + 2.35 * ESC * math.sin(ang)
  love.graphics.polygon("fill", px, py, px + 9, py - 3, px + 3, py + 9)
  love.graphics.setFont(fontes.p)
  love.graphics.print("ergosfera", CX + 2 * ESC + 6, CY - 8)
end

local function painel()
  local x = 720
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(fontes.g)
  love.graphics.print("PROCESSO DE PENROSE", x, 30)
  love.graphics.setFont(fontes.m)
  love.graphics.print(string.format("a = %.2f   quebra em r = %.2f   v = %.2f", a, rq, v), x, 76)
  love.graphics.setFont(fontes.p)
  local y = 116
  local function linha(txt, cor)
    love.graphics.setColor(cor or { 1, 1, 1, 0.85 })
    love.graphics.print(txt, x, y)
    y = y + 20
  end
  linha(string.format("horizonte em r = %.3f, ergosfera ate r = 2", horizonte()))
  y = y + 10
  if not q or erro then
    linha("nao da: " .. erro, { 1, 0.5, 0.4 })
  else
    linha("nave: E = 1 (caiu parada do infinito)")
    linha(string.format("metade de tras:   E = %+.4f", q.tras.m * q.tras.E), { 1, 0.45, 0.4 })
    linha(string.format("metade da frente: E = %+.4f", q.frente.m * q.frente.E), { 0.5, 1, 0.6 })
    y = y + 10
    local ganho = q.frente.m * q.frente.E - 1
    if ganho > 0 then
      linha(string.format("ganho: +%.2f%% de energia", 100 * ganho), { 0.5, 1, 0.6 })
      linha(string.format("o buraco perde %.4f de massa (por massa da nave)", -q.tras.m * q.tras.E))
    else
      linha(string.format("perde %.2f%%: a metade de tras ainda tem E > 0", -100 * ganho), { 1, 0.6, 0.4 })
      linha("(quebra mais pra dentro ou aumenta v)")
    end
  end
  y = y + 20
  love.graphics.setColor(1, 1, 1, 0.6)
  love.graphics.printf("dentro da ergosfera nada consegue ficar parado: ate a metade jogada pra tras " ..
    "gira junto com o buraco. vista de longe a energia dela eh negativa, entao quando ela cai a massa " ..
    "do buraco diminui e a metade da frente sai com a diferenca.", x, y, 340)
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.print("cima/baixo: raio da quebra   esquerda/direita: v   1/2: rotacao   " ..
    "+/-: ritmo   espaco: pausa   r: reinicia", 30, H - 28)
end

function love.draw()
  love.graphics.clear(0.03, 0.03, 0.05)
  buraco()
  for _, c in ipairs(corpos) do
    if #c.rastro > 1 then
      local pts = {}
      for _, p in ipairs(c.rastro) do pts[#pts + 1], pts[#pts + 2] = p[1], p[2] end
      love.graphics.setColor(c.cor[1], c.cor[2], c.cor[3], 0.6)
      love.graphics.line(pts)
    end
    if c.vivo then
      local x, y = xy(c)
      love.graphics.setColor(c.cor)
      love.graphics.circle("fill", x, y, 5)
    end
  end
  painel()
end
