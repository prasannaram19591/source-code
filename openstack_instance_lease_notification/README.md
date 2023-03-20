# openstack_instance_lease_notification

Openstack admins,

  Whats your idea about openstack instances life cycle management? Without the native functionality to notify VM owners about their owned vms lease expiry, its quite difficult to track the vm least expiry whereas the VMware VRA orchestration comes in handy to manage vm life cycle. Here is a python code to notify instance owners about their vm expiry and helps in effective life cycle management across all openstack projects. The code will send 3 notifications to the VM owners informing about their vm expiry dates and mails a list of expired instances to the openstack administrator so that the instances can be purged. It also mails the notification logs which are sent to users on a daily basis.
  
  Pre-requisites:
  1.  Running openstack cluster with version Rocky or above.
  2.  A linux VM with openstack cli, python, mail modules and SMTP enabled so that mail can be sent.
  3.  Optionally Jenkins to handle auto deletion of expired instances.
  4.  In the script.sh file enclosed in this repository, point your openstack openrc file.
  5.  Copy all te enclosed files in a directory.
