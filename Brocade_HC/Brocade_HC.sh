#! /bin/bash

#tstamp=`date | awk '{print $1,$2,$3,$NF}' | sed 's/ /-/g'`
cd /root/brocade_hc
rm -f *.csv
pass='password'
tstamp=`date | awk '{print $1,$2,$3,$NF,$4}' | sed 's/[ :]/-/g'`
echo "Device_Name,Switch_status,Temp_status,Fan_status,Power_supply_status,Port_status,Overall_status" > $tstamp-switch-report.csv
echo "$tstamp-switch-report.csv" > file.txt
for switch in `cat brocade_switches.txt`
do
        echo "Running commands on the switch: $switch"
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no user-name@$switch "switchshow" > $switch-ss.txt
        sw_name=`cat $switch-ss.txt | grep switchName | awk '{print $NF}'`
        sw_state=`cat $switch-ss.txt | grep switchState | awk '{print $NF}'`
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no user-name@$switch "sensorshow" > $switch-sen.txt
        cat $switch-sen.txt | sed 's/Power Supply/Power_Supply/g' | sed 's/Fan        /Fan/g' | sed 's/Ok,speed/Ok, speed/g' | sed 's/[,()]//g' | awk '{print $3,$4,$5}' | grep is > sensor-out.txt
        temp=`grep Temperature sensor-out.txt`
        temp_chk=`echo $temp | grep Faulty`
        if [ -z "$temp_chk" ]
        then
                #echo "temperature sensors are not faulty"
                temp_status='OK'
        else
                #echo "temperature sensors are faulty"
                temp_status='Faulty'
        fi

        fan=`grep Fan sensor-out.txt`
        fan_chk=`echo $fan | grep Faulty`
        if [ -z "$fan_chk" ]
        then
                #echo "fan sensors are not faulty"
                fan_status='OK'
        else
                #echo "fan sensors are faulty"
                fan_status='Faulty'
        fi

        ps=`grep Power_Supply sensor-out.txt`
        ps_chk=`echo $ps | grep Faulty`
        if [ -z "$ps_chk" ]
        then
                #echo "power supply sensors are not faulty"
                power_status='OK'
        else
                #echo "power supply sensors are faulty"
                power_status='Faulty'
        fi

        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no user-name@$switch "porterrshow" > $switch-perr.txt
        cat $switch-perr.txt | grep ":" > porterr-out.txt
        enc_in=`cat porterr-out.txt | awk '{print $4}' | sort | uniq | wc -l`
        crc_err=`cat porterr-out.txt | awk '{print $5}' | sort | uniq | wc -l`
        crc_g_eof=`cat porterr-out.txt | awk '{print $6}' | sort | uniq | wc -l`
        too_shrt=`cat porterr-out.txt | awk '{print $7}' | sort | uniq | wc -l`
        too_long=`cat porterr-out.txt | awk '{print $8}' | sort | uniq | wc -l`
        bad_eof=`cat porterr-out.txt | awk '{print $9}' | sort | uniq | wc -l`
        enc_out=`cat porterr-out.txt | awk '{print $10}' | sort | uniq | wc -l`
        disc_c3=`cat porterr-out.txt | awk '{print $11}' | sort | uniq | wc -l`
        link_fail=`cat porterr-out.txt | awk '{print $12}' | sort | uniq | wc -l`
        loss_sync=`cat porterr-out.txt | awk '{print $13}' | sort | uniq | wc -l`
        loss_sig=`cat porterr-out.txt | awk '{print $14}' | sort | uniq | wc -l`
        frjt=`cat porterr-out.txt | awk '{print $15}' | sort | uniq | wc -l`
        fbsy=`cat porterr-out.txt | awk '{print $16}' | sort | uniq | wc -l`
        c3_tout_tx=`cat porterr-out.txt | awk '{print $17}' | sort | uniq | wc -l`
        c3_tout_rx=`cat porterr-out.txt | awk '{print $18}' | sort | uniq | wc -l`
        pcs_err=`cat porterr-out.txt | awk '{print $19}' | sort | uniq | wc -l`
        uncor_err=`cat porterr-out.txt | awk '{print $20}' | sort | uniq | wc -l`
        if ([ "$enc_in" == "1" ] && [ "$crc_err" == "1" ] && [ "$crc_g_eof" == "1" ] && [ "$too_shrt" == "1" ] &&  [ "$too_long" == "1" ] && [ "$bad_eof" == "1" ] && [ "$enc_out" == "1" ] && [ "$disc_c3" == "1" ] && [ "$link_fail" == "1" ] && [ "$loss_sync" == "1" ] && [ "$loss_sig" == "1" ] && [ "$frjt" == "1" ] && [ "$fbsy" == "1" ] && [ "$c3_tout_tx" == "1" ] && [ "$c3_tout_rx" == "1" ] && [ "$pcs_err" == "1" ] && [ "$uncor_err" == "1" ]);
        then
                #echo "no port errors found"
                port_status='OK'
        else
                #echo "port errors found"
                port_status='Faulty'
        fi
        if ([ "$temp_status" == "OK" ] && [ "$fan_status" == "OK" ] && [ "$power_status" == "OK" ] && [ "$port_status" == "OK" ]);
        then
                overall_status='OK'
        else
                overall_status='Degraded'
        fi
        echo $sw_name,$sw_state,$temp_status,$fan_status,$power_status,$port_status,$overall_status >> $tstamp-switch-report.csv
done
rm -f 10.*
# echo "Hi Team, Please find the HC report" | mailx -s 'Brocade_Health_Report' -a $tstamp-switch-report.csv user-name@abc.com
( printf '%s\n' "Hello Team,"; printf '%s\n'; printf '%s\n' "Please find the attached SAN Switch health check report."; printf '%s\n'; printf '%s\n' "Thanks and Regards,"; printf '%s\n' "Storage Team"; printf '%s\n' "storage@abc.com"; ) | mailx -s 'Brocade_SAN_Switch_Health_Report' -a $tstamp-switch-report.csv -c storage@abc.com storageteam@abc.com

