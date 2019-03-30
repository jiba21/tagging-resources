#!/bin/bash

# Script Function ELB
# execute:
#             bash snapshotstagging.sh [ID] [FILTER] [listtag.txt] [PROFILE]

# It is mandatory to provide a ID file or a FILTER
# Inputs:
#       - %1: Archive ID to tagging - in case no exist write none
#       - %2: FILTER:
#                       [ TAG:VALUE ]
#                       [ all ]
#                       [ none ]  -->   Si queremos usar el filtro
#       - %3: Archive with list of the tags  -> the format list [key:value]
#       - %4: Profile Holcim
#                       [ default (shared) ]
#                       [ non-production ]
#                       [ production ]
#                       [ sandbox ]

TAG=$(echo $2 | cut -d':' -f1)
VALUE=$(echo $2 | cut -d':' -f2)
PROFILE=$4

# TRATAMIENTO ARCHIVO DE LISTA DE TAGS
# Ponemos en una string las KEY de archivo TAGLIST
cat $3 | cut -d':' -f1 | sed -e 's/^/"/g' > taglist1.txt
sed -e 's/$/"/g' taglist1.txt > taglist2.txt
declare -a applytaglist
mapfile -t applytaglist < taglist2.txt

# Ponemos en una string los VALORES de TAGLIST
cat $3 | cut -d':' -f2 |  sed -e 's/^/"/g' > taglist1.txt
sed -e 's/$/"/g' taglist1.txt > taglist2.txt
declare -a applyvaluelist
mapfile -t applyvaluelist < taglist2.txt

echo "TAG LIST A APLICAR: ${applytaglist[@]} VALORES: ${applyvaluelist[@]}"

# CRITERIO PARA TAGGUEAR
# seleccionamos filtrado por TAG o por archivos de ids
#                       [ TAG:VALUE ]  -->
#                       [ Owner:Value ]   -->  ALL
#                       [ none ]  -->   Si queremos usar el filtro

# Obtenemos todos los nombres de los ELB
name_elb=$(aws elb describe-load-balancers --profile $PROFILE | grep "LoadBalancerName" | sed 's/"LoadBalancerName": "//g' | sed 's/",//g' | sed 's/ //g'| sed 's/"//g')

#Seleccionamos filtrado por TAG o por archivos de ids
# El TAG    /    Archivos de ids    /    se aplicara a todos los del mismo owner.
if [ $TAG == "none" ]; then FILES=$(cat $1)
else
  if [ $TAG == "all" ]; then
  # Obtenemos todos los nombres de los ELB
    aws elb describe-load-balancers --profile $PROFILE | grep "LoadBalancerName" | sed 's/"LoadBalancerName": "//g' | sed 's/",//g' | sed 's/ //g'| sed 's/"//g' > elb_tag.txt
    FILES=$(cat elb_tag.txt)
  else
    for n in $name_elb; do
        aws elb describe-tags --load-balancer-name $n --profile $PROFILE --output text | grep "$TAG" | grep "$VALUE"
        if [ $? = 0 ]; then echo $n > elb_tag.txt; fi
      done
      FILES=$(cat elb_tag.txt)
  fi
fi

# Tageamos los ELB
for f in $FILES
  do
    # Cogemos los TAGS:VALOR del ELB y las ponemos en una string por separado
    aws elb describe-tags --load-balancer-name $f --profile $PROFILE --output text | grep TAGS | cut -f 2 | sed -e 's/^/"/g' | sed -e 's/$/"/g' > tags_id.txt
    declare -a elbtaglist
    mapfile -t elbtaglist < tags_id.txt
    aws elb describe-tags --load-balancer-name $f --profile $PROFILE --output text | grep TAGS | cut -f 3 | sed -e 's/^/"/g' | sed -e 's/$/"/g' > values_id.txt
    declare -a elbvaluelist
    mapfile -t elbvaluelist < values_id.txt
    echo "TAG LIST del ELB:${elbtaglist[@]} VALORES: ${elbvaluelist[@]}"

    v2=0
    v3=0
    v4=0
    for lt in "${applytaglist[@]}"; do
    skip=
      for at in "${elbtaglist[@]}"; do
        if [[ $lt == $at ]]; then
          av=${elbvaluelist[$v3]}
          if [[ $av == '""' ]]; then
            lv=${applyvaluelist[$v2]}
            echo "El valor del Tag es nulo, taggeamos con el valot de la lista a aplicar:"
            echo "TAGEO Con TAG $at y valor $lv "
            aws elb add-tags --load-balancer-name $f --tags Key="$lt",Value="$lv" --profile $PROFILE
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
      [[ -n $skip ]] || aws elb add-tags --load-balancer-name $f --tags Key="$lt",Value="$lval" --profile $PROFILE
    v2=$(($v2+1))
    done
    echo "El ELB $f queda con los siguientes TAG:VALUE"
    aws elb describe-tags --load-balancer-name $f --profile $PROFILE --output text | grep TAGS
done
rm -f tags_id.txt value_id.txt taglist1.txt taglist2.txt values_id.txt