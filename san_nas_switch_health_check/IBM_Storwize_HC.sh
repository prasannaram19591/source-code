#! /bin/bash

cd /root/IBM_hc/
user='user'
pass='pass'
tstamp=`date | awk '{print $1,$2,$3,$NF,$4}' | sed 's/[ :]/-/g'`
echo "Date,Hostname,IP_Address,Total_Capacity(TB),Allocated_Capacity(TB),Free_Capacity(TB),Utilization(%),Status,Comments" > $tstamp-IBM-hc-report.csv
for ibm_array in `cat ibm_arrays.xls`
do
    array=$(echo $ibm_array | awk -F "," '{print $2}')
	ibm_hostname_chk=$(echo $ibm_array | awk -F "," '{print $1}')
    sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "lseventlog -filtervalue status=alert -delim :" | grep -v error_code > ibm_event_chk.txt
	ibm_event_chk=$(if [[ $(cat ibm_event_chk.txt | wc -l) gt "1" ]]; then echo "NOT_OK"; comments=`cat ibm_event_chk.txt | awk -F ":" '{print $NF}'`; status=Degraded; else echo "OK"; status=Healthy; fi)
    sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user"@$array "lssystem | grep physical" > ibm_capacity_chk.txt
	total_cap_unit_part=$(grep physical_capacity ibm_capacity_chk.txt | awk '{print $NF}' | grep -oE '[A-Za-z]+')
	total_cap_numeric_part=$(grep physical_capacity ibm_capacity_chk.txt | awk '{print $NF}' | grep -oE '[0-9.]+')
	if [ "$total_cap_unit_part" == "PB" ]; then
		total_cap_numeric_part=$(echo "$total_cap_numeric_part" | awk '{ printf "%.2f", $1 * 1024 }')
	fi
	free_cap_unit_part=$(grep physical_free_capacity ibm_capacity_chk.txt | awk '{print $NF}' | grep -oE '[A-Za-z]+')
	free_cap_numeric_part=$(grep physical_free_capacity ibm_capacity_chk.txt | awk '{print $NF}' | grep -oE '[0-9.]+')
	if [ "$free_cap_unit_part" == "PB" ]; then
		free_cap_numeric_part=$(echo "$free_cap_numeric_part" | awk '{ printf "%.2f", $1 * 1024 }')
	fi
	if ([ "$total_cap_unit_part" == "PB" ] && [ "$free_cap_unit_part" == "PB" ]); then
		used_capacity=$(echo "$total_cap_numeric_part - $free_cap_numeric_part" | bc)
	elif ([ "$total_cap_unit_part" == "TB" ] && [ "$free_cap_unit_part" == "TB" ]); then
		used_capacity=$(echo "$total_cap_numeric_part - $free_cap_numeric_part" | bc)
	fi
	utilization=$(echo "scale=2; $used_capacity / $total_cap_numeric_part" | bc)
	utilization_percent=$(echo "$utilization * 100" | bc)
	echo "$(date +"%B %d, %Y"),$ibm_hostname_chk,$array,$total_cap_numeric_part,$used_capacity,$free_cap_numeric_part,$utilization_percent,$status,$comments" >> $tstamp-IBM-hc-report.csv
done

#( printf '%s\n' "Hello Team,"; printf '%s\n'; printf '%s\n' "Please find the attached IBM Devices health check report."; printf '%s\n'; printf '%s\n' "Thanks and Regards,"; printf '%s\n' "XYZ Storage Team"; printf '%s\n' "abc_storage@abc.xyz.com"; ) | mailx -s 'IBM_Health_Check_Report' -a $tstamp-IBM-hc-report.csv -c abc_storage@abc.xyz.com abc_storageteam@abc.xyz.com

# Set the email IDs
sender_email="IBM-hc-report@abc.xyz.com"
reply_email="abc_storage@abc.xyz.com"
recipient_email="abc_storageteam@abc.xyz.com"

# Email forwarding
email_subject="IBM HC Report"
email_body=$(cat <<EOF
Hello Team,

Please find the attached IBM Devices health check report.

Thanks and Regards,
XYZ Storage Team
$reply_email
EOF
)

# Email forwarding command
{
  echo "$email_body"
  echo
  echo "Attached file: $tstamp-IBM-hc-report.csv"
} | mailx -s "$email_subject" -a "$tstamp-IBM-hc-report.csv" -r "$sender_email" -c "$reply_email" "$recipient_email"

rm -f *.txt *.csv
