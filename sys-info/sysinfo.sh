#!/bin/bash

changeUnit(){
  value=$1
  unit="B/s"

  if [ $value -gt 1000 ] && [ $value -lt 1000000 ] #KILOBAJTY ZAPISYWANIA
  then
  unit="Kb/s"
  value=$(( $value / 1000 ))

  elif [ $value -gt 1000000 ]  #MEGABAJTY ZAPISYWANIA
  then
  unit="Mb/s"
  value=`echo "scale=2;($value/1000000)" | bc -l `
  fi

  echo "$value $unit"
}
setterm -cursor off
scales=(  )
curr_writing=(  )
curr_reading=(  )
curr_loadage=(  )
iteration=0

tput cud 1
tput cuf 25
echo "SYSTEM INFO FROM DISKSTATS"
tput cud 1
tput cuf 20
echo "r-reading  w-writting l-system loadage"

tput cud 1
tput cuf 10

echo "---------------------------------------------------------------"

tput cud 1
tput sc
while [ 1 = 1 ]
do
  scaleL=0
  scaleR=0
  scaleW=0
  unityR="B/s"
  unityW="B/s"

  line1=`cat < /proc/diskstats | grep  "sda "`
  tablica1=(`echo $line1 | gawk '{print $6}'` `echo $line1 | gawk '{print $10}'`)

  sleep 1

  line2=`cat < /proc/diskstats | grep  "sda "`
  tablica2=(`echo $line2 | gawk '{print $6}'` `echo $line2 | gawk '{print $10}'`)
  loadage=`cat < /proc/loadavg | cut -c -4`
  changeR=$(( `expr ${tablica2[0]} - ${tablica1[0]}` * 512 )) #RÓŻNICA W BAJTACH
  changeW=$(( `expr ${tablica2[1]} - ${tablica1[1]}` * 512 )) #RÓŻNICA W BAJTACH


  size=${#curr_writing[@]}
  size=$(( $size  ))

  if [ $iteration -lt 4 ]
  then
    curr_loadage[$size]=$loadage
    curr_writing[$size]=$changeW
    curr_reading[$size]=$changeR

  elif [ $iteration -ge 4 ]
  then
    curr_loadage[0]=${curr_loadage[1]}
    curr_loadage[1]=${curr_loadage[2]}
    curr_loadage[2]=${curr_loadage[3]}
    curr_loadage[3]=$loadage

    curr_writing[0]=${curr_writing[1]}
    curr_writing[1]=${curr_writing[2]}
    curr_writing[2]=${curr_writing[3]}
    curr_writing[3]=$changeW

    curr_reading[0]=${curr_reading[1]}
    curr_reading[1]=${curr_reading[2]}
    curr_reading[2]=${curr_reading[3]}
    curr_reading[3]=$changeR
  fi


  sortedL=($(printf '%s\n' "${curr_loadage[@]}"|sort -n))
  sortedW=($(printf '%s\n' "${curr_writing[@]}"|sort -n))
  sortedR=($(printf '%s\n' "${curr_reading[@]}"|sort -n))
  maxR=${sortedR[-1]}
  maxW=${sortedW[-1]}
  maxL=${sortedL[-1]}

  i=0
  tput rc
  tput sc

  while [ $i -lt 4 ] #GŁÓWNA PĘTLA WYPISUJĄCA
  do

    if [ $maxW -ne 0 ]
    then
      scaleW=`echo "scale=1;(${curr_writing[$i]}/$maxW)*10" | bc -l  2> errorlog.txt`
      scaleW=${scaleW/.*}

    else
      scaleW=0
    fi

    if [ $maxR -ne 0 ]
    then
      scaleR=`echo "scale=1;(${curr_reading[$i]}/$maxR)*10" | bc -l  2> errorlog.txt`
      scaleR=${scaleR/.*}
    else
      scaleR=0
    fi

      scaleL=`echo "scale=1;(${curr_loadage[$i]}/$maxL)*10" | bc -l  2> errorlog.txt`
      scaleL=${scaleL/.*}

    if [  "${curr_reading[$i]}" != "" ]
    then

    x=11
    align=$((x - scaleR))
    toPrint=`changeUnit ${curr_reading[$i]}`

    tput sgr 0
    tput cuf 8
    printf "%-12s" "r: $toPrint"
    tput sgr 0
    printf "%${x}s "
    tput cub 11
    tput setab 4
    printf "%${scaleR}s"

    tput cuf $align
    tput sgr 0
    align=$((x - scaleW))
    toPrint=`changeUnit ${curr_writing[$i]}`

    printf "%-13s" " w: $toPrint"
    tput sgr 0
    printf "%${x}s "
    tput cub 11
    tput setab 2
    printf "%${scaleW}s"
    tput sgr 0
    tput cuf $align

    printf "%-7s" " l: ${curr_loadage[$i]} "
    tput sgr 0
    printf "%${x}s "
    tput cub 11
    tput setab 0
    printf "%${scaleL}s\n"
    tput sgr 0
    tput cud 1
    fi

    i=$(( $i + 1 ))
  done
  iteration=$(( iteration + 1 ))
done
