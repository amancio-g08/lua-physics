-- main.lua
-- animacao do 2FA relativistico (love2d)
-- uso: love 2fa

local totp = require("totp")

local SENHA = "senha-secreta-do-viajante"
local INICIO = 1763000010  -- comeco de uma janela de 30 s
local FOLGA = 1            -- janelas de atraso que o servidor aceita

local BETAS = { 0, 0.1, 0.3, 0.5, 0.8, 0.9, 0.99 }
local RITMOS = { 1, 2, 5, 10, 30 }  -- segundos da terra por segundo real

local ib, ir = 5, 3     -- comeca em beta 0.8, 5x
local t, tau = 0, 0     -- relogio da terra e do viajante
local trancado          -- primeiro instante (terra) em que recusou
local pausado = false
local estrelas = {}
local cache = {}
local fontes = {}

local function gamma(b) return 1 / math.sqrt(1 - b * b) end

local function codigo(tempo)
  local j = math.floor((INICIO + tempo) / 30)
  if not cache[j] then cache[j] = totp.codigo(SENHA, INICIO + tempo) end
  return cache[j]
end

local function atraso()
  return math.floor((INICIO + t) / 30) - math.floor((INICIO + tau) / 30)
end

local function relogio(s)
  return string.format("%02d:%04.1f", math.floor(s / 60), s % 60)
end

local function reinicia()
  t, tau, trancado = 0, 0, nil
end

function love.load()
  love.window.setTitle("2FA relativistico")
  love.window.setMode(1000, 600)
  fontes.p = love.graphics.newFont(14)
  fontes.m = love.graphics.newFont(20)
  fontes.g = love.graphics.newFont(44)
  for i = 1, 160 do
    estrelas[i] = { x = math.random() * 1000, y = math.random() * 600, z = math.random() }
  end
end

function love.keypressed(k)
  if k == "up" then ib = math.min(ib + 1, #BETAS)
  elseif k == "down" then ib = math.max(ib - 1, 1)
  elseif k == "right" then ir = math.min(ir + 1, #RITMOS)
  elseif k == "left" then ir = math.max(ir - 1, 1)
  elseif k == "space" then pausado = not pausado
  elseif k == "r" then reinicia()
  elseif k == "escape" then love.event.quit()
  end
end

function love.update(dt)
  local beta = BETAS[ib]
  local passo = pausado and 0 or dt * RITMOS[ir]
  t = t + passo
  tau = tau + passo / gamma(beta)  -- o relogio dele anda 1/gamma do nosso
  if not trancado and atraso() > FOLGA then trancado = t end

  for _, e in ipairs(estrelas) do
    e.x = e.x - (20 + 1400 * beta) * (0.3 + e.z) * (pausado and 0 or dt)
    if e.x < 0 then e.x, e.y = e.x + 1000, math.random() * 600 end
  end
end

local function painel(x, titulo, cor, tempo, sub)
  local w, y = 300, 30
  love.graphics.setColor(0.09, 0.09, 0.14, 0.95)
  love.graphics.rectangle("fill", x, y, w, 190, 8)
  love.graphics.setColor(cor)
  love.graphics.setFont(fontes.m)
  love.graphics.print(titulo, x + 16, y + 12)
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(fontes.p)
  love.graphics.print("relogio " .. relogio(tempo) .. "   " .. sub, x + 16, y + 44)
  love.graphics.setFont(fontes.g)
  love.graphics.print(codigo(tempo), x + 16, y + 70)
  -- barra da janela de 30 s
  local frac = ((INICIO + tempo) % 30) / 30
  love.graphics.setColor(1, 1, 1, 0.15)
  love.graphics.rectangle("fill", x + 16, y + 140, w - 32, 10, 4)
  love.graphics.setColor(cor)
  love.graphics.rectangle("fill", x + 16, y + 140, (w - 32) * (1 - frac), 10, 4)
  love.graphics.setColor(1, 1, 1, 0.6)
  love.graphics.setFont(fontes.p)
  love.graphics.print(string.format("muda em %.0f s", 30 * (1 - frac)), x + 16, y + 158)
end

local function foguete(x, y)
  local chama = 18 + math.random() * 14
  love.graphics.setColor(1, 0.6, 0.1)
  love.graphics.polygon("fill", x - 40, y - 8, x - 40 - chama, y, x - 40, y + 8)
  love.graphics.setColor(0.85, 0.85, 0.9)
  love.graphics.polygon("fill", x + 50, y, x + 20, y - 14, x - 40, y - 14, x - 40, y + 14, x + 20, y + 14)
  love.graphics.setColor(0.3, 0.6, 1)
  love.graphics.circle("fill", x + 14, y, 6)
end

function love.draw()
  local beta = BETAS[ib]
  local g = gamma(beta)
  love.graphics.clear(0.02, 0.02, 0.06)

  -- estrelas esticam com a velocidade
  for _, e in ipairs(estrelas) do
    local rastro = 1 + 40 * beta * e.z
    love.graphics.setColor(1, 1, 1, 0.3 + 0.6 * e.z)
    love.graphics.line(e.x, e.y, e.x + rastro, e.y)
  end

  -- terra a esquerda, foguete indo embora
  love.graphics.setColor(0.15, 0.4, 0.9)
  love.graphics.circle("fill", -50, 400, 110)
  love.graphics.setColor(0.2, 0.7, 0.3)
  love.graphics.circle("fill", -5, 370, 30)
  foguete(560, 400 + math.sin(love.timer.getTime() * 2) * 4)

  painel(40, "TERRA (servidor)", { 0.4, 0.7, 1 }, t, "")
  painel(660, "VIAJANTE (celular)", { 1, 0.6, 0.2 }, tau,
    string.format("anda a %.0f%%", 100 / g))

  -- resultado do login
  local a = atraso()
  local txt, cor
  if a == 0 then txt, cor = "ACEITO", { 0.3, 0.9, 0.4 }
  elseif a <= FOLGA then txt, cor = "ACEITO (na folga)", { 1, 0.85, 0.2 }
  else txt, cor = "RECUSADO", { 1, 0.25, 0.25 }
  end
  love.graphics.setColor(0.02, 0.02, 0.06, 0.85)
  love.graphics.rectangle("fill", 260, 240, 480, 130, 8)
  love.graphics.rectangle("fill", 0, 505, 1000, 95)
  love.graphics.setColor(cor)
  love.graphics.setFont(fontes.g)
  love.graphics.printf(txt, 0, 250, 1000, "center")
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(fontes.m)
  love.graphics.printf(string.format("atraso: %d janela(s) de 30 s   (folga: %d)", a, FOLGA),
    0, 305, 1000, "center")
  if trancado then
    love.graphics.setColor(1, 0.4, 0.4)
    love.graphics.printf(string.format("trancado pra fora aos %.0f s na terra", trancado),
      0, 335, 1000, "center")
  end

  -- rodape
  love.graphics.setColor(1, 1, 1, 0.85)
  love.graphics.setFont(fontes.m)
  love.graphics.print(string.format("beta %.2f   gamma %.3f   tempo %dx%s",
    beta, g, RITMOS[ir], pausado and "   PAUSADO" or ""), 40, 520)
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.setFont(fontes.p)
  love.graphics.print("cima/baixo: velocidade   esquerda/direita: ritmo do tempo   espaco: pausa   r: reinicia",
    40, 560)
end
