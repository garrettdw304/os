@echo OFF
call make.bat
start X:\CodeProjects\compdes\compdes_gui\bin\Debug\net7.0-windows\compdes_gui.exe -rom -realtime
start plink.exe -serial COM95 -sercfg 9600,8,n,1,N