# An operating system used to test my W65C02 emulator.

## To Build

1. Download the 6502 assembler from http://sun.hasenbraten.de/vasm/index.php?view=binrel

The assembler to download from the page is "vasm6502_oldstyle_Win64.zip".

2. Extract the zip contents somewhere and optionally add the directory to the PATH environment variable (make.bat script expects it to be in PATH).

3. From the project directory do one of the following:

3A. Run 'mkdir bin' and then 'PATH_TO_VASM6502_OLDSTYLE.EXE -L bin/listingfile.txt -Lall -Fbin -dotdir -wdc02 -o bin/rom.bin src/kernel/main.s' with PATH_TO_VASM6502_OLDSTYLE.EXE replaced with the path to the exe that was extracted from the zip file.

3B. Run the make.bat script by typing './make' in the terminal.

A listingfile.txt and a rom.bin file should now be in the bin directory.
