#!/bin/bash

rm -f tot-srv-list.csv proj-to-chk.csv srv-to-bkp.csv snapshot_logs.csv snapshot_list.csv
source OpenRC_file
CEPH_PWD=`cat /home/vmadmin/ev | grep CEPH_PWD | awk -F "=" '{print $2}'`
openstack project list -f value -c Name > opsk_proj_list.csv
echo $CEPH_PWD | sudo -S sudo ceph osd pool ls > ceph_pool
snp=_snap

for k in `cat opsk_proj_list.csv`
do
  prj_chk=`grep $k opsk_proj_skip_list.csv`
  if [ -z "$prj_chk" ]; then
    source $k
    openstack server list -f value -c Name > $k-srv-list.csv
    echo $k >> proj-to-chk.csv
  fi
done

for k in `cat opsk_proj_list.csv`
do
  prj_chk=`grep $k opsk_proj_skip_list_for_srv.csv`
  if [ -z "$prj_chk" ]; then
    source $k
    openstack server list -f value -c Name >> tot-srv-list.csv
  fi
done

cat append-list.csv tot-srv-list.csv > unsort-srv-list.csv 
cat unsort-srv-list.csv | sort | uniq > srv-list.csv

for k in `cat srv-list.csv`
do
  srv_chk=`grep $k opsk_srv_skip_list.csv`
  if [ -z "$srv_chk" ]; then
  echo $k >> srv-to-bkp.csv
  fi
done

for j in `cat srv-to-bkp.csv`
do
  echo >> snapshot_logs.csv
  echo $j >> snapshot_list.csv
  for k in `cat opsk_proj_list.csv`
  do
    prj_chk=`grep $k opsk_proj_skip_list.csv`
    if [ -z "$prj_chk" ]; then
      srv_chk=`grep $j $k-srv-list.csv`
      if [ -n "$srv_chk" ]; then
      source $k
      srv_id=`nova show $j | grep -w id | head -n 1 | awk '{print $4}'`
      nova show $j | grep volumes_attached | grep -oP '\S+' | grep -v id | grep -v delete | grep -v false | grep -v attached | grep -v "|" | sed "s/,//g" | cut -b 2-100 | rev | cut -b 2-100 | rev > vol_id.csv

      for a in `cat ceph_pool`
      do
        b=`echo $CEPH_PWD | sudo -S sudo rbd ls $a | grep $srv_id`
        if [ -n "$b" ]; then
        dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`
        tstmp=`echo $day-$year-$mon-$date-$time`
        echo $CEPH_PWD | sudo -S sudo rbd snap add $a/$b@$j$snp-$tstmp > log
	msg=`cat log`
        if [ -z "$msg" ]; then
        echo "The instance $j root disk $b is successfully snapshotted at $tstmp and the snap name is $j$snp-$tstmp" >> snapshot_logs.csv
        else
        echo "Encountered an error while snapshotting $j for its root disk $b at $tstmp" >> snapshot_logs.csv
        fi
        echo $b >> snapshot_list.csv
        echo $CEPH_PWD | sudo -S sudo rbd snap ls $a/$b | tail -n +2 | awk '{print $2}' >> snapshot_list.csv
        echo >> snapshot_list.csv
        fi
      done
       
      for k in `cat vol_id.csv`
      do
        if [ -n "$k" ]; then
        for a in `cat ceph_pool`
        do
          b=`echo $CEPH_PWD | sudo -S sudo rbd ls $a | grep $k`
          if [ -n "$b" ]; then
          dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`
          tstmp=`echo $day-$year-$mon-$date-$time`
          echo $CEPH_PWD | sudo -S sudo rbd snap add $a/$b@$j-$tstmp > log
          msg=`cat log`
          if [ -z "$msg" ]; then
          echo "The instance $j extended disk $b is successfully snapshotted at $tstmp and the snap name is $j-$tstmp" >> snapshot_logs.csv
          else
          echo "Encountered an error while snapshotting $j for its extended disk $b at $tstmp" >> snapshot_logs.csv
          fi
          echo $b >> snapshot_list.csv
          echo $CEPH_PWD | sudo -S sudo rbd snap ls $a/$b | tail -n +2 | awk '{print $2}' >> snapshot_list.csv
          echo >> snapshot_list.csv
          fi
        done
        fi
      done
      fi
    fi
  done
done

