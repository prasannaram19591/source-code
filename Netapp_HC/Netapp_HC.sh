#!/bin/bash

# execute the command and capture its output
output=`cat storage_chk.txt | tail -n +3` 

# iterate over the lines of the output and check if all components are ok
while read line; do
    # extract the component name and status from the line
    component=$(echo $line | awk '{print $1}')
    status=$(echo $line | awk '{print $2}')
    echo $component $status 
    # check if the status is not ok
    if [ "$status" != "ok" ]; then
        echo "Component $component is not healthy"
        sys_chk_status=NOT_OK
    else
	sys_chk_status=OK
    fi
done <<< "$output"
echo $sys_chk_status

