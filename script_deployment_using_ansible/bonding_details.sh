#!/bin/bash

cat /proc/net/bonding/bond0 | grep -E "Slave|MII" | grep -v queue | tail -n +3 | grep Interface > /bonding_details/bonding_interface
cat /proc/net/bonding/bond0 | grep -E "Slave|MII" | grep -v queue | tail -n +3 | grep Status > /bonding_details/bonding_status

cnt=`cat /bonding_details/bonding_interface | wc -l`
hostname > /bonding_details/`hostname`.txt
for ((n=1;n<=$cnt;n++))
do
  bonding_interface=`head -n $n /bonding_details/bonding_interface | tail -n +$n | awk -F ": " '{print $2}'`
  bonding_status=`head -n $n /bonding_details/bonding_status | tail -n +$n | awk -F ": " '{print $2}'`
  echo $bonding_interface $bonding_status >> /bonding_details/`hostname`.txt
done
out=`xargs < /bonding_details/$(hostname).txt`
echo $out > /bonding_details/`hostname`.txt
