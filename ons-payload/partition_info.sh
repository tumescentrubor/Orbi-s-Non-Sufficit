#!/bin/bash
dev=$(mount | grep device_tables | cut -f 3 -d '/' | cut -f 1 -d ' ' | sed -e "s/p[0-9]\+$//" )
END=$(ls -1 /dev/$dev* | wc -l)
COUNT=1;
echo -ne [
for i in /dev/$dev*; do
  echo -ne { \"device\":\"$i\", \"size\":\"$( echo `blockdev --getsize64 $i`/1024/1024 | bc -l | sed -e "s/[0-9]\{18\}$//")\",
  echo -ne  \"options\":\"`mount | grep "$i " | cut -f 2-3 -d ' '`\", \"blkid\":\"`blkid -p $i | sed -e "s/\"//g"`\" }
  if [ $COUNT -lt $END ]; then
    echo -ne ,
    COUNT=$(($COUNT+1))
  fi
done
echo ]
