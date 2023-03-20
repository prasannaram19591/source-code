#!/bin/bash
rm -rf portal_list.csv ins_without_business_fn.csv nova_meta
######### Block-1 Collecting server list #########
source /root/prj1
openstack server list --all-projects --project Project1 -f value -c Name > Project1.csv
source /root/prj2
openstack server list --all-projects --project Project2 -f value -c Name > Project2.csv
source /root/prj3
openstack server list --all-projects --project Project3 -f value -c Name > Project3.csv

cat Project1.csv Project2.csv Project3.csv > opsk_srv.csv

for i in `cat opsk_srv.csv`
do
  echo $i
  ######### Block-2 Project check #########
  proj1="$(grep -w "$i" Project1.csv)"
  proj2="$(grep -w "$i" Project2.csv)"
  proj3="$(grep -w "$i" Project3.csv)"
  if [ "$proj1" == "$i" ]; then
    source /root/prj1
  elif [ "$proj2" == "$i" ]; then
    source /root/prj2
  elif [ "$proj3" == "$i" ]; then
    source /root/prj3
  fi

  nova show $i > $i.txt
    ######### Block-3 Filtering instances without a Business function #########
    ins_biz_fn=`grep -w "metadata" $i.txt | awk '{print $14}' | sed 's/"//g' | sed "s/,//g"`
    if [ ! -n "$ins_biz_fn" ]; then
      echo "The instance $i doesn't have a business function" >> ins_without_business_fn.csv
      rm -rf $i.txt
    else
      ######### Block-4 Collecting instance specs #########
      ins_ip_addr=`grep -w "network" $i.txt | awk '{print $5}' | sed "s/,//g"`
      ins_state=`grep -w "vm_state" $i.txt | awk '{print $4}'`
      #ins_bu=`grep -w "metadata" $i.txt | awk '{print $17}' | sed 's/"//g' | sed "s/,//g"`
      #ins_proj_code=`grep -w "metadata" $i.txt | awk '{print $11}' | sed 's/"//g' | sed "s/,//g"`
      ins_img=`grep -w "image" $i.txt | awk '{print $4}'`
      ins_cpu=`grep -w "flavor:vcpus" $i.txt | awk '{print $4}'`
      ins_ram_mb=`grep -w "flavor:ram" $i.txt | awk '{print $4}'`
      declare -i ins_ram_gb; ins_ram_gb=$ins_ram_mb/1024
      ins_disk=`grep -w "flavor:disk" $i.txt | awk '{print $4}'`
      #ins_strt_dt=`grep -w "metadata" $i.txt | awk '{print $20}' | sed 's/"//g' | sed "s/,//g"`
      #ins_end_dt=`grep -w "metadata" $i.txt | awk '{print $6}' | sed 's/"//g' | sed "s/,//g"`
      #ins_owner=`grep -w "metadata" $i.txt | awk '{print $23}' | sed 's/"//g' | sed "s/}//g"`
      ins_id=`grep -w "id" $i.txt | head -n +1 | awk '{print $4}'`
      grep meta $i.txt | sed 's/metadata//g' | sed 's/[|]//g' | sed 's/,/:/g' | awk -F ":" '{print $1,$2}' >> nova_meta
      grep meta $i.txt | sed 's/metadata//g' | sed 's/[|]//g' | sed 's/,/:/g' | awk -F ":" '{print $3,$4}' >> nova_meta
      grep meta $i.txt | sed 's/metadata//g' | sed 's/[|]//g' | sed 's/,/:/g' | awk -F ":" '{print $5,$6}' >> nova_meta
      grep meta $i.txt | sed 's/metadata//g' | sed 's/[|]//g' | sed 's/,/:/g' | awk -F ":" '{print $7,$8}' >> nova_meta
      grep meta $i.txt | sed 's/metadata//g' | sed 's/[|]//g' | sed 's/,/:/g' | awk -F ":" '{print $9,$10}' >> nova_meta
      grep meta $i.txt | sed 's/metadata//g' | sed 's/[|]//g' | sed 's/,/:/g' | awk -F ":" '{print $11,$12}' >> nova_meta
      grep meta $i.txt | sed 's/metadata//g' | sed 's/[|]//g' | sed 's/,/:/g' | awk -F ":" '{print $13,$14}' >> nova_meta
      grep meta $i.txt | sed 's/metadata//g' | sed 's/[|]//g' | sed 's/,/:/g' | awk -F ":" '{print $15,$16}' >> nova_meta
      ins_strt_dt=`grep "Start Date" nova_meta | awk '{print $3}' | sed 's/"//g' | sed 's/[{}]//g'`
      ins_end_dt=`grep "Retirement Date" nova_meta | awk '{print $3}' | sed 's/"//g' | sed 's/[{}]//g'`
      ins_owner=`grep "VM Owner" nova_meta | awk '{print $3}' | sed 's/"//g' | sed 's/[{}]//g'`
      ins_bu=`grep "Business unit" nova_meta | awk '{print $3}' | sed 's/"//g' | sed 's/[{}]//g'`
      ins_proj_code=`grep "Project Code" nova_meta | awk '{print $3}' | sed 's/"//g' | sed 's/[{}]//g'`
      ins_comp=`grep -w "OS-EXT-SRV-ATTR:host" $i.txt | awk '{ print $4 }'`
      vol_id=`openstack server show $i | grep "id='" | sed  "s/volumes_attached//g" |sed "s/|//g" | sed "s/ //g" |  sed "s/id=//g" | sed "s/'//g"`
      echo -e "$vol_id\n" > vol.txt
      ######### Block-5 Calculating extended volume capacity #########
      for k in `cat vol.txt`
      do
        vol_size=`openstack volume show $k | grep size`
        echo $vol_size | awk '{print $4}' >> vol_to_add.txt
      done
      vol_tot_size=`paste -sd+ vol_to_add.txt | bc`
      rm -f vol_to_add.txt
      ######### Block-6 Append specs per instance to the portal list #########
      echo $i,$ins_ip_addr,$ins_state,$ins_biz_fn,$ins_bu,$ins_proj_code,$ins_img,$ins_cpu,$ins_ram_gb,$ins_disk,$vol_tot_size,$ins_strt_dt,$ins_end_dt,$ins_owner,$ins_id,$ins_comp >> portal_list.csv
      rm -rf $i.txt nova_meta
    fi
