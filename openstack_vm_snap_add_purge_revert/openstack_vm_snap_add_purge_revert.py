from openstack import connection
import re, os, os.path
import rados, sys, rbd, time
from datetime import datetime as dt
from datetime import date
import datetime as dnt

#Openstack api connection..
def auth_args():
    d = {}
    d['username'] = os.environ['OS_USERNAME']
    d['password'] = os.environ['OS_PASSWORD']
    d['auth_url'] = os.environ['OS_AUTH_URL']
    d['project_name'] = os.environ['OS_TENANT_NAME']
    d['project_domain_id'] = os.environ['OS_PROJECT_DOMAIN_ID']
    d['user_domain_id'] = os.environ['OS_PROJECT_DOMAIN_ID']
    return d

conn=connection.Connection(**auth_args())

#Ceph api connection..
try:
        cluster = rados.Rados(conffile='')
except TypeError as e:
        print 'Argument validation error: ', e
        raise e

try:
        cluster.connect()
except Exception as e:
        print "connection error: ", e
        raise e

#Generating ceph pool list..
pools = cluster.list_pools()

#Getting openstack instance list..
instances_list = conn.compute.servers()

#Function for finding specified snap name for a disk id..
def ceph_pool(disk_id, snap_num):
  for pool in pools:
    ioctx = cluster.open_ioctx(pool)
    rbd_obj = rbd.RBD()
    pool_rbd = rbd_obj.list(ioctx)
    for obj in pool_rbd:
      if disk_id in obj:
        ins_img = rbd.Image(ioctx, obj)
        snaps = ins_img.list_snaps()
        for iteration, snap in enumerate(snaps):
          iter1 = iteration + 1
          if int(iter1) == int(snap_num):
            snap_name = snap.get('name')
            option.restore(disk_id, snap_name)

#Prompting instance input from the user..
instance_name = raw_input("Enter an instance name : ")

#Displaying the root drive and additional drives and its snaps..
for vm in instances_list:
  ins_name = vm.name
  if instance_name == ins_name:
    ins_state = vm.status
    ins_id = vm.id
    with open('/root/ceph-opsk-python/bkp-res-ins-and-vol-ids.csv', 'w') as output:
      output.write(ins_id + '\n')
    ins_vols = vm.attached_volumes
    for k in ins_vols:
      j = str(k).split("u'id': u")
      l = str(j).replace("['{',", '').replace("'}", '').replace('"',  '').replace(']',  '').replace("'",  '').replace(" ", '')
      with open('/root/ceph-opsk-python/bkp-res-ins-and-vol-ids.csv', 'a') as output:
        output.write(l + '\n')
    with open('/root/ceph-opsk-python/bkp-res-ins-and-vol-ids.csv', 'r') as ids:
      for k in ids:
        disk_id = str(k).replace('\n', '')
        for pool in pools:
          ioctx = cluster.open_ioctx(pool)
          rbd_obj = rbd.RBD()
          pool_rbd = rbd_obj.list(ioctx)
          for obj in pool_rbd:
            if disk_id in obj:
              ins_img = rbd.Image(ioctx, obj)
              snaps = ins_img.list_snaps()
              print('\n')
              print "-----------------Disk_image-----------------"
              print obj
              print "--------------------------------------------"
              print "-----------------Image_snaps-----------------"
              for snap in snaps:
                print snap.get('name')
              print "---------------------------------------------"

#Function to perform a restore..
def restore_query():
  disk_id = raw_input("select an id from the above to perform restore on the disk : ")
  snap_name = raw_input("select a snap from the above to perform restore on the disk : ")
  option.restore(disk_id, snap_name)
  print "Powering on the server"
  start_server()

#Function to start a server..
def start_server():
  start_cmd = ("nova start " + instance_name)
  os.system(start_cmd)

#Function to stop a server..
def stop_server():
  stop_cmd = ("nova stop " + instance_name)
  os.system(stop_cmd)

