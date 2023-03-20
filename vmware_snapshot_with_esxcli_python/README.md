# vmware_snapshot_with_esxcli_python

I have seen many requests in forums about vmware daily snapshots automation of the vms. There are many solutions with powercli and others with vsphere API. I tried with esxcli to take snapshots of vmware machines. The approach uses esxcli commands on the esxi hosts with the help of paramiko python module to ssh and execute commands.

Pre-requisites..
1.  Running vmware cluster or standalone esxi host (My work is on stand alone esxi, of course the code can be extended to be done at vCenter level.)
2.  Enable ssh access to the esxi hosts.
3.  A vm with access to the esxi host and python, pip and paramiko installed.
