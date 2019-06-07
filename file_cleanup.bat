@echo off

CD C:\Users\%USERNAME%\AppData\Local\Temp
DEL * /Q
CD C:\Users\%USERNAME%\Downloads
DEL * /Q
ECHO.
ECHO.
ECHO.
ECHO All unused files have been deleted from the following directories:
ECHO 	-C:\Users\%USERNAME%\Downloads 
ECHO		-C:\Users\%USERNAME%\AppData\Local\Temp
ECHO.
dir|find "bytes free"
ECHO.
PAUSE
