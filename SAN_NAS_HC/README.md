# SAN_NAS_HC

Dear Storage Admins,

Please have a look at my work to automate your daily health checks on SAN storage, NAS storage and SAN Switches in your infra without even logging into each of the device and run the same set of commands everyday. The code is a simple windows batch script which will log in to all the defined storage ips and performs a set of commands on all devices and records the output in a windows drive so that all you need to do is to check the file for any errors and take action on the storage which is reporting errors on the heclth check log. This saves a lot of manual efforts and eliminates human errors. This automation needs almost nothing to set up as you can just save the file and run it from a windows machine.

Pre-requisites.

1.  Full installation of PuTTy on a windows machine with plink and pscp included in the package.
2.  Copy the code and modify the path of the PuTTy to the install path in your windows machine.
3.  Input one common storage array (EX : IBM V7000) in the file V7K_Arrays.txt, one ip per line and save it the same folder.
4.  Input all the commands that you need to perform on an array in the file V7K_Commands.txt one command per line and save it in the same folder.
5.  Just double click the .bat file and wait for some time, a command prompt opens up and performs the health checks.
6.  Once its completed you will see a file with the name V7K_HC.txt in the same folder. 
7.  Everyday you can just run the batch file and verify the output. No need to login to all the storage.
8.  Optionally configure the batch file in Windows task scheduler to run at your specific schedules so that you dont even need to start the script manually.
9.  You can just verify the HC file everyday if the task is scheduled in task scheduler.
10. Just create a common user with only monitor permissions on all the storage devices and use the credentials for performing daily HC.
