-- main.lua
-- orbita de mercurio com a correcao da relatividade exagerada (love2d)
-- uso: love mercurio
--
-- unidades: GM = 1, a = 1 (periodo 2 pi)
-- aceleracao: -(GM / r^2) (1 + 3 h^2 / (c^2 r^2)), com 3 / c^2 = lam p

local W, H = 1100, 700
local CX, CY, ESC = 400, 360, 230   -- sol e px por unidade
local E = 0.205630                  -- excentricidade de mercurio
local P = 1 - E * E                 -- semi-latus rectum (a = 1)
local LAM_REAL = 3 * 1.32712440018e20 / (299792458 ^ 2 * 5.7909e10 * P)
local EXAGEROS = { 1e4, 1e5, 3e5, 1e6, 2e6 }

local iex = 4
local ritmo = 1
local pausado = false
local gr, nw, perielios, rastro, voltas, h2gr
local fontes = {}

local function lam() return LAM_REAL * EXAGEROS[iex] end

local function acel(x, y, k)
  local r2 = x * x + y * y
  local r = math.sqrt(r2)
  local f = (1 + k * lam() * P * h2gr / r2) / (r2 * r)
  return -f * x, -f * y
end

-- h^2 pra orbita com relatividade ter o mesmo perielio e afelio que a de newton
-- energia: h^2 / (2 r^2) - 1/r - kap h^2 / (3 r^3) igual nos dois pontos
local function h2_mesma_orbita(rp, ra)
  local kap = lam() * P
  local coef = (1 / rp ^ 2 - 1 / ra ^ 2) / 2 - kap / 3 * (1 / rp ^ 3 - 1 / ra ^ 3)
  return (1 / rp - 1 / ra) / coef
end

local function passo(c, h, k)
  local function d(x, y, vx, vy)
    local ax, ay = acel(x, y, k)
    return vx, vy, ax, ay
  end
  local x, y, vx, vy = c.x, c.y, c.vx, c.vy
  local a1, b1, c1, d1 = d(x, y, vx, vy)
  local a2, b2, c2, d2 = d(x + h / 2 * a1, y + h / 2 * b1, vx + h / 2 * c1, vy + h / 2 * d1)
  local a3, b3, c3, d3 = d(x + h / 2 * a2, y + h / 2 * b2, vx + h / 2 * c2, vy + h / 2 * d2)
  local a4, b4, c4, d4 = d(x + h * a3, y + h * b3, vx + h * c3, vy + h * d3)
  c.x = x + h / 6 * (a1 + 2 * a2 + 2 * a3 + a4)
  c.y = y + h / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
  c.vx = vx + h / 6 * (c1 + 2 * c2 + 2 * c3 + c4)
  c.vy = vy + h / 6 * (d1 + 2 * d2 + 2 * d3 + d4)
end

local function reinicia()
  -- comeca no perielio, velocidade pela vis-viva
  local rp = 1 - E
  local vp = math.sqrt((1 + E) / (1 - E))
  h2gr = h2_mesma_orbita(rp, 1 + E)
  gr = { x = rp, y = 0, vx = 0, vy = math.sqrt(h2gr) / rp }
  nw = { x = rp, y = 0, vx = 0, vy = vp }
  perielios = { 0 }
  rastro = {}
  voltas = 0
end

function love.load()
  love.window.setTitle("precessao de mercurio")
  love.window.setMode(W, H)
  fontes.p = love.graphics.newFont(13)
  fontes.m = love.graphics.newFont(17)
  fontes.g = love.graphics.newFont(26)
  reinicia()
end

