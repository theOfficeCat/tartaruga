#!/bin/bash

rm -rf assembled_tests
mkdir assembled_tests

cp riscv-tests/isa/rv32ui-p* assembled_tests
rm assembled_tests/*.dump

rm -rf to_run
mkdir to_run

for test in assembled_tests/rv32ui-p-*;
do
    python3 prepare_program_assembled.py $test to_run/
done

TESTS=$(ls to_run | wc -l)

echo $TESTS

for test in to_run/*;
do
    ./run_tartaruga.sh $test > tmp_file 2> /dev/null

    if grep -q "Execution suceeded" tmp_file; then
        ((TESTS--))
        echo test $test suceeded
    else
        echo test $test failed
    fi
done

echo total failed tests: $TESTS
