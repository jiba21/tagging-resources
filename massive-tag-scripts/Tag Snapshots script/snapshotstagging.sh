#!/bin/bash

# Script Function
# execute:
#             bash snnapshotstagging.sh [none | archivo.txt] [FILTER] [listtag.txt] [PROFILE]

# It is mandatory to provide a ID file or a FILTER
# Inputs:
#       - %1: Archivo con ids a taguear sino existe poner "none"
#       - %2: FILTER:
#                       [ TAG:VALUE ]
#                       [ all ]
#                       [ none ]  -->   Si queremos usar el archivo de id's de volumenes
#       - %3: Archive with list of the tags  -> the format list [key:value]
#       - %4: Profile 
#                       [ default ]

TAG=$(echo $2 | cut -d':' -f1)
VALUE=$(echo $2 | cut -d':' -f2)
PROFILE=$4

# Ponemos en una String valores de TAGLIST a APLICAR
cat $3 | cut -d':' -f1 |  sed -e 's/^/"/g' > taglist1.txt
sed -e 's/$/"/g' taglist1.txt > taglist2.txt
declare -a applytaglist
mapfile -t applytaglist < taglist2.txt

# Ponemos en una String valores de VALORES a APLICAR
cat $3 | cut -d':' -f2 |  sed -e 's/^/"/g' > taglist1.txt
sed -e 's/$/"/g' taglist1.txt > taglist2.txt
declare -a applyvaluelist
mapfile -t applyvaluelist < taglist2.txt
echo "TAG LIST A APLICAR: ${applytaglist[@]} VALORES: ${applyvaluelist[@]}"

#Seleccionamos filtrado por TAG o por archivos de ids
# El TAG    /    Archivos de ids    /    se aplicara a todas.
if [ $TAG == "none" ]; then FILES=$(cat $1 | grep "^snap")
else
  if [ $TAG == "all" ]; then
    aws ec2 describe-snapshots --profile $PROFILE | grep "SnapshotId" | sed 's/"SnapshotId": "//g' | sed 's/",//g' | sed 's/ //g' | sed 's/.$//g'  > id_snap_tag.txt
    FILES=$(cat id_snap_tag.txt | grep "^snap")
  else
    aws ec2 describe-snapshots --filters "Name=tag:$TAG,Values=$VALUE" --profile $PROFILE | grep "SnapshotId" | sed 's/"SnapshotId": "//g' | sed 's/",//g' | sed 's/ //g' | sed 's/.$//g' > id_snap_tag.txt
    FILES=$(cat id_snap_tag.txt | grep "^snap")
  fi
fi

# Tageamos el recurso
for f in $FILES
  do
    # Cogemos los TAGS:VALOR de la instancia y las ponemos en una string por separado
    aws ec2 describe-snapshots --snapshot-ids $f --profile $PROFILE --output text | grep TAGS | cut -f 2 | sed -e 's/^/"/g' | sed -e 's/$/"/g' > tags_id.txt
    declare -a snaptaglist
    mapfile -t snaptaglist < tags_id.txt
    aws ec2 describe-snapshots --snapshot-ids $f --profile $PROFILE --output text | grep TAGS | cut -f 3 | sed -e 's/^/"/g' | sed -e 's/$/"/g' > values_id.txt
    declare -a snapvaluelist
    mapfile -t snapvaluelist < values_id.txt
    echo "TAG LIST del snapshot:${snaptaglist[@]} VALORES: ${snapvaluelist[@]}"

    v2=0
    v3=0
    v4=0
    for lt in "${applytaglist[@]}"; do
    skip=
      for at in "${snaptaglist[@]}"; do
        if [[ $lt == $at ]]; then
          av=${snapvaluelist[$v3]}
          if [[ $av == '""' ]]; then
            lv=${applyvaluelist[$v2]}
            echo "El valor del Tag es nulo, taggeamos con el valot de la lista a aplicar:"
            echo "TAGEO Con TAG $at y valor $lv "
            aws ec2 create-tags --resources $f --tags Key="$lt",Value="$lv" --profile $PROFILE
            skip=1
            break;
          else
            skip=1
            break;
          fi
        fi
        v3=$(($v3+1))
      done
    v3=0
    lval=${applyvaluelist[$v2]}
      [[ -n $skip ]] || aws ec2 create-tags --resources $f --tags Key="$lt",Value="$lval" --profile $PROFILE
    v2=$(($v2+1))
    done
    echo "El snapshot $f queda con los siguientes TAG:VALUE"
    aws ec2 describe-snapshots --snapshot-ids $f --profile $PROFILE --output text | grep TAGS
 done
rm -f id_snap_tag.txt tags_id.txt value_id volumes.txt taglist1.txt taglist2.txt values_id.txt
