#!/bin/bash

n=100000
i=1
echo "usernum,datediff,quantity" > data.csv
while [ $i -le $n ]
do
  echo "$RANDOM,$RANDOM,$RANDOM" >> data.csv
  i=$((i+1))
done

exit 0
