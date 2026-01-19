#!/bin/bash

rm -rf assembled_tests
mkdir assembled_tests

cp riscv-tests/isa/rv32ui-p* assembled_tests
cp riscv-tests/isa/rv32um-p* assembled_tests
rm assembled_tests/*.dump
rm assembled_tests/*.commit
rm assembled_tests/*.kanata

rm -rf to_run
mkdir to_run

unsupported=( "fence_i" "jalr" "lb" "lbu" "lh" "lhu" "ma_data" "sb" "sh" "mulh" "mulhu" "mulhsu" "div" "divu" "rem" "remu" )

failed_tests=()  # array para guardar los fallidos

for test in assembled_tests/rv32u*-p-*;
do
    supported=1
    for unsup in "${unsupported[@]}";
    do
        if (echo $test | grep -Eq $unsup); then
            supported=0
        fi
    done

    if [ $supported -eq 1 ]; then
        tmp_file=$(mktemp)
        ./run_tartaruga.sh "$test" > "$tmp_file" 2> /dev/null

        if grep -q "Execution succeeded" "$tmp_file"; then
            echo "✅ test $test succeeded"
        else
            echo "❌ test $test failed"
            failed_tests+=("$test")
        fi

        rm -f "$tmp_file"
    fi
done

# Reporte final
total_failed=${#failed_tests[@]}
echo
echo "==============================="
echo "Total failed tests: $total_failed"
if [ "$total_failed" -gt 0 ]; then
    echo "Failed test list:"
    for f in "${failed_tests[@]}"; do
        if (echo $f | grep -Eq "lw"); then
            echo "  - $f (data segment unsupported when loading binaries on runtime)"
	    ((total_failed--))
        else
            echo "  - $f"
        fi
    done
fi
echo "==============================="

exit $total_failed
