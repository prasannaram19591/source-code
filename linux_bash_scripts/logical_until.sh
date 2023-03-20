  
#! /bin/bash

until ([ -n "$1" ] && [ -n "$2" ])
do
  echo Aruguments are not passed properly..
  exit 1
done
echo Arguments are passed properly..
