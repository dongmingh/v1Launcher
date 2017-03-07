#!/bin/bash

#
# usage: ./driver_GenOpt.sh [opt] [value]
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
   echo " "
   echo " example: "
   echo " ./NetworkLauncher.sh -o 1 -r 2 -p 3 -k 1 -f testOrg -c . "
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


while getopts ":d:f:h:k:o:p:r:t:s:c:" opt; do
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

# crypto
echo "generate crypto ..."
#echo "current working directory: $PWD"
go build

CRYPTOEXE=$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/cryptogen
$CRYPTOEXE -baseDir $CryptoBaseDir -ordererNodes $nOrderer -peerOrgs $nOrg -peersPerOrg $nPeersPerOrg


# configtx
echo "generate configtx.yml ..."
cd $CWD
echo "current working directory: $PWD"

echo "./driver_cfgtx.sh -o $nOrderer -p $nPeersPerOrg -r $nOrg -h $hashType -s $secType -t $ordServType -f $PROFILE_STRING"
./driver_cfgtx.sh -o $nOrderer -p $nPeersPerOrg -r $nOrg -h $hashType -s $secType -t $ordServType -f $PROFILE_STRING


echo "generate docker-compose.yml ..."
echo "current working directory: $PWD"
nPeers=$[ nPeersPerOrg * nOrg ]
echo "number of peers: $nPeers"
echo "./driver_GenOpt.sh -p $nPeers -o $nOrderer -k $nKafka -t $ordServType -d $ledgerDB"
cryptoDir="crypto-config"
echo "./driver_GenOpt.sh -a create -p $nPeers -o $nOrderer -k $nKafka -t $ordServType -d $ordServType -F $cryptoDir"
./driver_GenOpt.sh -a create -p $nPeers -o $nOrderer -k $nKafka -t $ordServType -d $ordServType -F $cryptoDir

