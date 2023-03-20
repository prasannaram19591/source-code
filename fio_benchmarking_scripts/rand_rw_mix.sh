#!/bin/bash

rm -f randrwmix_report.csv

calc(){ awk "BEGIN { print "$*" }"; }

for bs in `cat block_size.csv`
do
  for ds in `cat data_size.csv`
  do
    for tr in `cat threads.csv`
    do
      for rpr in `cat percentage.csv`
      do
        wpr=`calc 100-$rpr`
        echo Running random fio job on a $ds size of data with $bs block size having $tr threads for $rpr percent read and $wpr percent write..

        FIOCMD=`echo fio --name=randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr --rw=randrw --rwmixread=$rpr --direct=1 --ioengine=libaio --bs=$bs --numjobs=$tr --size=$ds --group_reporting`

        fio --name=randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr --rw=randrw --rwmixread=$rpr --direct=1 --ioengine=libaio --bs=$bs --numjobs=$tr --size=$ds --group_reporting > randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt

        RIOPS=`grep -w read randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt | grep IOPS | awk -F "=" '{ print $2 }' | awk -F "," '{ print $1}'`
        WIOPS=`grep -w write randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt | grep IOPS | awk -F "=" '{ print $2 }' | awk -F "," '{ print $1}'`

        RIOPSUNIT=`grep -w read randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt | grep IOPS | awk -F "=" '{ print $2 }' | awk -F "," '{ print $1}' | rev | cut -b 1-1`

        if [ "$RIOPSUNIT" == "k" ]; then
                RIOPS=`grep -w read randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt | grep IOPS | awk -F "=" '{ print $2 }' | awk -F "," '{ print $1}' | rev | cut -b 2-7 | rev`
                RIOPS=`calc $RIOPS*1000`
        elif [ "$RIOPSUNIT" == "m" ]; then
                RIOPS=`grep -w read randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt | grep IOPS | awk -F "=" '{ print $2 }' | awk -F "," '{ print $1}' | rev | cut -b 2-7 | rev`
                RIOPS=`calc $RIOPS*1000000`
        fi

        WIOPSUNIT=`grep -w write randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt | grep IOPS | awk -F "=" '{ print $2 }' | awk -F "," '{ print $1}' | rev | cut -b 1-1`

        if [ "$WIOPSUNIT" == "k" ]; then
                WIOPS=`grep -w write randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt | grep IOPS | awk -F "=" '{ print $2 }' | awk -F "," '{ print $1}' | rev | cut -b 2-7 | rev`
                WIOPS=`calc $WIOPS*1000`
        elif [ "$RIOPSUNIT" == "m" ]; then
                WIOPS=`grep -w write randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt | grep IOPS | awk -F "=" '{ print $2 }' | awk -F "," '{ print $1}' | rev | cut -b 2-7 | rev`
                WIOPS=`calc $WIOPS*1000000`
        fi

        RBWPS=`grep -w read randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt | grep BW | awk -F "=" '{ print $3 }' | awk '{ print $1 }' | rev | cut -b 6-12 | rev`
        WBWPS=`grep -w write randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt | grep BW | awk -F "=" '{ print $3 }' | awk '{ print $1 }' | rev | cut -b 6-12 | rev`

        RBWUNIT=`grep -w read randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt | grep BW | awk -F "=" '{ print $3 }' | awk '{ print $1 }' | rev | cut -b 1-5 | rev`

        if [ "$RBWUNIT" == "KiB/s" ]; then
                RBWPS=`calc $RBWPS/1024`
        fi

        WBWUNIT=`grep -w write randrwmix-r-$rpr-w-$wpr-bs-$bs-ds-$ds-tr-$tr.txt | grep BW | awk -F "=" '{ print $3 }' | awk '{ print $1 }' | rev | cut -b 1-5 | rev`

        if [ "$WBWUNIT" == "KiB/s" ]; then
                WBWPS=`calc $WBWPS/1024`
        fi

        echo $rpr,$wpr,$bs,$ds,$tr,$RIOPS,$RBWPS,$WIOPS,$WBWPS,$FIOCMD >> randrwmix_report.csv
      done
      echo >> randrwmix_report.csv
    done
  done
done

sed -i '1iRead_perc,Write_perc,Block_size,Data_size,Threads,Read_IOPS,Read_BW(MB),Write_IOPS,Write_BW(MB),FIO_Commands' randrwmix_report.csv
