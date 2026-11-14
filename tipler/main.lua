-- main.lua
-- nave dando voltas no cilindro girando (love2d)
-- uso: love tipler
--
-- c = G = 1, comprimento em L = 1/a (1 hora-luz), tempo em horas
-- t = relogio da poeira (de fora), tau = relogio da nave

local W, H = 1100, 700
local CX, CY = 330, 360     -- eixo do cilindro (px)
local PXL = 110             -- px por L
local RMAX = 2.8            -- borda desenhada (L)
local a = 1.0

local r, v = 1.5, 0.8       -- raio da volta (L) e velocidade em relacao a poeira (c)
local ritmo = 1
local pausado = false
local phi, t, tau, hist
local fontes = {}

-- dt/dphi = r (1/v - a r), dtau/dphi = (r/v) sqrt(1 - v^2)
local function taxas()
  return r * (1 / v - a * r), r / v * math.sqrt(1 - v * v)
end

local function reinicia()
  phi, t, tau = 0, 0, 0
  hist = { { 0, 0 } }
end

function love.load()
  love.window.setTitle("cilindro de tipler")
  love.window.setMode(W, H)
  fontes.p = love.graphics.newFont(13)
  fontes.m = love.graphics.newFont(17)
  fontes.g = love.graphics.newFont(26)
  reinicia()
end

function love.keypressed(k)
  if k == "up" then r = math.min(r + 0.1, 2.5)
  elseif k == "down" then r = math.max(r - 0.1, 0.3)
  elseif k == "right" then v = math.min(v + 0.05, 0.95)
  elseif k == "left" then v = math.max(v - 0.05, 0.1)
  elseif k == "=" or k == "kp+" then ritmo = math.min(ritmo * 2, 8) return
  elseif k == "-" or k == "kp-" then ritmo = math.max(ritmo / 2, 0.125) return
  elseif k == "space" then pausado = not pausado return
  elseif k == "escape" then love.event.quit() return
  elseif k ~= "r" then return
  end
  r = math.floor(r * 10 + 0.5) / 10
  v = math.floor(v * 100 + 0.5) / 100
  reinicia()
end

