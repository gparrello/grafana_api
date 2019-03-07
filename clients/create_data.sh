#!/bin/bash

n=100000
i=1
echo "submission_id,usernum,datediff,quantity" > data.csv
while [ $i -le $n ]
do
  echo "$RANDOM,$RANDOM,$RANDOM,$RANDOM" >> data.csv
  i=$((i+1))
done

exit 0
