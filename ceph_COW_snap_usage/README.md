# ceph_COW_snap_usage
Open source ceph software defined storage users would have come across this problem of finding the total amount of space that is consumed by ceph copy-on-write snapshots alone in their cluster as ther is no direct command to reflect the snapshots usage stats. Here is a way to calculate the complete space occupied by snapshots alone in a ceph cluster. The code will take a complete dump of ceph images across various pools and finds the space occupied for snapshots alone in your complete openstack root partitions as well as extended partitions seperately.

Pre-requisites
  1. Running Openstack cloud with ceph as cinder backend for storage.
  2. Sudo access to the controller node on which ceph and openstack softwares are installed.
  3. Openstack source file (openRC file) on the controller node.
  4. Save the file as xxx.sh and add execute permissions.
  5. Run as normal shell script.
  6. The code will take a minimum of 3 to 5 minutes depending upon the total capacity of your ceph cluster and reports the snapshot space consumption.
