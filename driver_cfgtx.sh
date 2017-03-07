#!/bin/bash

#
# usage: ./driver_cfgtx.sh [opt] [value]
# example:
#    ./driver_cfgtx.sh -o 2 -p 3 -r 2 -h SHA2 -s 256 -t kafka -b /mnt/crypto-config -x 9.47.152.126 -y 9.47.152.124 -z 20021
#

HostIP1="0.0.0.0"
HostIP2="0.0.0.0"
HostPort=7050

function cfgHelp {
   echo "Usage: "
   echo " ./driver_cfgtx.sh [opt] [value] "
   echo "    -o: number of orderers (optional)"
   echo "    -p: number of peers per organiztion (required)"
   echo "    -h: hash type"
   echo "    -r: number of organization (required)"
   echo "    -s: security service type"
   echo "    -t: orderer service [solo|kafka] (optional)"
   echo "    -f: profile name"
   echo "    -b: MSP directory, default=/mnt/crypto-config"
   echo "    -x: host ip 1, default=0.0.0.0"
   echo "    -y: host ip 2, default=0.0.0.0"
   echo "    -z: host port, default=7050"
   echo " "
   echo "Example:"
   echo " ./driver_cfgtx.sh -o 1 -p 2 -r 6 -h SHA2 -s 256 -t kafka -b /mnt/crypto-config -x 9.47.152.126 -y 9.47.152.124 -z 20021"
   exit
}

CWD=$PWD
#default vars
inFile=$CWD"/configtx.yaml-in"
cfgOutFile=$CWD"/configtx.yml"

nOrderer=1
ordServType="solo"
SecTypenOrderer=1
peersPerOrg=1
ordServType="solo"
hashType="SHA2"
SecType="256"
PROFILE_STRING="testOrg"
MSPBaseDir="/mnt/crypto-config/"

while getopts ":o:p:s:h:r:t:f:b:x:y:z:" opt; do
  case $opt in
    # number of orderers
    o)
      nOrderer=$OPTARG
      echo "nOrderer:  $nOrderer"
      ;;

    # number of peers
    p)
      peersPerOrg=$OPTARG
      echo "peersPerOrg: $peersPerOrg"
      ;;

    # type of orderer service
    h)
      hashType=$OPTARG
      echo "hashType:  $hashType"
      ;;

    r)
      nOrg=$OPTARG
      echo "nOrg:  $nOrg"
      ;;

    s)
      SecType=$OPTARG
      echo "SecType:  $SecType"
      ;;

    t)
      ordServType=$OPTARG
      echo "ordServType:  $ordServType"
      ;;

    f)
      PROFILE_STRING=$OPTARG
      echo "PROFILE_STRING:  $PROFILE_STRING"
      ;;

    b)
      MSPBaseDir=$OPTARG
      echo "MSPBaseDir:  $MSPBaseDir"
      ;;

    x)
      HostIP1=$OPTARG
      echo "HostIP1:  $HostIP1"
      ;;

    y)
      HostIP2=$OPTARG
      echo "HostIP2:  $HostIP2"
      ;;

    z)
      HostPort=$OPTARG
      echo "HostPort:  $HostPort"
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


echo "nOrderer=$nOrderer, peersPerOrg=$peersPerOrg, ordServType=$ordServType, nOrg=$nOrg, hashType=$hashType, SecType=$SecType"
echo "MSPBaseDir=$MSPBaseDir"
echo "Host IP=$HostIP1, $HostIP2, Port=$HostPort"
echo "inFile=$inFile"
echo "cfgOutFile=$cfgOutFile"

#remove existing cfgOutFile
rm -f $cfgOutFile

#begin process
while IFS= read line
do
    t1=$(echo $line | awk '{print $1}')
    t2=$(echo $line | awk '{print $2}')
    #echo "$line"
    #echo "t1:t2=$t1:$t2"
      #Profiles
      if [ "$t2" == "*Org0" ]; then
          for (( i=1; i<=$nOrg; i++ ))
          do
              echo "                - *PeerOrg$i" >> $cfgOutFile
          done

      elif [ "$t1" == "OrdererType:" ]; then
          echo "    $t1 $ordServType" >> $cfgOutFile

      elif [ "$t1" == "&ProfileString" ]; then
          echo "    $PROFILE_STRING:" >> $cfgOutFile

      elif [ "$t2" == "&OrdererOrg" ]; then
          echo "OrdererOrg ... "
          for (( i=1; i<=$nOrderer; i++ ))
          do
             j=$[ peersPerOrg * ( i - 1 ) ]
             tmp="OrdererOrg"$i
             tt="Orderer"$i"MSP"
             echo "    - &$tmp" >> $cfgOutFile
             echo "        Name: $tmp" >> $cfgOutFile
             echo "        ID: $tt" >> $cfgOutFile
             ordDir=$MSPBaseDir"/ordererOrganizations/ordererOrg"$i"/orderers/ordererOrg"$i"orderer"$i
             echo "        MSPDir: $ordDir" >> $cfgOutFile

             echo "" >> $cfgOutFile
             echo "        BCCSP:" >> $cfgOutFile
             echo "            Default: SW" >> $cfgOutFile
             echo "            SW:" >> $cfgOutFile
             echo "                Hash: $hashType" >> $cfgOutFile
             echo "                Security: $SecType" >> $cfgOutFile
             echo "                FileKeyStore:" >> $cfgOutFile
             echo "                    KeyStore:" >> $cfgOutFile
             echo "" >> $cfgOutFile

          done
      elif [ "$t2" == "&Org0" ]; then
          for (( i=1; i<=$nOrg; i++ ))
          do
             j=$[ peersPerOrg * ( i - 1 ) ]
             tt="PeerOrg"$i
             echo "    - &$tt" >> $cfgOutFile
             tmp="Peer"$i"MSP"
             echo "        Name: $tt" >> $cfgOutFile
             echo "        ID: $tmp" >> $cfgOutFile
             peerDir=$MSPBaseDir"/peerOrganizations/peerOrg"$i"/msp"
             echo "        MSPDir: $peerDir" >> $cfgOutFile

             echo "" >> $cfgOutFile
             echo "        BCCSP:" >> $cfgOutFile
             echo "            Default: SW" >> $cfgOutFile
             echo "            SW:" >> $cfgOutFile
             echo "                Hash: $hashType" >> $cfgOutFile
             echo "                Security: $SecType" >> $cfgOutFile
             echo "                FileKeyStore:" >> $cfgOutFile
             echo "                    KeyStore:" >> $cfgOutFile
             echo "" >> $cfgOutFile

             tmpPort=$[ HostPort + peersPerOrg * ( i - 1 ) ]
             echo "        AnchorPeers:" >> $cfgOutFile
             echo "            - Host: $HostIP1" >> $cfgOutFile
             echo "              Port: $tmpPort" >> $cfgOutFile
             echo "            - Host: $HostIP2" >> $cfgOutFile
             echo "              Port: $tmpPort" >> $cfgOutFile
             echo "" >> $cfgOutFile

          done

      else
          echo "$line" >> $cfgOutFile
      fi

done < "$inFile"

exit

