#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path_to_program>"
    exit 1
fi

# Ruta al binario (ajústala según corresponda)
BINARY="./obj_dir/Vtop"

# Ejecutar el binario con el argumento
GEN_TRACE=1 "$BINARY" "$1"
