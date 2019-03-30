#!/bin/bash
# script function
# execute:  bash amitagging.sh {none/archivo.txt} {KEY:VALUE/none/Owner:Value} listtag.txt PROFILE
# It is mandatory to provide a string for project name (&1) or a list of amis (&2)
# Inputs:
#  - %1: Archive IDs tagging - in case no exist write none
#  - %2: Project Name - in case no exist write none  (TAG:VALUE o Owner:Value)
#  - %3: Archive with list tags ami -> the format list (key:value)
#  - %4: Profile 

#TAG=$(echo $2 | cut -d':' -f1)
#VALUE=$(echo $2 | cut -d':' -f2)
PROFILE=$4
BTAGGING=$2 # list of name buckets

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

#Seleccionamos Buckets  segun el siguiente criterio:
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

# Tagueamos el recurso
for f in $FILES
  do
    # Cogemos los TAGS:VALOR del bucket y las ponemos en una string por separado
    aws s3api get-bucket-tagging --bucket $f --profile $PROFILE --output text | grep TAGS | cut -f 2 | sed -e 's/^/"/g' | sed -e 's/$/"/g' > tags_id.txt
    declare -a buckettaglist
    mapfile -t buckettaglist < tags_id.txt
    aws s3api get-bucket-tagging --bucket $f --profile $PROFILE --output text | grep TAGS | cut -f 3 | sed -e 's/^/"/g' | sed -e 's/$/"/g' > values_id.txt
    declare -a bucketvaluelist
    mapfile -t bucketvaluelist < values_id.txt

    v2=0
    v3=0
    v4=0
    for lt in "${applytaglist[@]}"; do
    skip=
      for at in "${buckettaglist[@]}"; do
        if [[ $lt == $at ]]; then
          av=${bucketvaluelist[$v3]}
          if [[ $av == '""' ]]; then
            lv=${applyvaluelist[$v2]}
            echo "El valor del Tag es nulo, taggeamos con el valot de la lista a aplicar:"
            echo "TAGEO Con TAG $at y valor $lv "
            kv={Key="$lt",Value="$lv"}
            aws s3api put-bucket-tagging --bucket $f --tagging 'TagSet=['$kv'}]' --profile $PROFILE
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
      [[ -n $skip ]] || kv={Key="$lt",Value="$lval"} || aws s3api put-bucket-tagging --bucket $f --tagging 'TagSet=['$kv'}]' --profile $PROFILE 
    v2=$(($v2+1))
    done
 done
rm -f id_ami_tag.txt tags_id.txt value_id taglist1.txt taglist2.txt values_id.txt