#Class for all openstack disk related operations..
class openstack_disk:

  #Method for backup of disk ids for a given instance..
  def backup(self, disk_id):
    for pool in pools:
      ioctx = cluster.open_ioctx(pool)
      rbd_obj = rbd.RBD()
      pool_rbd = rbd_obj.list(ioctx)
      for obj in pool_rbd:
        if disk_id in obj:
          ins_img = rbd.Image(ioctx, obj)
          now = dt.now()
          tstmp = now.strftime("%a-%Y-%b-%d-%H_%M_%S")
          snap_name = instance_name + '_' + 'snap-' + tstmp
          try:
            ins_img.create_snap(snap_name)
            print ("Successfully created the disk " + obj + " snapshot " + snap_name + " for the instance " + instance_name + "." )
          except: 
            print ("Error occured while creating the disk " + obj + " snapshot " + snap_name + " for the instance " + instance_name + "." )

  #Method for restore of disk ids for a given instance..
  def restore(self,disk_id,snap_name):
    for pool in pools:
      ioctx = cluster.open_ioctx(pool)
      rbd_obj = rbd.RBD()
      pool_rbd = rbd_obj.list(ioctx)
      for obj in pool_rbd:
        if disk_id in obj:
          ins_img = rbd.Image(ioctx, obj)
          try:
            ins_img.rollback_to_snap(snap_name)
            print ("Successfully restored the disk " + obj + " snapshot " + snap_name + " for the instance " + instance_name + "." )
          except:
            print ("Error occured while restoring the disk " + obj + " to its snapshot " + snap_name + " for the instance " + instance_name + "." )
 
  #Method for deleting all snaps of all disk ids for a given instance..
  def purge(self, disk_id):
    for pool in pools:
      ioctx = cluster.open_ioctx(pool)
      rbd_obj = rbd.RBD()
      pool_rbd = rbd_obj.list(ioctx)
      for obj in pool_rbd:
        if disk_id in obj:
          ins_img = rbd.Image(ioctx, obj)
          snaps = ins_img.list_snaps()
          for snap in snaps:
            try:
              ins_img.remove_snap(snap.get('name'))
              print ("Successfully deleted the disk " + obj + " snapshot " + snap.get('name') + " for the instance " + instance_name + "." )
            except:
              print ("Error occured while deleting the disk " + obj + " snapshot " + snap.get('name') + " for the instance " + instance_name + "." )

option = openstack_disk()

#Display choices..
x = '0'
while x == '0':
  print('\n')
  print('Select any one from the below choices..')
  print('1:Backup create')
  print('2:Disk restore')
  print('3:Full restore')
  print('4:Backup purge')
  print('\n')
  instance_choice = raw_input("select an option to perform on the instance : ")
  if instance_choice == '1':
    x = '1'
  if instance_choice == '2':
    x = '2'
  if instance_choice == '3':
    x = '3'
  if instance_choice == '4':
    x = '4'
  if not '1' in instance_choice:
    if not '2' in instance_choice:
      if not '3' in instance_choice:
        if not '4' in instance_choice:
          print('Invalid choice.. Select one from the below...')

#Condition to check for backup operation and call backup object of openstack_disk class..
if instance_choice == '1':
  with open('/root/ceph-opsk-python/bkp-res-ins-and-vol-ids.csv', 'r') as ids:
    for k in ids:
      disk_id = str(k).replace('\n', '')
      option.backup(disk_id)

