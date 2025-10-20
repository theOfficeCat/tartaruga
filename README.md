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

## Ejecutar cosas

### Compilar el core

```
make all
```


### Ejecutar binarios

```
riscv64-unknown-elf-as -march=rv32i test.s

(en el directorio base)

python3 prepare_program.py (elf generado)

./run_tartaruga.sh (fichero).program # el generado por el script de python
```

## Cosas pendientes de hacer

### Simulator

- Generar dumps de texto

### Verificacion

- Testbenches de modulos
- Entorno de testing del core

## Assembler

[https://riscvasm.lucasteske.dev/#](https://riscvasm.lucasteske.dev/#)

## Instructions information

[https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html#sw](https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html#sw)

