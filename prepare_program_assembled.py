import re
import sys
import os
import subprocess

if len(sys.argv) != 3:
    print(f"Uso: {sys.argv[0]} <fichero_asm_riscv.S> <directorio de destino>")
    sys.exit(1)

input_file = sys.argv[1]
base_name = os.path.splitext(os.path.basename(input_file))[0]
elf_file = input_file
output_file = f"{sys.argv[2]}/{base_name}.program"

# Expresión regular para capturar la instrucción en hexadecimal
hex_pattern = re.compile(r'^\s*[0-9a-f]+:\s*([0-9a-f]{8})', re.IGNORECASE)

# Ejecutar objdump para generar el disassembly
try:
    result = subprocess.run(
        ["riscv64-unknown-elf-objdump", "-d", elf_file],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
        text=True
    )
except subprocess.CalledProcessError as e:
    print(f"❌ Error ejecutando objdump: {e.stderr}")
    sys.exit(1)

# Extraer las instrucciones en hexadecimal y guardarlas en .program
with open(output_file, "w") as f_out:
    for line in result.stdout.splitlines():
        match = hex_pattern.match(line)
        if match:
            hex_inst = match.group(1)
            f_out.write(hex_inst + "\n")

print(f"✅ Instrucciones en hexadecimal escritas en {output_file}")

# (Opcional) Eliminar ficheros intermedios
# os.remove(obj_file)
os.remove(elf_file)

