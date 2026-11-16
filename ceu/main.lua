-- main.lua
-- o ceu visto da cabine de uma nave acelerando ate quase c (love2d)
-- uso: love ceu  (ou love ceu 0.9 pra ja comecar a 0.9c)
--
-- vista olho de peixe: centro = frente, borda = tras, raio proporcional ao angulo

local W, H = 1100, 700
local CX, CY, RD = 370, 355, 320   -- disco do ceu (px), RD = 180 graus
local N = 2500

local eta = 0                      -- rapidez: v = tanh(eta)
local aberr, cor, brilho = true, true, true
local estrelas = {}
local fontes = {}

-- aberracao: cos theta = (cos theta0 + b) / (1 + b cos theta0)
local function aberracao(theta0, b)
  local c0 = math.cos(theta0)
  return math.acos((c0 + b) / (1 + b * c0))
end

-- doppler: D = 1 / (gamma (1 - b cos theta))
local function doppler(theta, b)
  local g = 1 / math.sqrt(1 - b * b)
  return 1 / (g * (1 - b * math.cos(theta)))
end

-- cor de corpo negro (aproximacao de tanner helland), T em kelvin
local function rgb(T)
  local t = math.max(1000, math.min(T, 40000)) / 100
  local r, g, b
  if t <= 66 then
    r = 255
    g = 99.4708 * math.log(t) - 161.1196
  else
    r = 329.6987 * (t - 60) ^ -0.1332
    g = 288.1222 * (t - 60) ^ -0.0755
  end
  if t >= 66 then b = 255
  elseif t <= 19 then b = 0
  else b = 138.5177 * math.log(t - 10) - 305.0448 end
  local function c(x) return math.max(0, math.min(x, 255)) / 255 end
  return c(r), c(g), c(b)
end

local function sorteia_T()
  local u = math.random()
  local T
  if u < 0.5 then T = 3200 elseif u < 0.75 then T = 4500
  elseif u < 0.9 then T = 5800 elseif u < 0.97 then T = 8000 else T = 15000 end
  return T * (0.85 + 0.3 * math.random())
end

function love.load(arg)
  -- love ceu 0.9 -> ja comeca a 0.9c
  local v0 = tonumber(arg[1])
  if v0 and v0 >= 0 and v0 < 1 then eta = 0.5 * math.log((1 + v0) / (1 - v0)) end
  love.window.setTitle("ceu a quase c")
  love.window.setMode(W, H)
  fontes.p = love.graphics.newFont(13)
  fontes.m = love.graphics.newFont(17)
  fontes.g = love.graphics.newFont(26)
  math.randomseed(3)
  for i = 1, N do
    estrelas[i] = {
      theta0 = math.acos(2 * math.random() - 1),   -- uniforme na esfera
      psi = 2 * math.pi * math.random(),
      T = sorteia_T(),
      base = 0.05 + 0.95 * math.random() ^ 4,      -- muitas fracas, poucas fortes
    }
  end
end

function love.keypressed(k)
  if k == "1" then aberr = not aberr
  elseif k == "2" then cor = not cor
  elseif k == "3" then brilho = not brilho
  elseif k == "r" then eta = 0
  elseif k == "escape" then love.event.quit()
  end
end

function love.update(dt)
  if love.keyboard.isDown("up") then eta = math.min(eta + 0.5 * dt, 3.8) end
  if love.keyboard.isDown("down") then eta = math.max(eta - 0.5 * dt, 0) end
end

local function no_disco(theta, psi)
  local r = RD * theta / math.pi
  return CX + r * math.cos(psi), CY + r * math.sin(psi)
end

local function circulo_tracejado(raio, n)
  for i = 0, n - 1, 2 do
    local a0, a1 = i / n * 2 * math.pi, (i + 1) / n * 2 * math.pi
    love.graphics.line(CX + raio * math.cos(a0), CY + raio * math.sin(a0),
      CX + raio * math.cos(a1), CY + raio * math.sin(a1))
  end
end

