#/bin/bash

rm -f vol_id.csv new_vol_id.csv new_dels clones
source /home/vmadmin/ev
srv_id=`openstack server show $1 | grep -w id | head -n 1 | awk '{print $4}'`
openstack server show $1 | grep volumes_attached | grep -oP '\S+' | grep "}" | sed "s/u'//g" | sed "s/'},//g" | sed "s/'}]//g" >> vol_id.csv
flv_id=`openstack server show $1 | grep flavor | awk '{print $5}' | sed 's/[( )]//g'`

openstack server create --key-name rpc_support --image IMAGE_ID --flavor $flv_id --security-group SEC_GROUP_ID --availability-zone nova --nic net-id=NETWORK_ID $1-clone

for k in `cat vol_id.csv`
do
  vol_size=`openstack volume show $k | grep size | awk '{print $4}'`
  openstack volume create $k-clone-vol --type ssd --size $vol_size
  sleep 3
  new_vol_id=`openstack volume show $k-clone-vol | grep -w id | awk '{print $4}'`
  echo $new_vol_id >> new_vol_id.csv
  until [ $(nova show $1-clone | grep -w status | awk '{ print $4 }') == "ACTIVE" ]
    do
      echo "Instance $1-clone is building"
      sleep 3
    done
  nova volume-attach $1-clone $new_vol_id
done

nova stop $1-clone

new_srv_id=`openstack server show $1-clone | grep -w id | head -n 1 | awk '{print $4}'`
driv=_disk
 
ceph osd pool ls > ceph_pools.csv

for j in `cat ceph_pools.csv`
do
  ceph_id=`rbd ls $j | grep $srv_id | head -n 1`
  if [ -z "$ceph_id" ]; then
    :
  else
    until [ $(nova show $1-clone | grep -w status | awk '{ print $4 }') == "SHUTOFF" ]
    do
      echo "Instance $1-clone is powering off"
      sleep 3
    done
     rbd rm $j/$new_srv_id$driv
     rbd snap add $j/$ceph_id@$srv_id-clone
     rbd cp $j/$ceph_id@$srv_id-clone $j/$new_srv_id$driv
     rbd snap rm $j/$ceph_id@$srv_id-clone
  fi
done

for l in `cat ceph_pools.csv`
do
  for m in `cat new_vol_id.csv`
  do
    ceph_id=`rbd ls $l | grep $m | head -n 1`
    if [ -z "$ceph_id" ]; then
      :
    else
       rbd rm $l/$ceph_id
      echo $ceph_id >> new_dels
    fi
  done
done

for m in `cat vol_id.csv`
do
  for l in `cat ceph_pools.csv`
  do
    ceph_id=`rbd ls $l | grep $m | head -n 1`
    if [ -z "$ceph_id" ]; then
      :
    else
      rbd snap add $l/$ceph_id@clone
      echo $l/$ceph_id@clone >> clones
    fi
  done
done

cnt=`wc -l new_vol_id.csv | awk '{print $1}'`

for ((n=1;n<=$cnt;n++))
do
  a=`head -n $n clones | tail -n +$n`
  b=`head -n $n new_dels | tail -n +$n`
  rbd cp $a ssd_volumes/$b
done

for p in `cat clones`
do
  rbd snap rm $p
done

nova start $1-clone
echo "The cloned instance is $1-clone"
