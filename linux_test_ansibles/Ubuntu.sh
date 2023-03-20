#! /bin/bash -x

ls -l /root > version_info.txt
df -hT >> version_info.txt
