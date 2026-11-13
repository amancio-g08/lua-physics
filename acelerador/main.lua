-- main.lua
-- animacao do estilingue gravitacional (love2d)
-- uso: love acelerador
--
-- a conta eh feita no referencial do planeta (planeta parado na tela):
-- a nave chega com u = vi + U, a gravidade curva o caminho e, longe do
-- planeta, ela sai com o mesmo |u|. somando de volta a velocidade do
-- planeta (-U), no referencial do sol ela sai mais rapida.

local W, H = 1100, 700
local PX, PY, R = 640, 330, 70   -- planeta (px)
local U = 10000                  -- velocidade do planeta (m/s), indo pra esquerda
local U_PX = 160                 -- velocidade de chegada u na tela (px/s)
local GM = 3.8e7                 -- gravidade do planeta (px^3/s^2)
local LONGE = 100000             -- de onde a nave vem (px)

local vi = 150      -- velocidade da nave no referencial do sol (m/s), indo pra direita
local b = 540       -- parametro de impacto: distancia da reta de chegada ate o planeta (px)
local ritmo = 0.25
local pausado = false
local K             -- m/s por px/s
local nave, rastro, final, bateu
local fontes = {}
local estrelas = {}

-- um passo de gravidade (h em segundos). devolve false se bateu
local function passo(h)
  local dx, dy = nave.x - PX, nave.y - PY
  local r2 = dx * dx + dy * dy
  local r = math.sqrt(r2)
  if r < R then return false end
  local a = GM / (r2 * r)        -- a = GM / r^2, apontando pro planeta
  nave.vx = nave.vx - a * dx * h
  nave.vy = nave.vy - a * dy * h
  nave.x = nave.x + nave.vx * h
  nave.y = nave.y + nave.vy * h
  return true
end

local function na_tela(m)
  return nave.x > -m and nave.x < W + m and nave.y > -m and nave.y < H + m
end

local function reinicia()
  K = (vi + U) / U_PX
  -- mesmo la longe ainda tem um pouco de gravidade: compensa pra chegar com u = U_PX
  nave = { x = PX - LONGE, y = PY + b, vx = math.sqrt(U_PX ^ 2 + 2 * GM / LONGE), vy = 0 }
  -- faz a viagem de longe ate a tela sem desenhar
  while not na_tela(30) do passo(0.02) end
  rastro = { { nave.x, nave.y } }
  final, bateu = nil, false
end

-- velocidade agora, no referencial do sol (m/s)
local function v_sol()
  local vx, vy = nave.vx * K - U, nave.vy * K
  return math.sqrt(vx * vx + vy * vy)
end

-- velocidade quando estiver bem longe do planeta (pela orbita hiperbolica):
-- |u| volta ao valor de chegada e aponta pra assintota de saida
local function v_sol_longe()
  local rx, ry = nave.x - PX, nave.y - PY
  local vx, vy = nave.vx, nave.vy
  local r = math.sqrt(rx * rx + ry * ry)
  local v2 = vx * vx + vy * vy
  local u = math.sqrt(v2 - 2 * GM / r)
  local rv = rx * vx + ry * vy
  local ex = ((v2 - GM / r) * rx - rv * vx) / GM   -- vetor excentricidade
  local ey = ((v2 - GM / r) * ry - rv * vy) / GM
  local e = math.sqrt(ex * ex + ey * ey)
  local giro = (rx * vy - ry * vx) > 0 and 1 or -1
  local ang = math.atan2(ey, ex) + giro * math.acos(-1 / e)
  local sx, sy = u * math.cos(ang) * K - U, u * math.sin(ang) * K
  return math.sqrt(sx * sx + sy * sy)
end

function love.load()
  love.window.setTitle("estilingue gravitacional")
  love.window.setMode(W, H, { stencil = true })
  fontes.p = love.graphics.newFont(14)
  fontes.m = love.graphics.newFont(18)
  fontes.g = love.graphics.newFont(26)
  for i = 1, 220 do
    estrelas[i] = { math.random() * W, math.random() * H, math.random() }
  end
  reinicia()
end

function love.keypressed(k)
  if k == "up" then b = math.max(b - 20, 300)
  elseif k == "down" then b = math.min(b + 20, 1200)
  elseif k == "right" then vi = math.min(vi + 150, 6000)
  elseif k == "left" then vi = math.max(vi - 150, 0)
  elseif k == "=" or k == "kp+" then ritmo = math.min(ritmo * 2, 4) return
  elseif k == "-" or k == "kp-" then ritmo = math.max(ritmo / 2, 0.0625) return
  elseif k == "space" then pausado = not pausado return
  elseif k == "escape" then love.event.quit() return
  elseif k ~= "r" then return
  end
  reinicia()
end

