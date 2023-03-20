from openstack import connection
import re, os, os.path
import rados, sys, rbd
from datetime import datetime as dt
from datetime import date
import datetime as dnt

#Setting date and snap retention count..
today = date.today()
retention_count = 2

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

#Snapshot operaation block..
for instance in instances_list:
  ins_name = instance.name
  ins_id = instance.id
  with open('/root/ceph-opsk-python/opsk_srv.csv', 'r') as f:
    for vms in f:
      if vms.replace('\n', '') == ins_name:
        with open('/root/ceph-opsk-python/ins-and-vol-ids.csv', 'w') as output:
          output.write(ins_id + '\n')
        ins_vols = instance.attached_volumes
        for k in ins_vols:
          j = str(k).split("u'id': u")
          l = str(j).replace("['{',", '').replace("'}", '').replace('"',  '').replace(']',  '').replace("'",  '').replace(" ", '')
          with open('/root/ceph-opsk-python/ins-and-vol-ids.csv', 'a') as output:
            output.write(l + '\n')
      
        with open('/root/ceph-opsk-python/ins-and-vol-ids.csv', 'r') as ids:
          for k in ids:
            id = str(k).replace('\n', '')
            for pool in pools:
              ioctx = cluster.open_ioctx(pool)
              rbd_obj = rbd.RBD()
              pool_rbd = rbd_obj.list(ioctx)
              for obj in pool_rbd:
                if id in obj:
                  #print id, obj
                  ins_img = rbd.Image(ioctx, obj)
                  #Snapshot creation try block..
                  try:
                    now = dt.now()
                    tstmp = now.strftime("%a-%Y-%b-%d-%H_%M_%S")
                    snap_name = ins_name + '_' + 'snap-' + tstmp
                    ins_img.create_snap(snap_name)
                    #print obj.get_snap_timestamp
                    print ("Successfully created the disk " + obj + " snapshot " + snap_name + " for the instance " + ins_name + " at " + tstmp + "." )
                  except:
                    print ("Error occured while creating the disk " + obj + " snapshot " + snap_name + " for the instance " + ins_name + " at " + tstmp + "." )
                  snaps = ins_img.list_snaps()
                  for snap in snaps:
                    #print dir(snaps)
                    #print snap.get_snap_timestamp(snap.get('name'))
                    date = str(snap.get('name')).split('-')[4]
                    date_int = int(date)
                    month = str(snap.get('name')).split('-')[3]
                    year = str(snap.get('name')).split('-')[2]
                    year_int = int(year)
                    if month == "Jan":
                       month_num = 1
                    if month == "Feb":
                       month_num = 2
                    if month == "Mar":
                       month_num = 3
                    if month == "Apr":
                       month_num = 4
                    if month == "May":
                       month_num = 5
                    if month == "Jun":
                       month_num = 6
                    if month == "Jul":
                       month_num = 7
                    if month == "Aug":
                       month_num = 8
                    if month == "Sep":
                       month_num = 9
                    if month == "Oct":
                       month_num = 10
                    if month == "Nov":
                       month_num = 11
                    if month == "Dec":
                       month_num = 12

                    month_int = int(month_num)
                    snap_tstmp = dnt.date(year_int, month_int, date_int)
                    diff = snap_tstmp-today
                    diff_tmp = str(diff)
                    days_str = diff_tmp.split("days")[0]

                    #Snapshot deletion try block..
                    if 'days' in diff_tmp:
                      try:
                        days = abs(int(days_str))
                        if days > retention_count:
                          #print snap.get('name')
                          ins_img.remove_snap(snap.get('name'))
                          print ("Successfully deleted the disk " + obj + " snapshot " + snap.get('name') + " for the instance " + ins_name + " at " + tstmp + "." )
                      except:
                        print ("Error occured while deleting the disk " + obj + " snapshot " + snap.get('name') + " for the instance " + ins_name + " at " + tstmp + "." )
      
