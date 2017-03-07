#!/bin/bash

#
# example:
#    ./NetworkLauncher.sh -o 1 -r 2 -p 3 -f testOrg -k 1 -t kafka -d goleveldb -c .
#

function printHelp {

   echo "Usage: "
   echo " ./NetworkLauncher.sh [opt] [value] "
   echo "    -d: ledger database type, default=goleveldb"
   echo "    -f: profile string, default=testOrg"
   echo "    -h: hash type, default=SHA2"
   echo "    -k: number of kafka, default=solo"
   echo "    -o: number of orderers, default=1"
   echo "    -p: number of peers per organization, default=1"
   echo "    -r: number of organizations, default=1"
   echo "    -s: security type, default=256"
   echo "    -t: ledger orderer service type [solo|kafka], default=solo"
   echo "    -c: crypto directory, default=$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen"
   echo "    -x: host ip 1, default=0.0.0.0"
   echo "    -y: host ip 2, default=0.0.0.0"
   echo "    -z: host port, default=7050"
   echo " "
   echo " example: "
   echo " ./NetworkLauncher.sh -o 1 -r 2 -p 3 -k 1 -t kafka -f testOrg -w 9.47.152.126 -x 9.47.152.125 -y 9.47.152.124 -z 20000 "
   exit
}

#defaults
PROFILE_STRING="testOrg"
ordServType="solo"
nKafka=0
nOrderer=1
nOrg=1
nPeersPerOrg=1
ledgerDB="goleveldb"
hashType="SHA2"
secType="256"
CryptoBaseDir=$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen


while getopts ":d:f:h:k:o:p:r:t:s:c:w:x:y:z:" opt; do
  case $opt in
    # peer environment options
    d)
      ledgerDB=$OPTARG
      echo "ledger state database type: $ledgerDB"
      ;;

    f)
      PROFILE_STRING=$OPTARG
      echo "PROFILE_STRING: $PROFILE_STRING"
      ;;

    h)
      hashType=$OPTARG
      echo "hash type: $hashType"
      ;;

    k)
      nKafka=$OPTARG
      echo "number of kafka: $kafka"
      ;;

    o)
      nOrderer=$OPTARG
      echo "number of orderers: $nOrderer"
      ;;

    p)
      nPeersPerOrg=$OPTARG
      echo "number of peers: $nPeersPerOrg"
      ;;

    r)
      nOrg=$OPTARG
      echo "number of organizations: $nOrg"
      ;;

    s)
      secType=$OPTARG
      echo "security type: $secType"
      ;;

    t)
      ordServType=$OPTARG
      echo "orderer service type: $ordServType"
      ;;

    c)
      CryptoBaseDir=$OPTARG
      echo "CryptoBaseDir: $CryptoBaseDir"
      ;;

    w)
      HostIP1=$OPTARG
      KafkaAIP=$OPTARG
      echo "HostIP1:  $HostIP1"
      ;;

    x)
      KafkaBIP=$OPTARG
      echo "KafkaIP:  $KafkaIP"
      ;;

    y)
      HostIP2=$OPTARG
      KafkaCIP=$OPTARG
      echo "HostIP2:  $HostIP2"
      ;;

    z)
      BasePort=$OPTARG
      echo "BasePort: $BasePort, HostPort: $HostPort, OrdererPort: $OrdererPort, KafkaPort: $KafkaPort"
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

# sanity check
echo " PROFILE_STRING=$PROFILE_STRING, ordServType=$ordServType, nKafka=$nKafka, nOrderer=$nOrderer"
echo " nOrg=$nOrg, nPeersPerOrg=$nPeersPerOrg, ledgerDB=$ledgerDB, hashType=$hashType, secType=$secType"


CWD=$PWD
echo "current working directory: $CWD"
echo "GOPATH=$GOPATH"

# cryptogen ..................
echo "generate crypto ..."
cd $CryptoBaseDir
echo "current working directory: $PWD"
go build
cd $CWD
echo "current working directory: $PWD"

CRYPTOEXE=$CryptoBaseDir/cryptogen
$CRYPTOEXE -baseDir $CryptoBaseDir -ordererNodes $nOrderer -peerOrgs $nOrg -peersPerOrg $nPeersPerOrg


# configtx ..................
echo "generate configtx.yml ..."
cd $CWD
echo "current working directory: $PWD"
#CFGGenDir=$GOPATH/src/github.com/hyperledger/fabric/common/configtx/tool/configtxgen
#cd $CFGGenDir

echo "./driver_cfgtx.sh -o $nOrderer -p $nPeersPerOrg -r $nOrg -h $hashType -s $secType -t $ordServType -f $PROFILE_STRING"
./driver_cfgtx.sh -o $nOrderer -p $nPeersPerOrg -r $nOrg -h $hashType -s $secType -t $ordServType -f $PROFILE_STRING -w $KafkaAIP -x $KafkaBIP -y $KafkaCIP -z $BasePort


# network gen ..................
echo "generate docker-compose.yml ..."
echo "current working directory: $PWD"
nPeers=$[ nPeersPerOrg * nOrg ]
echo "number of peers: $nPeers"
cryptoDir="crypto-config"
echo "./driver_GenOpt.sh -a create -p $nPeers -o $nOrderer -k $nKafka -t $ordServType -d $ordServType -F $cryptoDir"
./driver_GenOpt.sh -a create -p $nPeers -o $nOrderer -k $nKafka -t $ordServType -d $ordServType -F $cryptoDir