local function grade(b)
  love.graphics.setFont(fontes.p)
  -- onde ficam os angulos de quando a nave estava parada
  local ult = -100
  for _, g in ipairs({ 30, 60, 90, 120, 150 }) do
    local th = math.rad(g)
    if aberr then th = aberracao(th, b) end
    local raio = RD * th / math.pi
    love.graphics.setColor(0.4, 0.8, 1, g == 90 and 0.6 or 0.25)
    love.graphics.circle("line", CX, CY, raio)
    if raio - ult > 24 then
      love.graphics.print(g .. "", CX + raio + 3, CY - 8)
      ult = raio
    end
  end
  -- lado da nave (90 graus pra quem esta nela)
  love.graphics.setColor(1, 1, 1, 0.35)
  circulo_tracejado(RD / 2, 90)
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.print("lado da nave", CX - 40, CY - RD / 2 - 18)
  love.graphics.line(CX - 8, CY, CX + 8, CY)
  love.graphics.line(CX, CY - 8, CX, CY + 8)
end

local function ceu(b)
  for _, e in ipairs(estrelas) do
    local th = aberracao(e.theta0, b)
    local D = doppler(th, b)
    if not aberr then th = e.theta0 end
    local T = cor and e.T * D or e.T
    local L = brilho and e.base * D ^ 4 or e.base
    local alfa = math.min(1, L * 1.5)
    if T < 1000 then alfa = alfa * (T / 1000) ^ 2 end
    if alfa > 0.02 then
      local x, y = no_disco(th, e.psi)
      local r, g, bb = rgb(T)
      local tam = 0.7 + 0.8 * math.max(0, math.log(L * 10, 10))
      tam = math.min(tam, 3.5)
      if L > 200 then
        love.graphics.setColor(r, g, bb, 0.05)
        love.graphics.circle("fill", x, y, tam * 2.5)
      end
      love.graphics.setColor(r, g, bb, alfa)
      love.graphics.circle("fill", x, y, tam)
    end
  end
end

local function painel(b)
  local g = 1 / math.sqrt(1 - b * b)
  local Df, Dt = doppler(0, b), doppler(math.pi, b)
  local x = 740
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(fontes.g)
  love.graphics.print("CEU A QUASE C", x, 30)
  love.graphics.setFont(fontes.m)
  love.graphics.print(string.format("v = %.4f c", b), x, 80)
  love.graphics.print(string.format("gamma = %.2f", g), x, 104)
  love.graphics.setFont(fontes.p)
  love.graphics.setColor(1, 1, 1, 0.85)
  local linhas = {
    string.format("estrela de lado aparece a %.1f graus", math.deg(aberracao(math.pi / 2, b))),
    string.format("%.1f%% do ceu na metade da frente", 100 * (1 + b) / 2),
    "",
    string.format("frente: D = %.2f, sol a %.0f K, brilho x %.3g", Df, 5800 * Df, Df ^ 4),
    string.format("tras:   D = %.3f, sol a %.0f K, brilho x %.3g", Dt, 5800 * Dt, Dt ^ 4),
  }
  for i, l in ipairs(linhas) do love.graphics.print(l, x, 145 + (i - 1) * 20) end

  local function chave(i, nome, ligado)
    love.graphics.setColor(1, 1, 1, ligado and 0.9 or 0.35)
    love.graphics.print(string.format("[%d] %s: %s", i, nome, ligado and "ligado" or "desligado"), x, 290 + i * 20)
  end
  chave(1, "aberracao", aberr)
  chave(2, "cor (doppler)", cor)
  chave(3, "brilho (D^4)", brilho)

  love.graphics.setColor(0.4, 0.8, 1, 0.8)
  love.graphics.print("circulos azuis: 30, 60, 90... graus\nde quando a nave estava parada", x, 410)
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.print("centro = frente, borda = tras", x, 460)
  love.graphics.print("cima/baixo: acelera/freia   1 2 3: liga/desliga   r: para", 30, H - 28)
end

function love.draw()
  love.graphics.clear(0.02, 0.02, 0.04)
  local b = math.tanh(eta)
  love.graphics.setColor(0.06, 0.06, 0.1)
  love.graphics.circle("fill", CX, CY, RD)
  ceu(b)
  grade(b)
  painel(b)
end