function love.update(dt)
  if pausado then return end
  local dphi = 1.2 * ritmo * dt
  local dtp, dtaup = taxas()
  phi = phi + dphi
  t = t + dtp * dphi
  tau = tau + dtaup * dphi
  local ult = hist[#hist]
  if tau - ult[1] > 0.05 then
    hist[#hist + 1] = { tau, t }
    if #hist > 2000 then table.remove(hist, 1) end
  end
end

local function circulo_tracejado(x, y, raio, n)
  for i = 0, n - 1, 2 do
    local a0, a1 = i / n * 2 * math.pi, (i + 1) / n * 2 * math.pi
    love.graphics.line(x + raio * math.cos(a0), y + raio * math.sin(a0),
      x + raio * math.cos(a1), y + raio * math.sin(a1))
  end
end

local function cilindro()
  -- densidade cresce com exp(a^2 r^2)
  local topo = math.exp(RMAX * RMAX) - 1
  for i = 60, 1, -1 do
    local rr = RMAX * i / 60
    local d = (math.exp(a * a * rr * rr) - 1) / topo
    love.graphics.setColor(0.10 + 0.25 * d, 0.10 + 0.18 * d, 0.16 + 0.10 * d)
    love.graphics.circle("fill", CX, CY, rr * PXL)
  end
  -- seta da rotacao
  love.graphics.setColor(1, 1, 1, 0.25)
  love.graphics.arc("line", "open", CX, CY, 0.35 * PXL, -2.2, 0.6)
  love.graphics.circle("fill", CX, CY, 4)
  -- r = 1/a: daqui pra fora g_phiphi < 0
  love.graphics.setColor(1, 0.45, 0.3, 0.9)
  circulo_tracejado(CX, CY, PXL / a, 80)
  love.graphics.setFont(fontes.p)
  love.graphics.print("r = 1/a", CX + PXL / a * 0.72, CY - PXL / a * 0.72 - 16)
  -- r = 1/v: daqui pra fora a nave volta no tempo
  love.graphics.setColor(0.4, 0.8, 1, 0.8)
  circulo_tracejado(CX, CY, PXL / (a * v), 60)
  love.graphics.print("r = 1/(a v)", CX + PXL / (a * v) * 0.72 + 4, CY + PXL / (a * v) * 0.72)
end

local function nave()
  local rr = r * PXL
  love.graphics.setColor(1, 1, 1, 0.3)
  love.graphics.circle("line", CX, CY, rr)
  local x, y = CX + rr * math.cos(phi), CY + rr * math.sin(phi)
  local ang = phi + math.pi / 2
  love.graphics.setColor(1, 0.55, 0.15)
  love.graphics.polygon("fill",
    x + 12 * math.cos(ang), y + 12 * math.sin(ang),
    x + 7 * math.cos(ang + 2.4), y + 7 * math.sin(ang + 2.4),
    x + 7 * math.cos(ang - 2.4), y + 7 * math.sin(ang - 2.4))
end

-- cone de luz no plano (x = r phi, t): bordas (1, 1 - ar) e (-1, 1 + ar)
local function cone(x, y, ar, tam, destaque)
  local function norm(dx, dt)
    local m = math.sqrt(dx * dx + dt * dt)
    return dx / m, dt / m
  end
  local ax, at = norm(1, 1 - ar)
  local bx, bt = norm(-1, 1 + ar)
  local a0 = math.atan2(at, ax)
  local a1 = math.atan2(bt, bx)
  local pts = { x, y }
  for i = 0, 20 do
    local ang = a0 + (a1 - a0) * i / 20
    pts[#pts + 1] = x + tam * math.cos(ang)
    pts[#pts + 1] = y - tam * math.sin(ang)
  end
  love.graphics.setColor(1, 0.85, 0.3, destaque and 0.45 or 0.25)
  love.graphics.polygon("fill", pts)
  love.graphics.setColor(1, 0.85, 0.3)
  love.graphics.line(x, y, x + tam * ax, y - tam * at)
  love.graphics.line(x, y, x + tam * bx, y - tam * bt)
  -- linha de t parado
  love.graphics.setColor(1, 1, 1, 0.3)
  love.graphics.line(x - tam, y, x + tam, y)
  love.graphics.line(x, y - tam, x, y + tam)
end

local function cones()
  local x0, y0 = 610, 545
  love.graphics.setFont(fontes.p)
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.print("cone de luz (horizontal: sentido da rotacao, vertical: t)", x0, y0 - 80)
  local lista = { 0, 0.5, 1.0, 1.5, 2.0 }
  for i, ar in ipairs(lista) do
    local x = x0 + (i - 1) * 78
    cone(x, y0, ar, 34)
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf(string.format("a r = %.1f", ar), x - 40, y0 + 42, 80, "center")
  end
  -- cone onde a nave esta, com o caminho dela
  local x = x0 + 5 * 78 + 15
  cone(x, y0, a * r, 34, true)
  local m = math.sqrt(1 + (1 / v - a * r) ^ 2)
  love.graphics.setColor(1, 0.55, 0.15)
  love.graphics.setLineWidth(3)
  love.graphics.line(x, y0, x + 34 / m, y0 - 34 * (1 / v - a * r) / m)
  love.graphics.setLineWidth(1)
  love.graphics.printf("nave", x - 40, y0 + 42, 80, "center")
end

local function grafico()
  local x0, y0, gw, gh = 640, 150, 420, 230
  love.graphics.setColor(1, 1, 1, 0.08)
  love.graphics.rectangle("fill", x0, y0, gw, gh)
  local tmin, tmax = 0, 1
  for _, p in ipairs(hist) do
    tmin, tmax = math.min(tmin, p[2]), math.max(tmax, p[2])
  end
  local taumax = math.max(hist[#hist][1], 1)
  local taumin = hist[1][1]
  local function ponto(p)
    return x0 + (p[1] - taumin) / (taumax - taumin + 1e-9) * gw,
      y0 + gh - (p[2] - tmin) / (tmax - tmin) * gh
  end
  -- t = 0 (hora da partida)
  local _, yz = ponto({ 0, 0 })
  love.graphics.setColor(1, 1, 1, 0.3)
  love.graphics.line(x0, yz, x0 + gw, yz)
  if #hist > 1 then
    local pts = {}
    for _, p in ipairs(hist) do
      local px, py = ponto(p)
      pts[#pts + 1], pts[#pts + 2] = px, py
    end
    love.graphics.setColor(1, 0.55, 0.15)
    love.graphics.setLineWidth(2)
    love.graphics.line(pts)
    love.graphics.setLineWidth(1)
  end
  love.graphics.setFont(fontes.p)
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.print("relogio da nave (tau) ->", x0 + gw - 170, y0 + gh + 4)
  love.graphics.print("relogio de fora (t)", x0, y0 - 18)
  love.graphics.print("partida", x0 + 4, yz - 16)
end

local function painel()
  local dtp, dtaup = taxas()
  local g = 1 / math.sqrt(1 - v * v)
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(fontes.g)
  love.graphics.print("CILINDRO DE TIPLER", 30, 24)
  love.graphics.setFont(fontes.m)
  love.graphics.print(string.format("r = %.1f L    v = %.2f c    a r v = %.2f", r, v, a * r * v), 30, 62)
  love.graphics.setFont(fontes.m)
  love.graphics.setColor(1, 0.55, 0.15)
  love.graphics.print(string.format("nave (tau): %8.2f h", tau), 640, 40)
  if dtp < 0 then love.graphics.setColor(0.4, 0.8, 1) else love.graphics.setColor(1, 1, 1) end
  love.graphics.print(string.format("fora (t):   %8.2f h", t), 640, 64)
  love.graphics.setFont(fontes.p)
  love.graphics.setColor(1, 1, 1, 0.8)
  local msg
  if dtp < 0 then
    msg = string.format("cada volta: a nave envelhece %.2f h e chega %.2f h antes", 2 * math.pi * dtaup, -2 * math.pi * dtp)
  else
    msg = string.format("cada volta: a nave envelhece %.2f h, la fora passam %.2f h", 2 * math.pi * dtaup, 2 * math.pi * dtp)
  end
  love.graphics.print(msg, 640, 92)
  love.graphics.print(string.format("dt/dtau = gamma (1 - a r v) = %.3f", g * (1 - a * r * v)), 640, 110)
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.print("cima/baixo: raio   esquerda/direita: v   +/-: ritmo   espaco: pausa   r: reinicia",
    30, H - 28)
end

function love.draw()
  love.graphics.clear(0.03, 0.03, 0.05)
  cilindro()
  nave()
  grafico()
  cones()
  painel()
end
