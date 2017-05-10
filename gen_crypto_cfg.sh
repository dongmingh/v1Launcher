#!/bin/bash

#
# usage: ./driver_crypto.sh [opt] [value]
# fabric coomit: f3c61e6cc3b04915081b15bbed000b377b53c4c1
#

function printHelp {
   echo "Usage: "
   echo " ./driver_crypto.sh [opt] [value] "
   echo "    -o: number of orderers, default=1"
   echo "    -p: number of peers per organization, default=1"
   echo "    -r: number of organization, default=1"
   echo " "
   echo "Example:"
   echo " ./driver_crypto.sh -o 1 -p 2 -r 2"
   exit
}

CWD=$PWD
#default vars
cfgOutFile=$CWD"/crypto-config.yaml"

#default values
nOrderer=1
peersPerOrg=1
nOrg=1

while getopts ":o:p:r:" opt; do
  case $opt in
    # number of orderers
    o)
      nOrderer=$OPTARG
      echo "nOrderer:  $nOrderer"
      ;;

    # number of peers per org
    p)
      peersPerOrg=$OPTARG
      echo "peersPerOrg: $peersPerOrg"
      ;;

    # number of orgs
    r)
      nOrg=$OPTARG
      echo "nOrg:  $nOrg"
      ;;

    # else
    \?)
      echo "Invalid option: -$OPTARG" >&2
      printHelp
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      printHelp
      ;;
  esac
done


echo "nOrderer=$nOrderer, peersPerOrg=$peersPerOrg, nOrg=$nOrg"
echo "cfgOutFile=$cfgOutFile"

# rm cfgOutFile
rm -f $cfgOutFile

#begin process
          echo "OrdererOrgs:" >> $cfgOutFile
          for (( i=1; i<=$nOrderer; i++  ))
          do
              echo "    - Name: OrdererOrg$i" >> $cfgOutFile
              tt=orderer$i".example.com"
              echo "      Domain: $tt" >> $cfgOutFile
              echo "      Specs:" >> $cfgOutFile
              echo "        - Hostname: orderer$i" >> $cfgOutFile
          done

          echo "PeerOrgs:" >> $cfgOutFile
          for (( i=1; i<=$nOrg; i++  ))
          do
              echo "    - Name: PeerOrg$i" >> $cfgOutFile
              tt=org$i".example.com"
              echo "      Domain: $tt" >> $cfgOutFile
              echo "      Template:" >> $cfgOutFile
              echo "        Count: $peersPerOrg" >> $cfgOutFile
              echo "      Users:" >> $cfgOutFile
              echo "        Count: 1" >> $cfgOutFile
          done
exit

