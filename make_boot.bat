@echo OFF
call mkdir bin/boot
call vasm6502_oldstyle -L bin/boot/bootlf.txt -Lall -Fbin -dotdir -wdc02 -o bin/boot/bootrom.bin src/boot/boot.s