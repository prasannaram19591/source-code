@echo off
setlocal enabledelayedexpansion
color 0B
SET PATH=%PATH%;C:\Program Files (x86)\PuTTY
echo.
DEL V7K_HC.txt
for /f %%i in (V7K_Arrays.txt) Do (
	echo ---------------------------------------------------------------------------------------------------------------------------------------------- >> V7K_HC.txt
	echo %%i >> V7K_HC.txt
	echo ------------ >> V7K_HC.txt
	for /f %%k in (V7K_Commands.txt) Do (
		echo %%k >> V7K_HC.txt
		plink -ssh %%i -l user_name -pw Password "%%k" >> V7K_HC.txt
		echo. >> V7K_HC.txt
	)
	echo ---------------------------------------------------------------------------------------------------------------------------------------------- >> V7K_HC.txt
)
SET /p exit=Press enter to exit the prompt..