#Condition to check for disk restore operation and call restore object of openstack_disk class..
if instance_choice == '2':
  if str(ins_state) == 'ACTIVE':
    shut_vm = 'n'
    while shut_vm != 'y':
      shut_vm = raw_input("The instance " + instance_name + " is in " + ins_state + ". It has to be powered off to perform restore. Press y to proceed.. ")
      if shut_vm != 'y':
        print('Invalid input received.. Press y to proceed..')
    stop_server()

  else:
    print "Please allow sometime to check if the vm is powered off.."
    instances_list = conn.compute.servers()
    for vm in instances_list:
      ins_name = vm.name
      if instance_name == ins_name:
        ins_state = vm.status
        while ins_state != 'SHUTOFF':
          print('Please wait for sometime to let the shutdown complete..')
          instances_list = conn.compute.servers()
          for vm in instances_list:
            ins_name = vm.name
            if instance_name == ins_name:
              time.sleep(4)
              ins_state = vm.status
        restore_query()
      break
         
  instances_list = conn.compute.servers()
  for vm in instances_list:
    ins_name = vm.name
    if instance_name == ins_name:
      ins_state = vm.status
      while ins_state != 'SHUTOFF':
        print('Please wait for sometime to let the shutdown complete..')
        instances_list = conn.compute.servers()
        for vm in instances_list:
          ins_name = vm.name
          if instance_name == ins_name:
            time.sleep(4)
            ins_state = vm.status
      restore_query() 

#Condition to check for full disk restore operation and call restore object of openstack_disk class..
if instance_choice == '3':
  if str(ins_state) == 'ACTIVE':
    shut_vm = 'n'
    while shut_vm != 'y':
      shut_vm = raw_input("The instance " + instance_name + " is in " + ins_state + ". It has to be powered off to perform restore. Press y to proceed.. ")
      if shut_vm != 'y':
        print('Invalid input received.. Press y to proceed..')
    stop_server()

  else:
    print "Please allow sometime to check if the vm is powered off.."
    instances_list = conn.compute.servers()
    for vm in instances_list:
      ins_name = vm.name
      if instance_name == ins_name:
        ins_state = vm.status
        while ins_state != 'SHUTOFF':
          print('Please wait for sometime to let the shutdown complete..')
          instances_list = conn.compute.servers()
          for vm in instances_list:
            ins_name = vm.name
            if instance_name == ins_name:
              time.sleep(4)
              ins_state = vm.status
        snap_num = raw_input("Enter the snap number from the above to perform restore on the all the disks : ")
        with open('/root/ceph-opsk-python/bkp-res-ins-and-vol-ids.csv', 'r') as ids:
          for k in ids:
            disk_id = str(k).replace('\n', '')
            instances_list = conn.compute.servers()
            for vm in instances_list:
              ins_id = vm.id
              if disk_id == ins_id:
                ceph_pool(disk_id, snap_num)
              else:
                ins_vols = vm.attached_volumes
                for vol in ins_vols:
                  if disk_id in str(vol):
                    ceph_pool(disk_id, snap_num)

      break

  instances_list = conn.compute.servers()
  for vm in instances_list:
    ins_name = vm.name
    if instance_name == ins_name:
      ins_state = vm.status
      while ins_state != 'SHUTOFF':
        print('Please wait for sometime to let the shutdown complete..')
        instances_list = conn.compute.servers()
        for vm in instances_list:
          ins_name = vm.name
          if instance_name == ins_name:
            time.sleep(4)
            ins_state = vm.status
      snap_num = raw_input("Enter the snap number from the above to perform restore on the all the disks : ")
      with open('/root/ceph-opsk-python/bkp-res-ins-and-vol-ids.csv', 'r') as ids:
        for k in ids:
          disk_id = str(k).replace('\n', '')
          instances_list = conn.compute.servers()
          for vm in instances_list:
            ins_id = vm.id
            if disk_id == ins_id:
              ceph_pool(disk_id, snap_num)
            else:
              ins_vols = vm.attached_volumes
              for vol in ins_vols:
                if disk_id in str(vol):
                  ceph_pool(disk_id, snap_num)
  
  print "Powering on the server"
  start_server()

#Condition to check for purge operation on all disks and call puege object of openstack_disk class..
if instance_choice == '4':
  with open('/root/ceph-opsk-python/bkp-res-ins-and-vol-ids.csv', 'r') as ids:
    for k in ids:
      disk_id = str(k).replace('\n', '')
      option.purge(disk_id)
