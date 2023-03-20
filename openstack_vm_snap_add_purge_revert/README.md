# openstack_vm_snap_add_purge_revert

This python code will help openstack admins to perform on demand openstack instances backup creation, backup deletion, drive level restore and full instance restore who are having ceph as backend storage. This code is built with native openstack and ceph api's to identify the disk id and attached volume id on ceph and performs live snapshots for it. Admins can choose to perform a specific drive restore as well as full restore back to a point in time.

Pre-requisites:

1.  Working ceph storage cluster with version Luminious or above.
2.  Working openstack compute cluster with version rocky or above.
3.  Linux vm with python 2.7.5 or above.
