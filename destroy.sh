#! /bin/bash

while getopts n:c: flag
do
    case "${flag}" in
        n) NAME=${OPTARG};;
        c) CODE=${OPTARG};;
    esac
done

if [ "$NAME" == "" ] || [ "$CODE" == "" ]; then
 echo "Syntax: $0 -n <name> -c <unique code>"
 exit 1;
elif [[ $CODE =~ [^a-zA-Z0-9] ]]; then
 echo "Unique code must contain ONLY letters and numbers. No special characters."
 echo "Syntax: $0 -n <name> -c <unique code>"
 exit 1;
fi

SUFFIX=reddog-$CODE
GROUP=${NAME}-${SUFFIX}
SECONDS=0

read -p "WARNING: This will delete all Azure resources in resource group $GROUP. Are you sure? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

read -p "Would you like the command to wait for operation to complete (otherwise deletion will continue in the background)? (Y/N):" linger


# delete resource group
if [[ $linger == [yY] || $linger == [yY][eE][sS] ]]; then
  echo "Start time: $(date)"
  az group delete --name $GROUP --yes

  duration=$SECONDS
  echo "End time: $(date)"
  echo "$(($duration / 3600)) hours, $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
else
  az group delete --name $GROUP --yes --no-wait
fi
