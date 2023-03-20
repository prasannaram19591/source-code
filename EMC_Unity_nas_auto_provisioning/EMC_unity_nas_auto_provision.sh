#!/bin/bash

source emc_uty_480

SP_A_IP=10.x.x.x
SP_B_IP=10.x.x.x

INP_NAME=`echo $1`
CAP_NAME=`echo ${INP_NAME^^}`

SP_A_SHARE_CNT=`uemcli -d $UTY_IPA -u $UTY_USR -p $UTY_PWD /stor/prov/fs/nfs show -detail | grep -w Export | awk -F "=" '{print $2}' | awk -F ":" '{print $1}' | sed 's/ //g' | grep "$SP_A_IP" | wc -l`
SP_B_SHARE_CNT=`uemcli -d $UTY_IPA -u $UTY_USR -p $UTY_PWD /stor/prov/fs/nfs show -detail | grep -w Export | awk -F "=" '{print $2}' | awk -F ":" '{print $1}' | sed 's/ //g' | grep "$SP_B_IP" | wc -l`

if [ $SP_A_SHARE_CNT -gt $SP_B_SHARE_CNT ]; then
  FS_ID=`uemcli -d $UTY_IPA -u $UTY_USR -p $UTY_PWD /stor/prov/fs create -name DC-FS-$CAP_NAME -serverName EMC_UTY_NAS_SRV_SPB -poolName EMC_UTY_GENERIC_POOL -size $2 -thin yes -dataReduction yes -advancedDedup yes -type nfs | grep ID | awk '{print $3}'`
  uemcli -d $UTY_IPA -u $UTY_USR -p $UTY_PWD /stor/prov/fs/nfs create -name DC-NFS-$CAP_NAME -fs $FS_ID -defAccess root -path "/" | grep ID | awk '{print $3}'
  EXPORT_PATH=`uemcli -d $UTY_IPA -u $UTY_USR -p $UTY_PWD /stor/prov/fs/nfs show -detail | grep Export | grep DC-NFS-$CAP_NAME | awk '{print $4}'`
  echo $EXPORT_PATH > nfs_export_path
else
  FS_ID=`uemcli -d $UTY_IPA -u $UTY_USR -p $UTY_PWD /stor/prov/fs create -name DC-FS-$CAP_NAME -serverName EMC_UTY_NAS_SRV_SPA -poolName EMC_UTY_GENERIC_POOL -size $2 -thin yes -dataReduction yes -advancedDedup yes -type nfs | grep ID | awk '{print $3}'`
  uemcli -d $UTY_IPA -u $UTY_USR -p $UTY_PWD /stor/prov/fs/nfs create -name DC-NFS-$CAP_NAME -fs $FS_ID -defAccess root -path "/" | grep ID | awk '{print $3}'
  EXPORT_PATH=`uemcli -d $UTY_IPA -u $UTY_USR -p $UTY_PWD /stor/prov/fs/nfs show -detail | grep Export | grep DC-NFS-$CAP_NAME | awk '{print $4}'`
  echo $EXPORT_PATH > nfs_export_path
fi
