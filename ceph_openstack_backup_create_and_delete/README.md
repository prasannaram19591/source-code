# ceph_openstack_backup_create_and_delete

This shell script will help ceph and openstack admins to take care of the backup related works. The code will take ceph level snapshots of all the openstack running instances. We can exclude some set of instances as well and all the newly created instances will get automatically included in the defined backup policy without any manaual tasks. This makes the life of an openstack backup admin so easy. With the help of Jenkins we can log the every day activity of backup creation as well as deletion and report can be made to be sent directly to the admins.

Pre-requisites:

1.  Working ceph storage cluster.
2.  Working openstack compute cluster.
3.  Openstack client package.
4.  Linux machine (RHEL/Ubuntu).
5.  Optionally Jenkins for every day backup task logging.
