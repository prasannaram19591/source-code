#!/bin/bash

source ev
rm -rf windows_machines.txt linux_machines.txt
openstack server list -f value -c Networks -c Name > srv_with_ip
lines=`wc -l srv_with_ip | awk '{print $1}'`
for (( i=1;i<=$lines;i++ ))
do
  j=`head -n $i srv_with_ip | tail -n +$i`
  name=`echo $j | awk '{print $1}'`
  ip=`echo $j | awk '{print $2}' | sed 's/,//' | sed 's/;//' | awk -F "=" '{print $2}'`
  ttl=`ping $ip -c 1 | grep ttl | awk '{print $6}' |  awk -F "=" '{print $2}'`
  if [ $ttl -ge "100" ]; then
    echo "$name with $ip is a Windows machine.." >> windows_machines.txt
  else
    echo "$name with $ip is a Linux machine.." >> linux_machines.txt
  fi
done
