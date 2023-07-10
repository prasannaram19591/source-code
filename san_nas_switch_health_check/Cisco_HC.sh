#! /bin/bash

pass=password
tstamp=`date | awk '{print $1,$2,$3,$NF,$4}' | sed 's/[ :]/-/g'`
rm -f all_port_stats.txt *.csv
echo "Switch_Name,Switch_status,Power_supply_status,Fan_status,Port_status,Overall_status" > $tstamp-switch-health-check.csv
echo "$tstamp-switch-health-check.csv" > file.txt
for switch in `cat mds_switches.txt`
do
        echo "Running commands on the switch: $switch"
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no admin@$switch "show switch" > $switch-ss.txt 2>/dev/null
        sw_name=`cat $switch-ss.txt | awk '{print $NF}'`
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no admin@$switch "show hardware" > mds_module_chk.txt 2>/dev/null
		sshpass -p "$pass" ssh -o StrictHostKeyChecking=no admin@$switch "show environment power" > mds_power_supply_chk.txt 2>/dev/null
        mds_module_chk=$(if [[ $(grep Module mds_module_chk.txt | grep -vE 'type|has' | awk '{print $NF}' | sort | uniq) == "ok" ]]; then echo "OK"; else echo "NOT_OK"; fi)
		mds_power_supply_chk=$(if [[ $(grep "W" mds_power_supply_chk.txt | grep -v "Total Power" | grep -v Absent | awk '{print $NF}' | sed 's/Powered-Up/Ok/g' | sort | uniq) == "Ok" ]]; then echo "Ok"; else echo "NOT_OK"; fi)
        mds_fan_chk=$(if [[ $(grep Fan mds_module_chk.txt | grep -v has | awk '{print $NF}' | sort | uniq) == "ok" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no admin@$switch "sh int brief" > port_brief.txt 2>/dev/null
        last_port=`grep fc port_brief.txt | grep "/" | awk '{print $1}' | tail -n 1 | awk -F "/" '{print $2}'`
        for i in $(seq 1 $last_port)
        do
                sshpass -p "$pass" ssh -o StrictHostKeyChecking=no admin@$switch "sh int fc1/$i | include errors|CRC" > port_stats.txt 2>/dev/null
                in_fr_disc=`grep discard port_stats.txt | head -n 1 | awk -F "discards" '{print $1}' | awk '{print $NF}'`
                in_fr_err=`grep discard port_stats.txt | head -n 1 | awk -F "errors" '{print $1}' | awk -F "," '{print $2}'`
                out_fr_disc=`grep discard port_stats.txt | tail -n 1 | awk -F "discards" '{print $1}' | awk '{print $NF}'`
                out_fr_err=`grep discard port_stats.txt | tail -n 1 | awk -F "errors" '{print $1}' | awk -F "," '{print $2}'`
                crc_err=`grep CRC port_stats.txt | awk -F "invalid" '{print $1}' | awk '{print $NF}'`
                echo $in_fr_disc $in_fr_err $out_fr_disc $out_fr_err $crc_err >> all_port_stats.txt
        done
        all_in_fr_disc=$(if [[ $(awk '{print $1}' all_port_stats.txt | sort | uniq) == "0" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        all_in_fr_err=$(if [[ $(awk '{print $2}' all_port_stats.txt | sort | uniq) == "0" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        all_out_fr_disc=$(if [[ $(awk '{print $3}' all_port_stats.txt | sort | uniq) == "0" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        all_out_fr_err=$(if [[ $(awk '{print $4}' all_port_stats.txt | sort | uniq) == "0" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        all_crc_err=$(if [[ $(awk '{print $5}' all_port_stats.txt | sort | uniq) == "0" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        [ "$all_in_fr_disc" == "OK" ] && [ "$all_in_fr_err" == "OK" ] && [ "$all_out_fr_disc" == "OK" ] && [ "$all_out_fr_err" == "OK" ] && [ "$all_crc_err" == "OK" ] && port_status='OK' || port_status='Faulty'
        [ "$mds_module_chk" == "OK" ] && [ "$mds_power_supply_chk" == "OK" ] && [ "$mds_fan_chk" == "OK" ] && [ "$port_status" == "OK" ] && overall_status='OK' || overall_status='Degraded'

        echo $sw_name,$mds_module_chk,$mds_power_supply_chk,$mds_fan_chk,$port_status,$overall_status >> $tstamp-switch-health-check.csv
done
rm -f 10.*
( printf '%s\n' "Hello Team,"; printf '%s\n'; printf '%s\n' "Please find the attached SAN Switch health check report."; printf '%s\n'; printf '%s\n' "Thanks and Regards,"; printf '%s\n' "Storage Team"; printf '%s\n' "abc@xyz.com"; ) | mailx -s 'Cisco_SAN_Switch_Health_Report' -a $tstamp-switch-health-check.csv -c abc@xyz.com abc@xyz.com
