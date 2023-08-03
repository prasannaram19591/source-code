#! /bin/bash

grep -E 'AM|PM' iostat.txt | awk '{print $2}' > tstamp.txt
grep sda iostat.txt | awk '{print $2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16}' | sed 's/ /,/g' > sda.txt
paste tstamp.txt sda.txt | awk '{print $1,$2}' | sed 's/ /,/g' > sda.csv
sed -i '1i Timestamp,r/s,w/s,rkB/s,wkB/s,rrqm/s,wrqm/s,%rrqm,%wrqm,r_await,w_await,aqu-sz,rareq-sz,wareq-sz,svctm,%util' sda.csv
