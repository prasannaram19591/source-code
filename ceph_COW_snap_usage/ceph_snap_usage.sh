#!/bin/bash

sudo ceph osd pool ls > pool-list.csv
for p in `cat pool-list.csv`
do
  sudo rbd du -p $p > $p-pool-imgs.csv
  cat $p-pool-imgs.csv >> pool-imgs.csv
done

rm -f srv_snap.csv vol_snap.csv
calc(){ awk "BEGIN { print "$*" }"; }
dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`

source openrc_file
openstack server list --all-projects -f value -c ID > srv-list.csv
openstack volume list --all-projects -f value -c ID > vol-list.csv

for k in `cat srv-list.csv`
do
  srv_snp=`grep $k pool-imgs.csv | awk '{print $3}' | tail -n +2`
  srv_snp_cnt=`grep $k pool-imgs.csv | awk '{print $3}' | tail -n +2 | wc -l`
  if [ -z "$srv_snp" ]; then
    :
  else
    for j in $srv_snp
    do
      UNIT=`echo $j | rev | cut -b 1-3 | rev`
      SPAC=`echo $j | rev | cut -b 4-10 | rev`
      if [ "$UNIT" == "MiB" ]; then
        TB=`calc $SPAC/1024/1024`
        echo $TB >> srv_snap.csv
      elif [ "$UNIT" == "GiB" ]; then
        TB=`calc $SPAC/1024`
        echo $TB >> srv_snap.csv
      elif [ "$UNIT" == "TiB" ]; then
        echo $SPAC >> srv_snap.csv
      fi
    done
  fi
done

SRV_TB=`awk '{ sum += $1 } END { print sum }' srv_snap.csv`

for k in `cat vol-list.csv`
do
  vol_snp=`grep $k pool-imgs.csv | awk '{print $3}' | tail -n +2`
  vol_snp_cnt=`grep $k pool-imgs.csv | awk '{print $3}' | tail -n +2 | wc -l`
  if [ -z "$vol_snp" ]; then
    :
  else
    for j in $vol_snp
    do
      UNIT=`echo $j | rev | cut -b 1-3 | rev`
      SPAC=`echo $j | rev | cut -b 4-10 | rev`
      if [ "$UNIT" == "MiB" ]; then
        TB=`calc $SPAC/1024/1024`
        echo $TB >> vol_snap.csv
      elif [ "$UNIT" == "GiB" ]; then
        TB=`calc $SPAC/1024`
        echo $TB >> vol_snap.csv
      elif [ "$UNIT" == "TiB" ]; then
        echo $SPAC >> vol_snap.csv
      fi
    done
  fi
done

VOL_TB=`awk '{ sum += $1 } END { print sum }' vol_snap.csv`

TOT_TB=`calc $SRV_TB+$VOL_TB`
echo
echo
echo ---------------------------------------------------------------------------
echo "   Snap space consumption for $day-$mon-$date-$year"
echo "The snap occupied space for root drive is $SRV_TB TB"
echo "The snap occupied space for extended drive is $VOL_TB TB"
echo
echo "The total space occupied by snapshots is $TOT_TB TB"
echo ---------------------------------------------------------------------------
echo

cat ceph-snap-db.csv | tail -n +2 > ceph-snap-tmp_db.csv
mv ceph-snap-tmp_db.csv ceph-snap-db.csv

echo $day-$mon-$date-$year,$SRV_TB,$VOL_TB,$TOT_TB >> ceph-snap-db.csv
sed -i '1iDate,Root_drive_snap_usage,Extended_drive_snap_uasage,Total_snap_uage' ceph-snap-db.csv
echo Please find the historical ceph daily snapshot capacity report below
echo
echo ---------------------------------------------------------------------------
cat ceph-snap-db.csv
echo ---------------------------------------------------------------------------
echo
