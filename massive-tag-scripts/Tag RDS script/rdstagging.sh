#!/bin/bash

# Script Function
# execute:
#             bash rdstagging.sh [none | archivo.txt] [FILTER] [listtag.txt] [PROFILE]

# It is mandatory to provide a ID file or a FILTER
# Inputs:
#       - %1: Archivo con ids a taguear sino existe poner "none"
#       - %2: FILTER:
#                       [ TAG:VALUE ]
#                       [ all ]
#                       [ none ]  -->   Si queremos usar archivo de nombre bbdd
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
readarray -t applytaglist < taglist2.txt

# Ponemos en una String valores de VALORES a APLICAR
cat $3 | cut -d':' -f2 |  sed -e 's/^/"/g' > taglist1.txt
sed -e 's/$/"/g' taglist1.txt > taglist2.txt
declare -a applyvaluelist
mapfile -t applyvaluelist < taglist2.txt
echo "TAG LIST A APLICAR: ${applytaglist[@]} VALORES: ${applyvaluelist[@]}"

#Seleccionamos filtrado por TAG o por archivos de ids
if [ $TAG == "none" ]; then FILES=$(cat $1 | grep "^i")
else
  if [ $TAG == "all" ]; then
    aws rds describe-db-instances --profile $PROFILE |grep "DBInstanceIdentifier" |grep -v 'ReadReplicaDBInstanceIdentifiers' | sed 's/",//g' | sed 's/ //g'| sed 's/"//g' | sed 's/DBInstanceIdentifier://g' > id_rds_tag.txt
    FILES=$(cat id_rds_tag.txt | grep "^")
  else
    aws rds describe-db-instances --filters "Name=tag:$TAG,Values=$VALUE" --profile $PROFILE |grep "DBInstanceIdentifier" | grep -v 'ReadReplicaDBInstanceIdentifiers'| sed 's/",//g' | sed 's/ //g'| sed 's/"//g' | sed 's/DBInstanceIdentifier://g'   > id_rds_tag.txt
    FILES=$(cat id_rds_tag.txt | grep "^")
  fi
fi

get_account_id(){
  aws ec2 describe-security-groups --group-names 'Default' --query 'SecurityGroups[0].OwnerId' --output text --profile "$PROFILE"
}
ACCOUNT_ID=$(get_account_id)

# Tageamos el recurso
for f in $FILES
  do
    # Cogemos los TAGS:VALOR de la instancia y las ponemos en una string por separado
    aws rds list-tags-for-resource --resource-name arn:aws:rds:eu-west-1:$ACCOUNT_ID:db:$f --profile "$PROFILE" --output text | grep TAGLIST | cut -f 2 | sed 's/ //g'| sed 's/"//g' > tags_id.txt
    declare -a instancetaglist
    mapfile -t instancetaglist < tags_id.txt
    aws rds list-tags-for-resource --resource-name arn:aws:rds:eu-west-1:$ACCOUNT_ID:db:$f --profile "$PROFILE" --output text | grep TAGLIST | cut -f 3 | sed 's/ //g'| sed 's/"//g' > values_id.txt
    declare -a instancevaluelist
    mapfile -t instancevaluelist < values_id.txt
    echo "TAG LIST de la RDS:${instancetaglist[@]} VALORES: ${instancevaluelist[@]}"

    v2=0
    v3=0
    v4=0
    for lt in "${applytaglist[@]}"; do
    skip=
      for at in "${instancetaglist[@]}"; do
        if [[ $lt == $at ]]; then
          av=${instancevaluelist[$v3]}
          if [[ $av == '""' ]]; then
            lv=${applyvaluelist[$v2]}
            echo "El valor del Tag es nulo, taggeamos con el valot de la lista a aplicar:"
            echo "TAGEO Con TAG $at y valor $lv "
            aws rds add-tags-to-resource --resource-name arn:aws:rds:eu-west-1:$ACCOUNT_ID:db:$f --tags Key="$lt",Value="$lv" --profile $PROFILE
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
      [[ -n $skip ]] || aws rds add-tags-to-resource --resource-name arn:aws:rds:eu-west-1:$ACCOUNT_ID:db:$f --tags Key="$lt",Value="$lval" --profile $PROFILE
    v2=$(($v2+1))
    done
    echo "La RDS $f queda con los siguientes TAG:VALUE"
    aws rds list-tags-for-resource --resource-name arn:aws:rds:eu-west-1:$ACCOUNT_ID:db:$f --profile $PROFILE --output text | grep TAGLIST 
 done
rm -f id_rds_tag.txt tags_id.txt value_id volumes.txt taglist1.txt taglist2.txt values_id.txt