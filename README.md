# Tartaruga core

Subset muy subsetero de RV32I

## Instrucciones soportadas

### Aritmetico-logicas

- ADD
- SUB
- SLL
- SRL
- SRA
- AND
- OR
- XOR
- SLT
- SLTU
- ADDI
- SLLI
- SRLI
- SRAI
- ANDI
- ORI
- XORI
- SLTI
- SLTIU
- AUIPC
- LUI

### Flow control

- JAL
- BEQ
- BNE
- BLT
- BGE
- BLTU
- BGEU

### Memory

- LW
- SW

## Tratamiento de instruccion ilegal

Por ahora sera una NOP

## Ejecutar cosas

### Compilar el core

```
make all
```


### Ejecutar binarios

```
python3 prepare_program.py test.S

./run_tartaruga.sh (fichero).program # el generado por el script de python
```

## Cosas pendientes de hacer

### Simulator

- Generar dumps de texto con el desensamblado de las instrucciones

### Verificacion

- Testbenches de modulos
- Entorno de testing del core

## Assembler

```
riscv64-unknown-elf-as -march=rv32i
```

## Instructions information

[https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html#sw](https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html#sw)

