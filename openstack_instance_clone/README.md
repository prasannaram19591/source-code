# openstack_instance_clone

Open source ceph and openstack users, ever felt annoyed at the inability to natively do cloning of an instance in openstack horizon just as VMware vCenter does??
As there is no direct option of accheiving a clone of an instance with its all extended drives at one go, here is a workaround to save your day. The code is a shell based job which will perform cloning at ease without disrupting the source machine. It performs live snapthotting of all the drives of a given instance and does a image level cloning from the snapshot at the storage backend which in my case is opensource ceph storage.

Pre-Requisites

1.  Running openstack cluster with ceph as backend cinder storage.
2.  A machine which has admin previlaged access to perform openstack and ceph commands.
3.  Openstack openrc file to feed as source to this code.
4.  Optionally jenkins server if your clone requests are more frequent and you may want a GUI interface to perform clones.
5.  Save the file and assign execute permissions and invoke the job by typing ./openstack-clone.sh INSTANCE_NAME_TO_CLONE