function love.update(dt)
  if pausado or final or bateu then return end
  local n = 60
  for _ = 1, n do
    if not passo(dt * ritmo / n) then bateu = true return end
  end
  local ult = rastro[#rastro]
  if (nave.x - ult[1]) ^ 2 + (nave.y - ult[2]) ^ 2 > 16 then
    rastro[#rastro + 1] = { nave.x, nave.y }
  end
  if not na_tela(40) then final = v_sol_longe() end
end

local function planeta()
  love.graphics.stencil(function() love.graphics.circle("fill", PX, PY, R) end, "replace", 1)
  love.graphics.setStencilTest("greater", 0)
  love.graphics.setColor(0.78, 0.62, 0.45)
  love.graphics.circle("fill", PX, PY, R)
  local faixas = { { -50, 10 }, { -28, 7 }, { -6, 13 }, { 20, 8 }, { 40, 12 } }
  for i, f in ipairs(faixas) do
    local c = (i % 2 == 0) and { 0.62, 0.45, 0.32 } or { 0.88, 0.76, 0.6 }
    love.graphics.setColor(c)
    love.graphics.rectangle("fill", PX - R, PY + f[1], 2 * R, f[2])
  end
  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.circle("fill", PX + 40, PY - 8, R)
  love.graphics.setStencilTest()
end

local function seta(x1, y1, x2, y2)
  love.graphics.line(x1, y1, x2, y2)
  local ang = math.atan2(y2 - y1, x2 - x1)
  love.graphics.polygon("fill", x2, y2,
    x2 - 10 * math.cos(ang - 0.4), y2 - 10 * math.sin(ang - 0.4),
    x2 - 10 * math.cos(ang + 0.4), y2 - 10 * math.sin(ang + 0.4))
end

local function desenha_nave()
  love.graphics.push()
  love.graphics.translate(nave.x, nave.y)
  love.graphics.rotate(math.atan2(nave.vy, nave.vx))
  love.graphics.setColor(1, 0.6, 0.1)
  love.graphics.polygon("fill", -10, -3, -16 - math.random() * 6, 0, -10, 3)
  love.graphics.setColor(0.9, 0.9, 0.95)
  love.graphics.polygon("fill", 12, 0, -10, -6, -10, 6)
  love.graphics.pop()
end

local function texto(txt, x, y, cor)
  love.graphics.setColor(cor or { 1, 1, 1 })
  love.graphics.print(txt, x, y)
end

function love.draw()
  love.graphics.clear(0.01, 0.01, 0.03)
  for _, e in ipairs(estrelas) do
    love.graphics.setColor(1, 1, 1, 0.2 + 0.6 * e[3])
    love.graphics.points(e[1], e[2])
  end

  planeta()
  love.graphics.setColor(1, 1, 1, 0.6)
  seta(PX - 10, PY - R - 25, PX - 100, PY - R - 25)
  love.graphics.setFont(fontes.m)
  love.graphics.print("U", PX - 62, PY - R - 52)

  if #rastro > 1 then
    local pts = {}
    for _, p in ipairs(rastro) do pts[#pts + 1] = p[1]; pts[#pts + 1] = p[2] end
    pts[#pts + 1] = nave.x; pts[#pts + 1] = nave.y
    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(pts)
    love.graphics.setLineWidth(1)
  end
  if not bateu then desenha_nave() end

  -- painel
  love.graphics.setColor(0.07, 0.07, 0.1, 0.92)
  love.graphics.rectangle("fill", 30, 30, 430, 215, 8)
  love.graphics.setFont(fontes.g)
  texto(string.format("U  = %d m/s", U), 50, 45)
  texto(string.format("vi = %d m/s", vi), 50, 80)
  if final then
    texto(string.format("vf = %.0f m/s", final), 50, 115, { 0.4, 1, 0.5 })
  else
    texto(string.format("v agora = %.0f m/s", v_sol()), 50, 115)
  end
  love.graphics.setFont(fontes.p)
  texto(string.format("maximo (volta completa): vi + 2U = %d m/s", vi + 2 * U), 50, 160, { 1, 1, 1, 0.7 })
  texto(string.format("visto pelo planeta: chega e sai a %d m/s", vi + U), 50, 180, { 1, 1, 1, 0.7 })
  if bateu then
    texto("bateu no planeta! passa mais longe (seta pra baixo)", 50, 205, { 1, 0.35, 0.35 })
  elseif final then
    texto(string.format("ganhou %.0f m/s", final - vi), 50, 205, { 0.4, 1, 0.5 })
  else
    texto("perto do planeta a gravidade acelera a nave", 50, 205, { 1, 1, 1, 0.5 })
  end

  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.printf("cima/baixo: passa mais perto/longe   esquerda/direita: vi\n+/-: ritmo   espaco: pausa   r: reinicia",
    470, 650, 600, "right")
end
