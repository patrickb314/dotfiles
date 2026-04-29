#!/bin/bash
for i in *.pub
do
KEYNAME=`basename $i .pub`
echo $KEYNAME
lpass show --field=Private\ Key -G ${KEYNAME} > ${KEYNAME}
done
