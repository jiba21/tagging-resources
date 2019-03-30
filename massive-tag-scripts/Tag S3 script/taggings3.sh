#!/bin/bash

#### ESTES SCRIPT TAGEA RECURSOS DE S3 ELIMINANDO LOS TAGS YA EXISTENTES EN EL BUCKET ######
# Funcionamiento scrip
# bash s3tagging.sh {Project} {lista_buckets.txt} taglist.json PROFILE
# dos entradas:
#     > $1 Project name  --> if don't exist put none
#     > $2 Achive with the names of buckets to tag, if don't exist list put none
#     > $3 Archive JSON with list tag
#     > $4 Name client profile Profile

PROJECT=$1
BTAGGING=$2 # list of name buckets
PROFILE=$4
TAGLIST=$(cat $3)

# si no tenemos una lista de buckets, filtramos por proyecto
if [ $BTAGGING == "none" ];
then
  # Nombre de los buckets, que despues se filtaran por proyecto
  name=$(aws s3api list-buckets --query 'Buckets[].Name' --output text --profile $PROFILE)
  for n in $name
    do
      aws s3api get-bucket-tagging --bucket $n --profile=$PROFILE --output text | grep "Project" | grep "$PROJECT"
      if [ $? = 0 ];
        then echo $n > s3totag.txt
      fi
    done
    FILE=$(cat s3totag.txt) # buckets a tagguear
else
# si tenemos lista de nombre de buckets los ponemos para taguear
  FILE=$(cat $BTAGGING)
fi

#en kv tenemos el key y el valor a poner en el tag
for b in $FILE
  do
    aws s3api put-bucket-tagging --bucket $b --tagging file://taglist.json --profile $PROFILE
  done
