rem disable commands on screen
@echo off
rem setting environment path variable
SET PATH=%PATH%;C:\Program Files (x86)\PuTTY
rem insert empty line in console
echo.
rem delete old files
DEL V7K_HC.txt
rem Defining a for loop for v7k arrays.
for /f %%i in (V7K_Arrays.txt) Do (
	rem saving a line to the file to make it understandable
	echo ---------------------------------------------------------------------------------------------------------------------------------------------- >> V7K_HC.txt
	rem saving storage ip variable to file to verify output later
	echo %%i >> V7K_HC.txt
	rem printing the array name for current iteration
	echo I am looping over %%i 
	rem adding a line below the ip for better readability
	echo ------------ >> V7K_HC.txt
	rem Defining a for loop for the set of commands to run per array
	for /f %%k in (V7K_Commands.txt) Do (
		rem saving command name to the output file to check later
		echo %%k >> V7K_HC.txt
		rem Displaying what command is being run on what storage array
		echo Running %%k on %%i
		rem Using plink to login to the storage array and run a command
		plink -ssh %%i -l root -pw cephadmin "%%k" >> V7K_HC.txt
		rem adding an empty line to the output.
		echo. >> V7K_HC.txt
	rem Inner for loop exits
	)
	rem adding a line to the output for better display
	echo ---------------------------------------------------------------------------------------------------------------------------------------------- >> V7K_HC.txt
rem Outer for loop exits
)
rem User prompt to close the console
SET /p exit=Press enter to exit the prompt..
