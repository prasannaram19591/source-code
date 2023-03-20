#!/bin/bash

dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`

srv=`cat /root/nova-rebuild/server.txt`
pass=`cat /root/nova-rebuild/password.txt`
img=`cat /root/nova-rebuild/image.txt`
srv_rev=`echo $srv | rev`
rm -f /root/nova-rebuild/password.txt /root/nova-rebuild/all_pool_chk.csv
source /root/nova-rebuild/Project

openstack project list -f value -c Name >/root/nova-rebuild/opsk_proj_list.csv

for k in `cat /root/nova-rebuild/opsk_proj_list.csv`
do
  prj_chk=`grep $k /root/nova-rebuild/opsk_proj_skip_list.csv`
  if [ -z "$prj_chk" ]; then
    echo $k >> /root/nova-rebuild/proj-to-chk.csv
  fi
done

rm -f /root/nova-rebuild/opsk_proj_list.csv
mv /root/nova-rebuild/proj-to-chk.csv /root/nova-rebuild/opsk_proj_list.csv


for k in `cat /root/nova-rebuild/opsk_proj_list.csv`
do
  source /root/nova-rebuild/$k; openstack server list -f value -c Name > /root/nova-rebuild/$k-srv-list.csv
done

for p in `cat /root/nova-rebuild/opsk_proj_list.csv`
do
    srv_chk=`cat /root/nova-rebuild/$p-srv-list.csv | grep -w $srv`
    echo $srv_chk > /root/nova-rebuild/$p-srv-fnd.csv
    if [ -z "$srv_chk" ]; then
      :
    else
      source /root/nova-rebuild/$p
      nova stop $srv
      nova_id=`openstack server show $srv -f value -c id`
      echo $pass | sudo -S sudo ceph osd pool ls > /root/nova-rebuild/ceph-pool.csv
    fi
done

for p in `cat /root/nova-rebuild/opsk_proj_list.csv`
do
  cat /root/nova-rebuild/$p-srv-fnd.csv >> /root/nova-rebuild/all_pool_chk.csv
done

proj_ver=`awk 'length($0) != 0' /root/nova-rebuild/all_pool_chk.csv`

if [ -z "$proj_ver" ]; then
  echo "The instance $srv is not found under any projects. Please re-run the job and input a valid instance name to rebuild."
else
  until [ $(nova show $srv | grep -w status | awk '{ print $4 }') == "SHUTOFF" ]
  do
    echo "Instance $srv is powering off"
    sleep 3
  done

  echo "The instnce $srv is powered off"
  sleep 3

  for c in `cat /root/nova-rebuild/ceph-pool.csv`
  do
    ceph_id=`echo $pass | sudo -S sudo rbd ls $c | grep $nova_id | head -n 1`
    if [ -z "$ceph_id" ]; then
      :
    else
     echo $pass | sudo -S sudo rbd mv $c/$ceph_id $c/$srv_rev-rebuild-$day-$year-$mon-$date-$time
    fi
  done

  nova rebuild $srv $img > /root/nova-rebuild/rebuild.txt

  until [ $(nova show $srv | grep -w status | awk '{ print $4 }') == "SHUTOFF" ]
  do
    echo "Instance $srv is rebuilding"
    sleep 3
  done

  echo "The instnce $srv is rebuilded"

  nova start $srv

  until [ $(nova show $srv | grep -w status | awk '{ print $4 }') == "ACTIVE" ]
  do
    echo "Instance $srv is rebooting"
    sleep 3
  done

  echo "The instnce $srv is powered on"
fi
