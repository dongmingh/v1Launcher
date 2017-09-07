#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

#
# usage: ./gen_network.sh [opt] [value]
#


function printHelp {
   echo "Usage: "
   echo " ./gen_network.sh [opt] [value] "
   echo "    network variables"
   echo "       -a: action [create|add] "
   echo "       -p: number of peers per organization"
   echo "       -o: number of orderers "
   echo "       -k: number of brokers "
   echo "       -r: number of organiztions "
   echo "       -S: TLS base directory "
   echo "       -x: number of ca "
   echo "       -F: local MSP base directory, default=$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config"
   echo "       -G: src MSP base directory, default=/opt/hyperledger/fabric/msp/crypto-config"
   echo " "
   echo "    peer environment variables"
   echo "       -l: core logging level [(default = not set)|CRITICAL|ERROR|WARNING|NOTICE|INFO|DEBUG]"
   echo "       -d: core ledger state DB [goleveldb|couchdb] "
   echo " "
   echo "    orderer environment variables"
   echo "       -b: batch size [10|msgs in batch/block]"
   echo "       -t: orderer type [solo|kafka] "
   echo "       -c: batch timeout [10s|max secs before send an unfilled batch] "
   echo " "
   echo "Example:"
   echo "   ./gen_network.sh -a create -x 2 -p 2 -r 2 -o 1 -k 1 -z 1 -t kafka -d goleveldb -F /root/gopath/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config -G /opt/hyperledger/fabric/msp/crypto-config "
   echo "   ./gen_network.sh -a create -x 2 -p 2 -r 2 -o 1 -k 1 -z 1 -t kafka -d goleveldb -F /root/gopath/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config -G /opt/hyperledger/fabric/msp/crypto-config -S /root/gopath/src/github.com/hyperledger/fabric-sdk-node/test/fixtures/tls "
   echo " "
   exit
}

#init var
nBroker=0
nPeerPerOrg=1
MSPDIR="$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config"
SRCMSPDIR="/opt/hyperledger/fabric/msp/crypto-config"

while getopts ":x:z:l:d:b:c:t:a:o:k:p:r:F:G:S:C:" opt; do
  case $opt in
    # peer environment options
    S)
      TLSDIR=$OPTARG
      export TLSDIR=$TLSDIR
      echo "TLSDIR: $TLSDIR"
      ;;
    x)
      nCA=$OPTARG
      echo "number of CA: $nCA"
      ;;
    l)
      CORE_LOGGING_LEVEL=$OPTARG
      export CORE_LOGGING_LEVEL=$CORE_LOGGING_LEVEL
      echo "CORE_LOGGING_LEVEL: $CORE_LOGGING_LEVEL"
      ;;
    d)
      db=$OPTARG
      echo "ledger state database type: $db"
      ;;

    # orderer environment options
    b)
      CONFIGTX_ORDERER_BATCHSIZE_MAXMESSAGECOUNT=$OPTARG
      export CONFIGTX_ORDERER_BATCHSIZE_MAXMESSAGECOUNT=$CONFIGTX_ORDERER_BATCHSIZE_MAXMESSAGECOUNT
      echo "CONFIGTX_ORDERER_BATCHSIZE_MAXMESSAGECOUNT: $CONFIGTX_ORDERER_BATCHSIZE_MAXMESSAGECOUNT"
      ;;
    c)
      CONFIGTX_ORDERER_BATCHTIMEOUT=$OPTARG
      export CONFIGTX_ORDERER_BATCHTIMEOUT=$CONFIGTX_ORDERER_BATCHTIMEOUT
      echo "CONFIGTX_ORDERER_BATCHTIMEOUT: $CONFIGTX_ORDERER_BATCHTIMEOUT"
      ;;
    F)
      SRCMSPDIR=$OPTARG
      export SRCMSPDIR=$SRCMSPDIR
      echo "SRCMSPDIR: $SRCMSPDIR"
      ;;
    G)
      MSPDIR=$OPTARG
      export MSPDIR=$MSPDIR
      echo "MSPDIR: $MSPDIR"
      ;;

    t)
      CONFIGTX_ORDERER_ORDERERTYPE=$OPTARG
      export CONFIGTX_ORDERER_ORDERERTYPE=$CONFIGTX_ORDERER_ORDERERTYPE
      echo "CONFIGTX_ORDERER_ORDERERTYPE: $CONFIGTX_ORDERER_ORDERERTYPE"
      if [ $nBroker == 0 ] && [ $CONFIGTX_ORDERER_ORDERERTYPE == 'kafka' ]; then
          nBroker=1   # must have at least 1
      fi
      ;;

    # network options
    a)
      Req=$OPTARG
      echo "action: $Req"
      ;;
    k)
      nBroker=$OPTARG
      echo "# of Broker: $nBroker"
      ;;
    z)
      nZoo=$OPTARG
      echo "number of zookeeper: $Zoo"
      ;;
    p)
      nPeerPerOrg=$OPTARG
      echo "# of peer per org: $nPeerPerOrg"
      ;;

    r)
      nOrg=$OPTARG
      echo "# of nOrg: $nOrg"
      ;;

    o)
      nOrderer=$OPTARG
      echo "# of orderer: $nOrderer"
      ;;

    C)
      comName=$OPTARG
      export comName=$comName
      echo "comName: $comName"
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