done
rm -f vol.txt
######### Block-7 Adding total cpu ram and disk on the portal list #########
cpu_total=`awk -F "," '{ sum += $8 } END { print sum }' portal_list.csv`
ram_total=`awk -F "," '{ sum += $9 } END { print sum }' portal_list.csv`
root_disk_total=`awk -F "," '{ sum += $10 } END { print sum }' portal_list.csv`
extd_disk_total=`awk -F "," '{ sum += $11 } END { print sum }' portal_list.csv`
######### Block-8 Append heading to the portal list #########
sed -i '1iInstance_Name,IP_Address,State,Business_function,Business_unit,Project_code,Flavor_of_OS,CPU,RAM,OS_DISK,EXTD_DISK,Start_date,Retirement_date,Owner,Instance_ID,Running_on' portal_list.csv
echo ,,,,,,Total,$cpu_total,$ram_total,$root_disk_total,$extd_disk_total >> portal_list.csv
######### Block-9 Copy the list to historic server list directory #########
dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`
cp portal_list.csv portal_lists/portal_list-$day-$year-$mon-$date-$time.csv
rm -rf /var/www/html/opsk_portal/portal_list.csv
######### Block-10 Copy the list to html directory #########
cp /dir1/dir2/portal_list.csv /var/www/html/opsk_portal
######### Block-11 Execute csv to html code #########
/bin/bash /dir1/dir2/csvtohtml_portal.sh > /var/www/html/opsk_portal/index.html
cd /var/www/html/opsk_portal
sed -i 's/refresh/"refresh"/g' index.html; sed -i 's/3600/"3600"/g' index.html