function love.keypressed(k)
  if k == "up" then iex = math.min(iex + 1, #EXAGEROS)
  elseif k == "down" then iex = math.max(iex - 1, 1)
  elseif k == "=" or k == "kp+" then ritmo = math.min(ritmo * 2, 8) return
  elseif k == "-" or k == "kp-" then ritmo = math.max(ritmo / 2, 0.125) return
  elseif k == "space" then pausado = not pausado return
  elseif k == "escape" then love.event.quit() return
  elseif k ~= "r" then return
  end
  reinicia()
end

local function rdot(c) return c.x * c.vx + c.y * c.vy end

function love.update(dt)
  if pausado then return end
  local n = 200
  local h = 2.2 * ritmo * dt / n
  for _ = 1, n do
    local antes = rdot(gr)
    passo(gr, h, 1)
    passo(nw, h, 0)
    -- perielio: r para de diminuir e comeca a crescer
    if antes < 0 and rdot(gr) >= 0 then
      perielios[#perielios + 1] = math.atan2(gr.y, gr.x)
      voltas = voltas + 1
    end
  end
  local ult = rastro[#rastro]
  local x, y = CX + ESC * gr.x, CY - ESC * gr.y
  if not ult or (x - ult[1]) ^ 2 + (y - ult[2]) ^ 2 > 9 then
    rastro[#rastro + 1] = { x, y }
    if #rastro > 4000 then table.remove(rastro, 1) end
  end
end

local function cena()
  -- elipse de newton (fecha sempre no mesmo lugar)
  local pts = {}
  for i = 0, 200 do
    local th = 2 * math.pi * i / 200
    local r = P / (1 + E * math.cos(th))
    pts[#pts + 1] = CX + ESC * r * math.cos(th)
    pts[#pts + 1] = CY - ESC * r * math.sin(th)
  end
  love.graphics.setColor(1, 1, 1, 0.25)
  love.graphics.line(pts)
  -- caminho com relatividade
  if #rastro > 1 then
    local t = {}
    for _, p in ipairs(rastro) do t[#t + 1], t[#t + 2] = p[1], p[2] end
    love.graphics.setColor(1, 0.6, 0.25, 0.7)
    love.graphics.line(t)
  end
  -- linhas do sol ate cada perielio
  for i, ang in ipairs(perielios) do
    local r = 1 - E
    love.graphics.setColor(0.4, 0.8, 1, i == #perielios and 0.9 or 0.3)
    love.graphics.line(CX, CY, CX + ESC * r * math.cos(ang), CY - ESC * r * math.sin(ang))
  end
  -- sol
  love.graphics.setColor(1, 0.85, 0.3, 0.25)
  love.graphics.circle("fill", CX, CY, 22)
  love.graphics.setColor(1, 0.9, 0.4)
  love.graphics.circle("fill", CX, CY, 13)
  -- planetas
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.circle("fill", CX + ESC * nw.x, CY - ESC * nw.y, 5)
  love.graphics.setColor(1, 0.6, 0.25)
  love.graphics.circle("fill", CX + ESC * gr.x, CY - ESC * gr.y, 7)
end

local function painel()
  local x = 700
  local seg = 180 / math.pi * 3600
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(fontes.g)
  love.graphics.print("PRECESSAO DE MERCURIO", x, 30)
  love.graphics.setFont(fontes.m)
  love.graphics.print(string.format("exagero: %g vezes", EXAGEROS[iex]), x, 76)
  love.graphics.setFont(fontes.p)
  local y = 116
  local function linha(txt, cor)
    love.graphics.setColor(cor or { 1, 1, 1, 0.85 })
    love.graphics.print(txt, x, y)
    y = y + 20
  end
  linha(string.format("voltas: %d", voltas))
  if #perielios > 1 then
    local d = perielios[#perielios] - perielios[#perielios - 1]
    if d < -math.pi then d = d + 2 * math.pi end
    linha(string.format("perielio andou: %.2f graus na ultima volta", math.deg(d)), { 0.4, 0.8, 1 })
  else
    linha("perielio andou: (esperando a primeira volta)", { 0.4, 0.8, 1 })
  end
  linha(string.format("formula 6 pi GM / (c^2 a (1 - e^2)): %.2f graus", math.deg(2 * math.pi * lam())))
  linha(string.format("sem aproximar, 2 pi (1/sqrt(1 - 2 lam) - 1): %.2f graus",
    math.deg(2 * math.pi * (1 / math.sqrt(1 - 2 * lam()) - 1))))
  y = y + 14
  linha("de verdade (sem exagero):", { 1, 1, 1 })
  linha(string.format("%.4f segundo de arco por volta", 2 * math.pi * LAM_REAL * seg))
  linha(string.format("%.2f por seculo", 2 * math.pi * LAM_REAL * seg * 36525 / 87.9691))
  linha(string.format("uma volta inteira do perielio: %.1f milhoes de anos",
    360 * 3600 / (2 * math.pi * LAM_REAL * seg * 36525 / 87.9691) * 100 / 1e6))
  y = y + 14
  love.graphics.setColor(1, 1, 1, 0.6)
  love.graphics.printf("bolinha branca e elipse cinza: so newton, fecha sempre no mesmo lugar. " ..
    "laranja: com a correcao da relatividade, o perielio (linhas azuis) vai girando.", x, y, 320)
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.print("cima/baixo: exagero   +/-: ritmo   espaco: pausa   r: reinicia", 30, H - 28)
end

function love.draw()
  love.graphics.clear(0.03, 0.03, 0.05)
  cena()
  painel()
end
