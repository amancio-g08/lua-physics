# lua-physics

mini projetos de fisica em lua

## acelerador

foguete passando por aneis magneticos (solenoides), vendo quanto de beta ganha por anel com a correcao de lorentz. no final compara com estilingue gravitacional em jupiter.

```
lua acelerador/acelerador.lua
```

formulas:
- B = n * mu * I
- energia por anel = eta * B^2 / (2 * mu0) * volume
- gamma = 1 + k * E_anel / (m * c^2)
- beta = sqrt(1 - 1/gamma^2)
