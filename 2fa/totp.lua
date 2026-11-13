-- totp.lua
-- codigo 2FA de 6 digitos (TOTP, RFC 6238): HMAC-SHA1(senha, floor(t / 30))
-- funciona no lua 5.4 e no luajit (love2d)

local M32 = 4294967296  -- 2^32
local band, bor, bxor, shl, shr

if bit then  -- luajit
  band, bor, bxor, shl, shr = bit.band, bit.bor, bit.bxor, bit.lshift, bit.rshift
else         -- lua 5.3+ (operadores carregados por texto pra o luajit nao reclamar)
  band, bor, bxor, shl, shr = load([[
    return function(a, b) return a & b end, function(a, b) return a | b end,
           function(a, b) return a ~ b end, function(a, n) return a << n end,
           function(a, n) return a >> n end
  ]])()
end

local function u(x) return x % M32 end            -- volta pra 0 .. 2^32-1
local function bnot(x) return M32 - 1 - x end
local function gira(x, n) return u(shl(x, n)) + u(shr(x, 32 - n)) end

local function u32(x)  -- 4 bytes big endian
  return string.char(math.floor(x / 16777216) % 256, math.floor(x / 65536) % 256,
                     math.floor(x / 256) % 256, x % 256)
end

local function le32(s, i)
  local a, b, c, d = s:byte(i, i + 3)
  return ((a * 256 + b) * 256 + c) * 256 + d
end

local function sha1(msg)
  local h = { 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0 }
  local bits = #msg * 8
  msg = msg .. "\128" .. string.rep("\0", (55 - #msg) % 64)
      .. u32(math.floor(bits / M32)) .. u32(bits % M32)

  for bloco = 1, #msg, 64 do
    local w = {}
    for i = 0, 15 do w[i] = le32(msg, bloco + i * 4) end
    for i = 16, 79 do
      w[i] = gira(u(bxor(bxor(w[i - 3], w[i - 8]), bxor(w[i - 14], w[i - 16]))), 1)
    end

    local a, b, c, d, e = h[1], h[2], h[3], h[4], h[5]
    for i = 0, 79 do
      local f, k
      if i < 20 then
        f, k = bor(band(b, c), band(bnot(b), d)), 0x5A827999
      elseif i < 40 then
        f, k = bxor(bxor(b, c), d), 0x6ED9EBA1
      elseif i < 60 then
        f, k = bor(bor(band(b, c), band(b, d)), band(c, d)), 0x8F1BBCDC
      else
        f, k = bxor(bxor(b, c), d), 0xCA62C1D6
      end
      local temp = u(gira(a, 5) + u(f) + e + k + w[i])
      e, d, c, b, a = d, c, gira(b, 30), a, temp
    end

    h[1], h[2], h[3] = u(h[1] + a), u(h[2] + b), u(h[3] + c)
    h[4], h[5] = u(h[4] + d), u(h[5] + e)
  end
  return u32(h[1]) .. u32(h[2]) .. u32(h[3]) .. u32(h[4]) .. u32(h[5])
end

local function xor_bytes(s, x)
  return (s:gsub(".", function(ch) return string.char(u(bxor(ch:byte(), x))) end))
end

local function hmac_sha1(senha, msg)
  if #senha > 64 then senha = sha1(senha) end
  senha = senha .. string.rep("\0", 64 - #senha)
  return sha1(xor_bytes(senha, 0x5c) .. sha1(xor_bytes(senha, 0x36) .. msg))
end

-- codigo de 6 digitos pro horario t (segundos)
local function codigo(senha, t)
  local janela = math.floor(t / 30)
  local h = hmac_sha1(senha, u32(math.floor(janela / M32)) .. u32(janela % M32))
  local pos = h:byte(20) % 16
  local numero = le32(h, pos + 1) % 2147483648
  return string.format("%06d", numero % 1000000)
end

return { codigo = codigo }
