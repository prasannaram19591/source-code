# openstack_backup_restore_using_ceph

  This is a complete batch only solution to restore your openstack workloads incase of any unforeseen situations. If ceph snapshots is your backup strategy in your private cloud for your openstack, then this code will give single pane of connectivity for both openstack and ceph to perform point in time restores. The code gets openstack instance name as input and displays the root and extended drives attached to it. Then it looks for its snapshots on ceph storage and performs point in time restore. If you feel a backup of current state is required you can opt for it. Tasks performed by this code gets recorded as logs which can be used for future reference.
  
  Jenkins mail notifications is also configured in the code, so just in case you want to be notified about the restores performed through this code, you can add it too.

Pre-requisites:
1.  Working openstack cloud with ceph as cinder backend.
2.  An openstack client machine which uses API calls to fetch metadata of instances.
3.  Access to the ceph controller node to find the location of the openstack instances in the pool.
4.  Full installation of PuTTY which has pscp, plink utilities.

