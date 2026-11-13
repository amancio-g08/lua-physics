-- 2fa.lua
-- codigo 2FA (TOTP) de quem viaja perto da velocidade da luz
-- uso: lua 2fa/2fa.lua

-- acha o totp.lua na mesma pasta deste arquivo
package.path = (arg[0]:gsub("[^/\\]+$", "")) .. "?.lua;" .. package.path
local codigo_2fa = require("totp").codigo


-- gamma = 1 / sqrt(1 - beta^2). o relogio do viajante marca t / gamma
local function gamma(beta)
  return 1 / math.sqrt(1 - beta^2)
end

local FOLGA = 1  -- janelas de atraso que o servidor aceita

local function atraso_em_janelas(t, g, inicio)
  local janela_terra = math.floor((inicio + t) / 30)
  local janela_viajante = math.floor((inicio + t / g) / 30)
  return janela_terra - janela_viajante
end

-- primeiro segundo (tempo da terra) em que o codigo eh recusado
local function tempo_ate_trancar(beta, inicio)
  local g = gamma(beta)
  local t = 0
  while atraso_em_janelas(t, g, inicio) <= FOLGA do
    t = t + 1
  end
  return t
end

local function legivel(s)
  if s < 120 then return string.format("%.0f s", s)
  elseif s < 7200 then return string.format("%.1f min", s / 60)
  elseif s < 172800 then return string.format("%.1f h", s / 3600)
  else return string.format("%.1f dias", s / 86400)
  end
end


-- 0) exemplo da RFC 6238: senha "12345678901234567890", t = 59 -> 287082
print("-- 0) teste com o exemplo oficial --")
print("esperado 287082, deu " .. codigo_2fa("12345678901234567890", 59))

-- 1) viajante a 0.8c. depois do primeiro RECUSADO ainda passa uma vez,
-- porque o celular dele acabou de virar de janela
local SENHA = "senha-secreta-do-viajante"
local INICIO = 1763000010   -- comeco de uma janela de 30 s
local BETA = 0.8
local g = gamma(BETA)

print(string.format("\n-- 1) viajante a beta %.1f (gamma %.3f) --", BETA, g))
print("terra   viajante   servidor  celular   resultado")
for t = 0, 150, 15 do
  local atraso = atraso_em_janelas(t, g, INICIO)
  local resultado
  if atraso == 0 then
    resultado = "aceito"
  elseif atraso <= FOLGA then
    resultado = "aceito (na folga)"
  else
    resultado = "RECUSADO"
  end
  print(string.format("%4d s  %6.1f s   %s    %s    %s",
    t, t / g, codigo_2fa(SENHA, INICIO + t), codigo_2fa(SENHA, INICIO + t / g), resultado))
end
print("trancado pra fora depois de " .. legivel(tempo_ate_trancar(BETA, INICIO)) .. " na terra")

-- 2) tempo ate trancar. kerberos aceita 5 min de diferenca: t = 300 / (1 - 1/gamma)
print("\n-- 2) tempo ate ser trancado (tempo da terra) --")
print("beta     gamma      2fa (folga 30 s)   kerberos (5 min)")
for _, b in ipairs({0.01, 0.1, 0.5, 0.8, 0.99}) do
  local gb = gamma(b)
  print(string.format("%-6.2f   %-8.5f   %-17s  %s",
    b, gb, legivel(tempo_ate_trancar(b, INICIO)), legivel(300 / (1 - 1 / gb))))
end

-- 3) GPS: a velocidade atrasa o relogio do satelite (beta^2 / 2),
-- a gravidade mais fraca adianta (GM/c^2 * (1/R_terra - 1/r_sat))
print("\n-- 3) GPS --")
local C = 299792458.0
local GM = 3.986004e14   -- terra
local R_TERRA = 6.371e6  -- m
local R_SAT = 2.6571e7   -- m (20200 km de altura)
local V_SAT = 3874       -- m/s
local DIA = 86400

local atraso = (V_SAT / C)^2 / 2 * DIA
local adianto = GM / C^2 * (1 / R_TERRA - 1 / R_SAT) * DIA
local total = adianto - atraso
print(string.format("velocidade:  -%.1f microssegundos por dia", atraso * 1e6))
print(string.format("gravidade:   +%.1f microssegundos por dia", adianto * 1e6))
print(string.format("total:       +%.1f microssegundos por dia", total * 1e6))
print(string.format("sem correcao: erro de %.1f km por dia", C * total / 1000))
