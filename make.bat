@echo OFF
call mkdir bin
call vasm6502_oldstyle -L bin/lf.txt -Lall -Fbin -dotdir -wdc02 -o bin/rom.bin src/kernel/main.s