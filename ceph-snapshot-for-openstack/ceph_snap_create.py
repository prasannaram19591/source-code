import rados, sys, rbd
import os
from datetime import datetime
rbd_inst = rbd.RBD()
try:
        cluster = rados.Rados(conffile='')
except TypeError as e:
        print 'Argument validation error: ', e
        raise e
print "Created cluster handle."
try:
        cluster.connect()
except Exception as e:
        print "connection error: ", e
        raise e
finally:
        print "\nConnected to the ceph cluster.."
print "\nOpening an IO context to the pool for read/write operations"
print "------------------------------------------------------------"
ioctx = cluster.open_ioctx('Pool_name')
print "\nListing rbd objects in pool"
print "-----------------------------"
rbd_obj = rbd.RBD()
pool_rbd = rbd_obj.list(ioctx)
for obj in pool_rbd:
        print obj
        pool_img = rbd.Image(ioctx, obj)
        try:
                now = datetime.now()
                dt = now.strftime("%d-%m-%Y_%H-%M-%S")
                snp_nm = obj + '_' + dt
                pool_img.create_snap(snp_nm)
        finally:
                print "Created snapshot for object successfully"
        snp_list = pool_img.list_snaps()
        for snp in snp_list:
                print snp
