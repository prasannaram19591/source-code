import paramiko, os, os.path
from datetime import datetime
import time

if os.path.isfile('esxi_log.csv'):
    os.remove("esxi_log.csv")

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('10.x.x.x',port=22, username='username', password='password')

try:
    stdin, stdout, stderr = ssh.exec_command('vim-cmd vmsvc/getallvms')
    opt = stdout.readlines()
    opt ="".join(opt)
    with open('esxi_log.csv', 'a') as output:
        output.write(opt + '\n')
        output.close()
    with open('esxi_log.csv', 'r') as vms:
        for vm in vms:
            if not 'Vmid' in vm:
                str_to_list = vm.split(" ")
                vm_id = str_to_list[0]
                vm_id_n = vm_id.rstrip('\n')
                now = datetime.now()
                dt = now.strftime("%d-%m-%Y_%H-%M-%S")
                print ('Creating snapshot for the vm id ' + vm_id_n + ' with the command vim-cmd vmsvc/snapshot.create ' + vm_id_n + ' snap_' + dt)
                stdin, stdout, stderr = ssh.exec_command('vim-cmd vmsvc/snapshot.create ' + vm_id_n + ' snap_' + dt + ' snap_description')
                opt = stdout.readlines()
                opt ="".join(opt)
                with open('esxi_snap_log.csv', 'w') as output:
                    output.write(opt + '\n')
                    output.close()
                time.sleep(1)
except:
    pass

finally:
    ssh.close()
