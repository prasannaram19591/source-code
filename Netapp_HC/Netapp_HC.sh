#! /bin/bash

user='username'
pass='password'
tstamp=`date | awk '{print $1,$2,$3,$NF,$4}' | sed 's/[ :]/-/g'`
echo "Hostname,IP_Address,Overall_Status,System_Health,Emergency_Event,Sub-System_Status,Failed_Disk,Vserver_Status,Cluster_Status,Aggr_Status,Volume_Status,Network_Interface,Shelf_Status,Port_Status,CF_Status,CPU_Utilization" > $tstamp-netapp-report.csv
rm -f *.txt
for array in `cat netapp_arrays.csv`
do
		sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "hostname" > ntap_hostname_chk.txt
		ntap_hostname_chk=$(cat ntap_hostname_chk.txt | grep -v Last | sort | uniq | tail -n 1)
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "system health subsystem show" > ntap_sub_sys_chk.txt
        ntap_sub_sys_chk=$(if [[ $(cat ntap_sub_sys_chk.txt | sed -e "s/\r//g" | grep . | grep -iE 'ok|degraded' | awk '{print $NF}' | sort | uniq | wc -l) == "1" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "system health alert show" > ntap_health_alert_chk.txt
        ntap_health_alert_chk=$(if [[ $(cat ntap_health_alert_chk.txt | sed -e "s/\r//g" | grep . | grep "This table is currently empty.") ]]; then echo "OK"; else echo "NOT_OK"; fi)
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "event show -severity emergency" > ntap_sev_egency_chk.txt
        ntap_sev_egency_chk=$(if [[ $(cat ntap_sev_egency_chk.txt | sed -e "s/\r//g" | grep . | grep "There are no entries matching your query") ]]; then echo "OK"; else echo "NOT_OK"; fi)
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "vol show -state offline" > ntap_vol_chk.txt
        ntap_vol_chk=$(if [[ $(cat ntap_vol_chk.txt | sed -e "s/\r//g" | grep . | grep "There are no entries matching your query") ]]; then echo "OK"; else echo "NOT_OK"; fi)
		sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "storage disk show -container-type broken" > ntap_disk_chk.txt
        ntap_disk_chk=$(if [[ $(cat ntap_disk_chk.txt | sed -e "s/\r//g" | grep . | grep "There are no entries matching your query") ]]; then echo "OK"; else echo "NOT_OK"; fi)
		sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "cluster show" > ntap_clust_show_chk.txt
        ntap_clust_show_chk=$(if [[ $(cat ntap_clust_show_chk.txt | sed -e "s/\r//g" | grep . | grep -vE 'Node|-------|entries|login' | sed '/^$/d' | awk '{print $2}' | sort | uniq) == "true" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "aggr show" > ntap_aggr_show_chk.txt
        ntap_aggr_show_chk=$(if [[ $(cat ntap_aggr_show_chk.txt | sed -e "s/\r//g" | grep . | grep -vE 'Node|-------|entries|login' | sed '/^$/d' | awk '{print $5}' | sed '/^$/d' | sort | uniq) == "online" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "vserver show" > ntap_vsrv_show_chk.txt
        ntap_vsrv_show_chk=$(if [[ $(cat ntap_vsrv_show_chk.txt | sed -e "s/\r//g" | grep . | grep data | awk '{print $4}' | sort | uniq) == "running" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "storage shelf show" > ntap_shlf_show_chk.txt
        ntap_shlf_show_chk=$(if [[ $(cat ntap_shlf_show_chk.txt | grep Shelf -A 2000 | sed -e "s/\r//g" | grep . | grep -vE 'Node|-------|entries|login|Status|Operational' | sed '/^$/d' | awk '{print $NF}' | sort | uniq) == "Normal" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "net int show" > ntap_int_show_chk.txt
        ntap_int_show_chk=$(if [[ $(cat ntap_int_show_chk.txt | sed -e "s/\r//g" | grep . | grep '\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}' | grep -o -w 'up/up' | sort | uniq) == "up/up" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "net port show -health" > ntap_port_show_chk.txt
        ntap_port_show_chk=$(if [[ $(cat ntap_port_show_chk.txt | sed -e "s/\r//g" | grep . | grep up | awk '{print $3}' | sort | uniq) == "healthy" ]]; then echo "OK"; else echo "NOT_OK"; fi)
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "cf status" > ntap_cf_stat_chk.txt
        ntap_cf_stat_chk=$(if [[ $(cat ntap_cf_stat_chk.txt | sed -e "s/\r//g" | grep . |grep -vE 'Takeover|Possible|login|--------|displayed.' | sed '/^$/d' | awk '{print $3}' | sort | uniq) == "true" ]]; then echo "OK"; else echo "NOT_OK"; fi)
		sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "node run * sysstat -c 5 -m 3" > ntap_cpu_stat_chk.txt
		for node in `grep Node ntap_cpu_stat_chk.txt | awk '{print $NF}'`
			do
				for avg in `grep $node ntap_cpu_stat_chk.txt -A 6 | awk '{print $2}' | grep "%" | awk -F "%" '{print $1}' | awk '{ total += $1 } NR == 5 { print total / 5 }' | awk -F "." '{print $1}'`
				do
					if [ $avg -gt 85 ]; then
						echo "NOT_OK"
					else
						echo "OK"
					fi
				done
			done > status.txt
		ntap_cpu_stat_chk=$(if [[ $(cat status.txt | grep NOT_OK) ]]; then echo "NOT_OK"; else echo "OK"; fi)
		ntap_overall_status=$(if ([ "$ntap_sub_sys_chk" == "OK" ] && [ "$ntap_health_alert_chk" == "OK" ] && [ "$ntap_sev_egency_chk" == "OK" ] && [ "$ntap_vol_chk" == "OK" ] && [ "$ntap_disk_chk" == "OK" ] && [ "$ntap_clust_show_chk" == "OK" ] && [ "$ntap_aggr_show_chk" == "OK" ] && [ "$ntap_vsrv_show_chk" == "OK" ] && [ "$ntap_shlf_show_chk" == "OK" ] && [ "$ntap_int_show_chk" == "OK" ] && [ "$ntap_port_show_chk" == "OK" ] && [ "$ntap_cf_stat_chk" == "OK" ] && [ "$ntap_cpu_stat_chk" == "OK" ]); then echo "Healthy"; else echo "Faulty"; fi)
		echo "$ntap_hostname_chk,$array,$ntap_overall_status,$ntap_health_alert_chk,$ntap_sev_egency_chk,$ntap_sub_sys_chk,$ntap_disk_chk,$ntap_vsrv_show_chk,$ntap_clust_show_chk,$ntap_aggr_show_chk,$ntap_vol_chk,$ntap_int_show_chk,$ntap_shlf_show_chk,$ntap_port_show_chk,$ntap_cf_stat_chk,$ntap_cpu_stat_chk" >> $tstamp-netapp-report.csv
done


