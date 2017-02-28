#!/bin/bash

#
# usage: ./driver_cfgtx.sh [opt] [value]
# example:
#    ./driver_cfgtx.sh -p 100 -o 1 -s solo -i configtx.yaml-in -c configtx.yaml
#

function cfgHelp {
   echo "Usage: "
   echo " ./driver_cfgtx.sh [opt] [value] "
   echo "    -c: output configtx file name (required)"
   echo "    -i: input configtx file name (required)"
   echo "    -o: number of orderers (optional)"
   echo "    -p: number of peers (required)"
   echo "    -s: orderer service [solo|kafka] (optional)"
   echo " "
   exit
}

oService="solo"  # default
while getopts ":c:i:o:p:s:" opt; do
  case $opt in
    # output file
    c)
      cfgOutFile=$OPTARG
      echo "cfgOutFile:  $cfgOutFile"
      if [ -e $cfgOutFile ]; then
          rm -f $cfgOutFile
      fi
      ;;

    # input file
    i)
      inFile=$OPTARG
      echo "inFile:  $inFile"
      if [ ! -f $inFile ]; then
          echo "$inFile does not exist"
          exit
      fi
      ;;

    # number of orderers
    o)
      nOrderers=$OPTARG
      echo "nOrderers:  $nOrderers"
      ;;

    # number of peers
    p)
      nPeers=$OPTARG
      echo "nPeers: $nPeers"
      ;;

    # type of orderer service
    s)
      oService=$OPTARG
      echo "oService:  $oService"
      ;;

    # else
    \?)
      echo "Invalid option: -$OPTARG" >&2
      cfgHelp
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      cfgHelp
      ;;
  esac
done

#sanity check input vars
if [ -z ${nOrderers+x} ]; then
   echo "number of Orderers is set to 1"
   $nOrderers=1
fi

if [ -z ${nPeers+x} ]; then
   echo "number of peers is not set"
   cfgHelp
fi

if [ -z ${cfgOutFile+x} ]; then
   echo "configtx output File is not set"
   cfgHelp
fi

if [ -z ${inFile+x} ]; then
   echo "configtx input File if not set"
   cfgHelp
fi

nOrgs=$[nPeers / 2]
echo "nOrgs: $nOrgs"

#begin process
while IFS= read line
do
    #printf '%s\n' "$line"
    #t1=$(echo $line | awk '{print $1}')
    t2=$(echo $line | awk '{print $2}')
    #echo "$line"
    #echo "t1:t2=$t1:$t2"
      #Profiles
      #echo "$line" >> $cfgOutFile
      if [ "$t2" == "*Org0" ]; then
          for (( i=0; i<$nOrgs; i++ ))
          do
              echo "                - *Org$i" >> $cfgOutFile
          done


      elif [ "$t2" == "&Org0" ]; then
          for (( i=0; i<$nOrgs; i++ ))
          do
             j=$[2 * i ]
             tt="Org"$i
             echo "    - &$tt" >> $cfgOutFile
             tmp=$tt"MSP"
             echo "        Name: $tmp" >> $cfgOutFile
             echo "        ID: $tmp" >> $cfgOutFile
             tmp=examples/e2e/crypto/peer$j"/localMspConfig"
             echo "        MSPDir: $tmp" >> $cfgOutFile

             echo "" >> $cfgOutFile
             echo "        BCCSP:" >> $cfgOutFile
             echo "            Default: SW" >> $cfgOutFile
             echo "            SW:" >> $cfgOutFile
             echo "                Hash: SHA2:" >> $cfgOutFile
             echo "                Security: 256" >> $cfgOutFile
             echo "                FileKeyStore:" >> $cfgOutFile
             echo "                    KeyStore:" >> $cfgOutFile
             echo "" >> $cfgOutFile

             echo "        AnchorPeers:" >> $cfgOutFile
             echo "            - Host: peer$j" >> $cfgOutFile
             echo "            Port: 7051" >> $cfgOutFile
             echo "" >> $cfgOutFile

          done

      else
          echo "$line" >> $cfgOutFile
      fi

done < $inFile
exit

