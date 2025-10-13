# Tartaruga core

Subset muy subsetero de RV32I

## Instrucciones minimas

- ADD ```rd <- ra + rb```
- LW ```rd <- dmem[rb + offset]```
- SW ```dmem[rb + offset] <- ra```
- BEQ ```pc <- pc + offset``` if taken
- BGT ```pc <- pc + offset``` if taken
- BGE ```pc <- pc + offset``` if taken
- JMP ```pc <- pc + offset``` sera simplemente un ```JAL``` a ```x0```
- LI ```rd <- sign_ext(imm)```

## Tratamiento de instruccion ilegal

Salto a posicion de memoria 3090 (0xC12). Por ahora sera una NOP

## Cosas pendientes de hacer

### RTL

- Creacion de inmediatos
- ALU
- Logica de control de entradas a la ALU
- Acabar el decoder
- Interfz de memoria de datos
- Writeback

### Simulator

- Poder cargar binarios
- Generar dumps de texto

### Verificacion

- Testbenches de modulos
- Entorno de testing del core

## Assembler

[https://riscvasm.lucasteske.dev/#](https://riscvasm.lucasteske.dev/#)

## Instructions information

[https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html#sw](https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html#sw)

