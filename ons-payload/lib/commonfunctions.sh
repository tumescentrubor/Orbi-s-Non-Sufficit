#!/bin/sh

if [ $1 ] && [ $1 = 'list_functions' ]; then
  #echo this is $0
  while read line; do
    echo $line | grep -E "^\w+\(\)" | sed -e "s/{//"
  done < $0
fi

lc() {
  while read LINE; do
    echo $LINE | tr '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]' '[abcdefghijklmnopqrstuvwxyz]'
  done
}

add_item_to_space_separated_list() {                                                                                                                                                        
  listname=$(eval echo "\$$1")                                                                                                                                                                    
  var=$2                                                                                                                                                                                     
  if ( echo $listname | grep "$var" > /dev/null ); then
    # item already in list
    echo $listname
  else
    if [ $(echo $listname | wc -m) -lt 3 ]; then                                                                                                                                               
      listname="$var"                                                                                                                                                                           
    else                                                                                                                                                                                       
      listname="$listname $var"                                                                                                                                                               
    fi                                                                                                                                                                                         
    echo $listname
  fi
}

remove_item_from_space_separated_list() {
  listname=$(eval echo "\$$1")
  var=$2
  listname=$( echo $listname | sed -e "s/$var//" -e "s/  / /" )
  echo $listname
}

urldecode() {
  echo $1 | sed 's@+@ @g;s@%@\\x@g' | xargs -0 printf "%b"
}

urlencode() {
  # urldecode <string>
  local url_encoded="${1//+/ }"
  printf '%b' "${url_encoded//%/\\x}" 
}
