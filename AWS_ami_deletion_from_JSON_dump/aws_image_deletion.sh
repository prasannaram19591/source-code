#!/bin/bash

read -p "Enter the json file path: " json_path
read -p "Enter how many days to retain: " retention_days

rm -f expired_images.csv

cat $json_path | grep name > name.csv
cat $json_path | grep creationTimestamp > time.csv

paste -d':' name.csv time.csv > final.csv
cat final.csv | awk '{print $2, $4}' | sed 's/"//g' | sed 's/ //g' > parse.csv

current_timestamp_in_secs=`date +%s`
for k in `cat parse.csv`
do
  image_timestamp=`echo $k | awk -F ":" '{print $2}' | awk -F "T" '{print $1}'`
  image_timestamp_in_secs=`date --date $image_timestamp +%s`
  time_diff_in_secs=`expr $current_timestamp_in_secs - $image_timestamp_in_secs`
  time_diff_in_days=`expr $time_diff_in_secs / 86400`
  if [ $time_diff_in_days -ge $retention_days ]
  then
      echo $k | awk -F ":" '{print $1}' | sed 's/,//g' >> expired_images.csv
  fi
done

echo "The images that needs to be deleted which are older than $retention_days days are"
if [ -f expired_images.csv ]
then
    cat expired_images.csv 
    else
    echo "There are no images found to be deleted which are older than $retention_days days"
fi
