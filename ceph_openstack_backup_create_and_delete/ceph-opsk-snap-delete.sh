#!/bin/bash

rm -f tot-srv-list.csv proj-to-chk.csv srv-to-del.csv *.txt
source OpenRC_file
CEPH_PWD=`cat /home/vmadmin/ev | grep CEPH_PWD | awk -F "=" '{print $2}'`
openstack project list -f value -c Name > opsk_proj_list.csv
echo $CEPH_PWD | sudo -S sudo ceph osd pool ls > ceph_pool
snp=_snap

snaps_to_retain=3
current_timestamp_in_secs=`date +%s`

calc(){ awk "BEGIN { print "$*" }"; }
retention_days=`echo $snaps_to_retain`

month_num()
{

if [ "$1" == "Jan" ]
then
    mon=01
fi
if [ "$1" == "Feb" ]
then
    mon=02
fi
if [ "$1" == "Mar" ]
then
    mon=03
fi
if [ "$1" == "Apr" ]
then
    mon=04
fi
if [ "$1" == "May" ]
then
    mon=05
fi
if [ "$1" == "Jun" ]
then
    mon=06
fi
if [ "$1" == "Jul" ]
then
    mon=07
fi
if [ "$1" == "Aug" ]
then
    mon=08
fi
if [ "$1" == "Sep" ]
then
    mon=09
fi
if [ "$1" == "Oct" ]
then
    mon=10
fi
if [ "$1" == "Nov" ]
then
    mon=11
fi
if [ "$1" == "Dec" ]
then
    mon=12
fi

}

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
  echo $k >> srv-to-del.csv
  fi
done

for j in `cat srv-to-del.csv`
do
  dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`
  echo >> Purged-list-$day-$year-$mon-$date.txt 
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
        echo $CEPH_PWD | sudo -S sudo rbd snap ls $a/$b | tail -n +2 | awk '{print $2}' > snapshot_list.csv
        for snap in `cat snapshot_list.csv`
        do
          month=`echo $snap | awk -F "snap-" '{print $2}' | awk -F "-" '{print $3}'`
          month_num $month
          year=`echo $snap | awk -F "snap-" '{print $2}' | awk -F "-" '{print $2}'`
          day=`echo $snap | awk -F "snap-" '{print $2}' | awk -F "-" '{print $4}'`
          snap_tstmp=$year-$mon-$day
          snap_tstmp_in_secs=`date --date $snap_tstmp +%s`
          time_diff_in_secs=`expr $current_timestamp_in_secs - $snap_tstmp_in_secs`
          time_diff_in_days=`expr $time_diff_in_secs / 86400`
          if [ $time_diff_in_days -ge $retention_days ]
          then
             echo $CEPH_PWD | sudo -S sudo rbd snap rm $a/$b@$snap &> stat.csv
             status=`grep "100% complete" stat.csv`
             success="Removing snap: 100% complete...done."
             dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`
             if [ -z "$status" ]; then
               echo Error occured while deleting the instance $j root disk $b snapshot $snap at $day-$year-$mon-$date-$time >> Purged-list-$day-$year-$mon-$date.txt
             else
               echo Successfully deleted the instance $j root disk $b snapshot $snap at $day-$year-$mon-$date-$time >> Purged-list-$day-$year-$mon-$date.txt
             fi
          fi
       done 
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
          echo $CEPH_PWD | sudo -S sudo rbd snap ls $a/$b | tail -n +2 | awk '{print $2}' > snapshot_list.csv
          for snap in `cat snapshot_list.csv`
          do
            month=`echo $snap | awk -F "snap-" '{print $2}' | awk -F "-" '{print $3}'`
            month_num $month
            year=`echo $snap | awk -F "snap-" '{print $2}' | awk -F "-" '{print $2}'`
            day=`echo $snap | awk -F "snap-" '{print $2}' | awk -F "-" '{print $4}'`
            snap_tstmp=$year-$mon-$day
            snap_tstmp_in_secs=`date --date $snap_tstmp +%s`
            time_diff_in_secs=`expr $current_timestamp_in_secs - $snap_tstmp_in_secs`
            time_diff_in_days=`expr $time_diff_in_secs / 86400`
            if [ $time_diff_in_days -ge $retention_days ]
            then
                echo $CEPH_PWD | sudo -S sudo rbd snap rm $a/$b@$snap &> stat.csv
                status=`grep "100% complete" stat.csv`
                success="Removing snap: 100% complete...done."
                dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`
                if [ -z "$status" ]; then
                  echo Error occured while deleting the instance $j extended disk $b snapshot $snap at $day-$year-$mon-$date-$time >> Purged-list-$day-$year-$mon-$date.txt
                else
                  echo Successfully deleted the instance $j extended disk $b snapshot $snap at $day-$year-$mon-$date-$time >> Purged-list-$day-$year-$mon-$date.txt
                fi
            fi
          done
          fi
        done
        fi
      done
      fi
    fi
  done
done

