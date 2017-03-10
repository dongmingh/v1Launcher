#!/bin/bash


# default directories
FabricDir="$GOPATH//src/github.com/hyperledger/fabric"
ordererDir="$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config/ordererOrganizations"
MSPDir="$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config"
SRCMSPDir="/opt/hyperledger/fabric/msp/crypto-config"

function printHelp {

   echo "Usage: "
   echo " ./NetworkLauncher.sh [opt] [value] "
   echo "    -d: ledger database type, default=goleveldb"
   echo "    -f: profile string, default=testOrg"
   echo "    -h: hash type, default=SHA2"
   echo "    -k: number of kafka, default=solo"
   echo "    -n: number of channels, default=1"
   echo "    -o: number of orderers, default=1"
   echo "    -p: number of peers per organization, default=1"
   echo "    -r: number of organizations, default=1"
   echo "    -s: security type, default=256"
   echo "    -t: ledger orderer service type [solo|kafka], default=solo"
   echo "    -c: crypto directory, default=$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen"
   echo "    -w: host ip 1, default=0.0.0.0"
   echo "    -F: local MSP base directory, default=/root/gopath/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config"
   echo "    -G: src MSP base directory, default=/opt/hyperledger/fabric/msp/crypto-config"
   echo " "
   echo " example: "
   echo " ./NetworkLauncher.sh -o 1 -r 2 -p 2 -k 1 -n 5 -t kafka -f testOrg -w 10.120.223.35 "
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
nChannel=1


while getopts ":d:f:h:k:n:o:p:r:t:s:c:w:F:G:" opt; do
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

    n)
      nChannel=$OPTARG
      echo "number of channels: $nChannel"
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
      echo "HostIP1:  $HostIP1"
      ;;

    F)
      MSPDIR=$OPTARG
      export MSPDIR=$MSPDIR
      echo "MSPDIR: $MSPDIR"
      ;;
    G)
      SRCMSPDIR=$OPTARG
      export SRCMSPDIR=$SRCMSPDIR
      echo "SRCMSPDIR: $SRCMSPDIR"
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
echo " "
echo "        ####################################################### "
echo "        #                execute cryptogen                    # "
echo "        ####################################################### "
echo "generate crypto ..."
cd $CryptoBaseDir
# remove existing crypto-config
rm -rf crypto-config
echo "current working directory: $PWD"
go build
cd $CWD
echo "current working directory: $PWD"

CRYPTOEXE=$CryptoBaseDir/cryptogen
echo "$CRYPTOEXE -baseDir $CryptoBaseDir -ordererNodes $nOrderer -peerOrgs $nOrg -peersPerOrg $nPeersPerOrg"
$CRYPTOEXE -baseDir $CryptoBaseDir -ordererNodes $nOrderer -peerOrgs $nOrg -peersPerOrg $nPeersPerOrg

echo " "
echo "        ####################################################### "
echo "        #                 generate configtx.yaml              # "
echo "        ####################################################### "
echo " "
echo "generate configtx.yaml ..."
cd $CWD
echo "current working directory: $PWD"

echo "./driver_cfgtx_x.sh -o $nOrderer -k $nKafka -p $nPeersPerOrg -r $nOrg -h $hashType -s $secType -t $ordServType -f $PROFILE_STRING -w $HostIP1"
./driver_cfgtx_x.sh -o $nOrderer -k $nKafka -p $nPeersPerOrg -r $nOrg -h $hashType -s $secType -t $ordServType -f $PROFILE_STRING -w $HostIP1

echo " "
echo "        ####################################################### "
echo "        #     create orderer.block and channel blocks         # "
echo "        ####################################################### "
echo " "
CFGGenDir=$GOPATH/src/github.com/hyperledger/fabric/build/bin
CFGEXE=$CFGGenDir"/configtxgen"
cp configtx.yaml $FabricDir"/common/configtx/tool"
#cd $CFGGenDir
if [ ! -f $CFGEXE ]; then
    cd $FabricDir
    make configtxgen
    cd $CWD
fi
#create orderer blocks
$CFGEXE -profile $PROFILE_STRING -outputBlock $ordererDir"/orderer.block" 

#create channels blocks
for (( i=1; i<=$nChannel; i++ ))
do
    $CFGEXE -profile $PROFILE_STRING -channelID $PROFILE_STRING"$i" -outputCreateChannelTx $ordererDir"/"$PROFILE_STRING$i".block"
done

echo " "
echo "        ####################################################### "
echo "        #                   bring up network                  # "
echo "        ####################################################### "
echo " "
echo "generate docker-compose.yml ..."
echo "current working directory: $PWD"
nPeers=$[ nPeersPerOrg * nOrg ]
echo "number of peers: $nPeers"
echo "./driver_GenOpt.sh -a create -p $nPeersPerOrg -r $nOrg -o $nOrderer -k $nKafka -t $ordServType -d $ordServType -F $MSPDir -G $SRCMSPDir"
./driver_GenOpt.sh -a create -p $nPeersPerOrg -r $nOrg -o $nOrderer -k $nKafka -t $ordServType -d $ordServType -F $MSPDir -G $SRCMSPDir

