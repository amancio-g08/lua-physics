# lua-physics

mini projetos de fisica em lua, um pra cada duvida que tive vendo esse video:
https://www.youtube.com/watch?v=ErMSHiQRnc8

cada pasta tem um arquivo `.lua` com tudo comentado, feito pra dar pra entender
mesmo sem saber programar.

## como rodar

1. instala o lua (https://www.lua.org/download.html, ou no windows `winget install DEVCOM.Lua`)
2. abre o terminal na pasta `lua-physics`
3. roda o projeto que quiser, ex: `lua doppler/doppler.lua`

## projetos

### acelerador

foguete passando por aneis magneticos (solenoides), vendo quanto de beta
(velocidade / velocidade da luz) ele ganha por anel, com a correcao de lorentz.
compara com a conta de newton (que passa da velocidade da luz, o que nao pode)
e no final com o estilingue gravitacional em jupiter.

```
lua acelerador/acelerador.lua
```

formulas:
- campo no solenoide: B = n * mu * I
- energia por anel: eta * B^2 / (2 * mu0) * volume
- fator de lorentz: gamma = 1 + k * E_anel / (m * c^2)
- velocidade: beta = sqrt(1 - 1/gamma^2)

o que sai:
- a 5% de mc^2 por anel, chega em beta 0.8 no anel 14. o relogio do foguete anda
  a 60% do nosso (passam 30 s aqui, 18 s la)
- um solenoide de verdade (1,26 T, ~3 kJ por anel) precisaria de ~2 x 10^16 aneis pra isso
- 20 sobrevoos em jupiter nao chegam nem perto

### doppler

a cor da luz muda quando voce anda muito rapido ou cai num buraco negro.
a luz de partida eh a H-alfa (656 nm), a linha vermelha do hidrogenio.

```
lua doppler/doppler.lua
```

formulas (beta > 0 = indo na direcao da luz, beta < 0 = fugindo dela):
- doppler relativistico: lambda_visto = lambda * sqrt((1 - beta) / (1 + beta))
- redshift gravitacional: lambda_longe = lambda / sqrt(1 - rs/r)

o que sai:
1. **nave e luz vermelha**: indo na direcao dela a beta 0.3 o vermelho vira azul
   (482 nm). fugindo, vira infravermelho. a 0.8 de frente ja eh ultravioleta
2. **caindo no buraco negro, olhando pra tras**: a gravidade deixa a luz das
   estrelas mais azul, mas voce ta fugindo dela e o doppler ganha. a conta vira
   lambda * (1 + beta). perto do horizonte a luz chega com o dobro do comprimento
3. **disco de acrecao** (gas a 3 raios do buraco girando a c/2): o lado que vem
   pra ca chega azul (464 nm), o que vai embora chega infravermelho (1392 nm)
4. **jato relativistico**: a 0.99c o jato que vem pra ca vira ultravioleta e o
   contra-jato vai pra quase 10 mil nm

obs: quem muda a cor eh o doppler + a dilatacao do tempo, nao a contracao do
espaco. e perto do buraco negro entra um segundo efeito separado, o redshift
gravitacional (a luz perde energia pra "subir" da gravidade).
