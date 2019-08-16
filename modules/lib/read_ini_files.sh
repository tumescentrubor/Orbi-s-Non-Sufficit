#!/bin/sh

sectionlist=''

read_config_file() {
  section=''
  while read -r line; do
    if ( echo $line | grep \\\[ > /dev/null ); then
      section="$( echo $line | tr -d '[]' )"
      if [ $( echo $sectionlist | wc -m ) -lt 3 ]; then
        sectionlist=$section
      else
        sectionlist="$sectionlist $section"
      fi
    else
      varname=$( echo $line | cut -f 1 -d '=' | sed -e "s/^ //" -e "s/ $//" -e "s/ /_/g" )
      value=$( echo $line | cut -f 2 -d '=' | sed -e "s/^ //" -e "s/ $//" -e "s/ /_/g" )
      if [ $varname ]; then
        eval $section"__$varname=$value"
        tmp=$(printf $(printf $section)__$(printf $varname))
        #echo $tmp is $(eval echo "\$$tmp")
      fi
    fi
    
  done < $1

}

