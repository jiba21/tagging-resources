#!/bin/bash

# Script Function
# execute:
#             bash ec2deletetags.sh [none | archivo.txt] [FILTER] [listtag.txt] [PROFILE]

# It is mandatory to provide a ID file or a FILTER
# Inputs:
#       - %1: Archivo con ids a taguear sino existe poner "none"
#       - %2: FILTER:
#                       [ TAG:VALUE ]
#                       [ all ]
#                       [ none ]  -->   Si queremos usar el archivo de id's
#       - %3: Archive with list of the tags  -> the format list [key:value]
#       - %4: Profile
#                       [ default ]


TAG=$(echo $2 | cut -d':' -f1)
VALUE=$(echo $2 | cut -d':' -f2)
PROFILE=$4

# Ponemos en una String valores de TAGLIST a APLICAR
cat $3 | cut -d':' -f1 |  sed -e 's/^/"/g' > taglist1.txt
sed -e 's/$/"/g' taglist1.txt > taglist2.txt
declare -a deletetaglist
readarray -t deletetaglist < taglist2.txt

#Seleccionamos filtrado por TAG o por archivos de ids
if [ $TAG == "none" ]; then FILES=$(cat $1 | grep "^i")
else
  if [ $TAG == "all" ]; then
    aws ec2 describe-instances --profile $PROFILE | grep "InstanceId" | sed 's/"InstanceId": "//g' | sed 's/",//g' | sed 's/ //g' > id_ec2_tag.txt
    FILES=$(cat id_ec2_tag.txt | grep "^i")
  else
    aws ec2 describe-instances --filters "Name=tag:$TAG,Values=$VALUE" --profile $PROFILE | grep "InstanceId" | sed 's/"InstanceId": "//g' | sed 's/",//g' | sed 's/ //g' > id_ec2_tag.txt
    FILES=$(cat id_ec2_tag.txt | grep "^i")
  fi
fi

# Delete TAGS
for f in $FILES
  do
    for lt in "${deletetaglist[@]}"; do
      aws ec2 delete-tags --resources $f --tags Key="$lt" --profile $PROFILE
    done
  done

rm -f id_ec2_tag.txt tags_id.txt value_id volumes.txt taglist1.txt taglist2.txt values_id.txt
