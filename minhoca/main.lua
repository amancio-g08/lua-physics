-- main.lua
-- buraco de minhoca (ellis) no diagrama de imersao, com alguem atravessando (love2d)
-- uso: love minhoca
--
-- o formato eh o mesmo pra qualquer b0, so os numeros mudam
-- r = sqrt(l^2 + b0^2), z = b0 asinh(l / b0)

local W, H = 1100, 700
local CX, CY, S = 350, 360, 68     -- centro e px por b0
local INC = 0.38                   -- inclinacao da camera
local LMAX = 4

local C, G = 299792458.0, 6.674e-11
local g, XI = 9.81, 2              -- 1 g e tamanho da pessoa (m)
local TAMANHOS = { 1, 100, 1000, 1e5, 1e8 }

local ib, f = 3, 1                 -- tamanho da garganta e velocidade (fracao da maxima)
local giro, l = 0, -LMAX - 0.5
local pausado = false
local fontes = {}

local function raio(x) return math.sqrt(x * x + 1) end
local function altura(x) return math.log(x + math.sqrt(x * x + 1)) end

-- ponto da superficie na tela; devolve tambem se esta na frente
local function tela(x, th)
  local r, z = raio(x), altura(x)
  local px = CX + S * r * math.cos(th + giro)
  local prof = math.sin(th + giro)
  local py = CY - S * z * math.cos(INC) + S * r * prof * math.sin(INC)
  return px, py, prof
end

function love.load()
  love.window.setTitle("buraco de minhoca")
  love.window.setMode(W, H)
  fontes.p = love.graphics.newFont(13)
  fontes.m = love.graphics.newFont(17)
  fontes.g = love.graphics.newFont(26)
end

function love.keypressed(k)
  if k == "up" then ib = math.min(ib + 1, #TAMANHOS)
  elseif k == "down" then ib = math.max(ib - 1, 1)
  elseif k == "right" then f = math.min(f + 0.25, 3)
  elseif k == "left" then f = math.max(f - 0.25, 0.25)
  elseif k == "space" then pausado = not pausado
  elseif k == "r" then l = -LMAX - 0.5
  elseif k == "escape" then love.event.quit()
  end
end

function love.update(dt)
  if pausado then return end
  giro = giro + 0.15 * dt
  l = l + 1.2 * dt
  if l > LMAX + 0.5 then l = -LMAX - 0.5 end
end

local function superficie()
  -- aneis, mais vermelhos onde a energia negativa eh maior (1 / r^4)
  for i = -32, 32 do
    local x = LMAX * i / 32
    local forca = 1 / raio(x) ^ 4
    local n = 72
    for j = 0, n - 1 do
      local a0, a1 = 2 * math.pi * j / n, 2 * math.pi * (j + 1) / n
      local x0, y0, p0 = tela(x, a0)
      local x1, y1 = tela(x, a1)
      local alfa = (0.12 + 0.6 * forca) * (p0 > 0 and 1 or 0.35)
      love.graphics.setColor(0.4 + 0.6 * forca, 0.5 - 0.3 * forca, 1 - 0.7 * forca, alfa)
      love.graphics.line(x0, y0, x1, y1)
    end
  end
  -- meridianos
  for j = 0, 15 do
    local th = 2 * math.pi * j / 16
    for i = -32, 31 do
      local xa, xb = LMAX * i / 32, LMAX * (i + 1) / 32
      local x0, y0, p0 = tela(xa, th)
      local x1, y1 = tela(xb, th)
      love.graphics.setColor(0.6, 0.7, 1, p0 > 0 and 0.35 or 0.12)
      love.graphics.line(x0, y0, x1, y1)
    end
  end
  love.graphics.setFont(fontes.p)
  love.graphics.setColor(1, 1, 1, 0.6)
  love.graphics.print("lado de la", CX - 30, CY - S * altura(LMAX) * math.cos(INC) - 70)
  love.graphics.print("lado de ca", CX - 30, CY + S * altura(LMAX) * math.cos(INC) + 58)
  love.graphics.print("garganta (r = b0)", CX + S + 14, CY - 8)
end

local function viajante()
  if math.abs(l) > LMAX then return end
  local th = math.pi / 2 - giro            -- sempre na frente
  local x, y = tela(l, th)
  love.graphics.setColor(1, 0.75, 0.2)
  love.graphics.circle("fill", x, y, 7)
end

local function painel()
  local b0 = TAMANHOS[ib]
  local w = b0 * math.sqrt(g / XI) * f           -- gamma v
  local v = w / math.sqrt(1 + (w / C) ^ 2)
  local r = b0 * raio(l)
  local rho = -C ^ 4 * b0 * b0 / (8 * math.pi * G * r ^ 4)
  local mare = w * w * XI * b0 * b0 / r ^ 4      -- gamma^2 v^2 xi b0^2 / r^4
  local massa = math.pi / 2 * b0 * C * C / G
  local x = 720
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(fontes.g)
  love.graphics.print("BURACO DE MINHOCA", x, 30)
  love.graphics.setFont(fontes.m)
  love.graphics.print(string.format("garganta b0 = %g m", b0), x, 76)
  love.graphics.setFont(fontes.p)
  local y = 116
  local function linha(txt, cor)
    love.graphics.setColor(cor or { 1, 1, 1, 0.85 })
    love.graphics.print(txt, x, y)
    y = y + 20
  end
  linha(string.format("energia negativa no total: %.3g kg", -massa), { 1, 0.5, 0.45 })
  linha(string.format("(%.3g jupiters, %.3g sois)", massa / 1.898e27, massa / 1.989e30), { 1, 0.5, 0.45 })
  y = y + 12
  linha(string.format("velocidade: %.3g m/s (%.2f da maxima)", v, f))
  if math.abs(l) <= LMAX then
    linha(string.format("posicao: l = %.2f b0, r = %.3g m", l, r))
    linha(string.format("densidade aqui: %.2e J/m^3", rho), { 1, 0.5, 0.45 })
    local cor = mare > g * 1.001 and { 1, 0.35, 0.3 } or { 0.5, 1, 0.6 }
    linha(string.format("mare na pessoa (2 m): %.2f g%s", mare / g, mare > g * 1.001 and "  esticado!" or ""), cor)
  else
    linha("posicao: fora do desenho")
  end
  linha(string.format("atravessa (l = -10 b0 ate 10 b0) em %.2f s", 20 * b0 / w))
  y = y + 12
  love.graphics.setColor(1, 1, 1, 0.6)
  love.graphics.printf("o desenho eh o diagrama de imersao: a superficie mostra como o espaco se curva, " ..
    "a altura nao eh uma direcao de verdade. vermelho = mais energia negativa. " ..
    "o formato eh igual pra qualquer b0, so mudam os numeros.", x, y, 350)
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.print("cima/baixo: tamanho da garganta   esquerda/direita: velocidade   espaco: pausa   r: reinicia",
    30, H - 28)
end

function love.draw()
  love.graphics.clear(0.03, 0.03, 0.05)
  superficie()
  viajante()
  painel()
end