if [ $nBroker -gt 0 ] && [ $CONFIGTX_ORDERER_ORDERERTYPE == 'solo' ]; then
    echo "reset Broker number to 0 due to the CONFIGTX_ORDERER_ORDERERTYPE=$CONFIGTX_ORDERER_ORDERERTYPE"
    nBroker=0
fi

#OS
##OSName=`uname`
##echo "Operating System: $OSName"

# get current dir for CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE
CWD=${PWD##*/}
HOSTCONFIG_NETWORKMODE=$(echo $CWD | awk '{print tolower($CWD)}')
export HOSTCONFIG_NETWORKMODE=$HOSTCONFIG_NETWORKMODE
echo "HOSTCONFIG_NETWORKMODE: $HOSTCONFIG_NETWORKMODE"

dbType=`echo "$db" | awk '{print tolower($0)}'`
echo "action=$Req nPeerPerOrg=$nPeerPerOrg nBroker=$nBroker nOrderer=$nOrderer dbType=$dbType"
VP=`docker ps -a | grep 'peer node start' | wc -l`
echo "existing peers: $VP"


echo "remove old docker-composer.yml"
rm -f docker-compose.yml

#echo "docker pull https://hub.docker.com/r/rameshthoomu/fabric-ccenv-x86_64:x86_64-0.7.0-snapshot-b291705"
#docker pull rameshthoomu/fabric-ccenv-x86_64

# form json input file
if [ $nBroker == 0 ]; then
    #jsonFILE="network_solo.json"
    jsonFILE="network.json"
else
#    jsonFILE="network_kafka.json"
    jsonFILE="network.json"
fi
echo "jsonFILE $jsonFILE"

# create docker compose yml
if [ $Req == "add" ]; then
    N1=$[ nPeerPerOrg * nOrg + VP]
    N=$[N1]
    VPN="peer"$[N-1]
else
    N1=$[ nPeerPerOrg * nOrg ]
    N=$[N1 - 1]
    VPN="peer"$N
fi

## echo "N1=$N1 VP=$VP nPeerPerOrg=$nPeerPerOrg VPN=$VPN"

echo "node json2yml.js $jsonFILE $nPeerPerOrg $nOrderer $nBroker $nZoo $nOrg $dbType $nCA"

node json2yml.js $jsonFILE $nPeerPerOrg $nOrderer $nBroker $nZoo $nOrg $dbType $nCA

#fix CA _sk in docker-compose.yml
CWD=$PWD
echo $CWD
echo "GOPATH: $GOPATH"

for (( i=0; i<$nCA; i++ ))
do
    j=$[ i + 1 ]
    Dir=$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config/peerOrganizations/org$j"."$comName"/ca"
    cd $Dir
    tt=`ls *sk`

    cd $CWD

    sed '-i' "s/CA_SK$i/$tt/g" docker-compose.yml

done



## sed 's/-x86_64/TEST/g' docker-compose.yml > ss.yml
## cp ss.yml docker-compose.yml
# create network
if [ $Req == "create" ]; then

   #docker-compose -f docker-compose.yml up -d --force-recreate cli $VPN
   docker-compose -f docker-compose.yml up -d --force-recreate
   #docker-compose -f docker-compose.yml up -d --force-recreate $VPN
   ##docker-compose -f docker-compose.yml up -d --force-recreate $VPN
   #for ((i=1; i<$nOrderer; i++))
   #do
       #tmpOrd="orderer"$i
       #docker-compose -f docker-compose.yml up -d $tmpOrd
   #done
fi

if [ $Req == "add" ]; then
   docker-compose -f docker-compose.yml up -d $VPN

fi

exit
