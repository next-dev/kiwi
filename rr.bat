@echo off
call m.bat
if not errorlevel 1 (
    bin\hdfmonkey put \sdcard\cspect-next-2gb.img kiwi.nex
    bin\CSpect.exe -r -s14 -w3 -zxnext -nextrom -map=kiwi.map -mmc=\sdcard\cspect-next-2gb.img
)