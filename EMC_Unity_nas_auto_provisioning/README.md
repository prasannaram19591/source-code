# EMC-Unity_nas_auto_provisioning

This automation work helps storage admins to automatically create a nfs share on the EMC unity storage systems. The script takes care of File system creation, nfs share allocation as well. It aso load balances the nfs work load on both of the storage processors. With the help of jenkins we can send mail notifications directly to the requestor.

Pre-requisites:

1.  Working EMC Unity storage device.
2.  UEMCLI client for unity package.
3.  Linux machine with connectivity to storage (RHEL/Ubuntu).
4.  Optionally Jenkins for mail notification.
