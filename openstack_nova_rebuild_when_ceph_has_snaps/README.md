# openstack_nova_rebuild_when_ceph_has_snaps

Hi Openstack and Ceph admins,

  If you are using ceph snapshots as a backup strategy for your openstack workloads, then nova rebuilds will not work properly as there is a bug on ceph and openstack integration which is prevalent in even ceph Mimic and Openstack Stein version. To get around this issue you can run the below shell script to remove the snaps on the ceph storage forst and then perform the normal nova rebuild. This will ensure that the rebuild gets successful.
  
  Pre-requisites:
  
  1.  Running ceph cluster
  2.  Running openstack cluster
  3.  Linux machine with openstack and ceph cli installed
  4.  Optionally Jenkins to schedule and mail
