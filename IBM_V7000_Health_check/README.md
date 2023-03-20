# IBM_V7000_Health_check

Hello Storage Admins,

How many times we had been told to automate daily health checks of the storae infra that we manage by many people. In a work area with more than 100 storage devices, it will become a tedious task to login to each storage device and perform the same set of commands and verifying the output. More than the wastage of time it involes manual errors as well. I have got you covered for all your day to day health checks for storage devices that you manage.

How it works:

The automation is done using Python code. The code performs a SSH into all of the defined storage boxes and performs all the commands that we want to. It saves the output of all the commands that it ran across all the storage device and mails the same to the admins so that all we need to do is to check the output file and look at the storage that only have errros in the output.

1.  Create a common user(monitoring user) and password for all storage arrays of same model for ex: IBM V7000.
2.  Create an environment file and input a common user name and password which is created for all the storage and source it (source ibm_env.sh).
3.  Create a file and input all the ips of the storage that you want to perform HC.
4.  Creata a file and input all the HC commands that you want to have a daily look.
5.  Run the file ("python ibm_health_check.py") daily to get the output of all device commands at one go to your mail.


Pre-requisites:
1.  SSH connectivity to the storage box to run remote commands.
2.  A Linux VM with storage network connectivity.
3.  Python 2.7 and above installed on the vm.
4.  Python Paramiko and MIME modules installed for SSH and mailing capabilities.
5.  The VM should be able to send mails through SMTP.
6.  Optionally Jenkins to schedule.
