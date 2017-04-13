#!/bin/bash


# default directories
FabricDir="$GOPATH//src/github.com/hyperledger/fabric"
ordererDir="$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config/ordererOrganizations"
MSPDir="$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config"
SRCMSPDir="/opt/hyperledger/fabric/msp/crypto-config"

function printHelp {

   echo "Usage: "
   echo " ./NetworkLauncher.sh [opt] [value] "
   echo "    -z: number of ca, default=0"
   echo "    -d: ledger database type, default=goleveldb"
   echo "    -f: profile string, default=test"
   echo "    -h: hash type, default=SHA2"
   echo "    -k: number of kafka, default=solo"
   echo "    -n: number of channels, default=1"
   echo "    -o: number of orderers, default=1"
   echo "    -p: number of peers per organization, default=1"
   echo "    -r: number of organizations, default=1"
   echo "    -s: security type, default=256"
   echo "    -t: ledger orderer service type [solo|kafka], default=solo"
   echo "    -c: crypto directory, default=$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen"
   echo "    -w: host ip, default=0.0.0.0"
   echo "    -F: local MSP base directory, default=$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config"
   echo "    -G: src MSP base directory, default=/opt/hyperledger/fabric/msp/crypto-config"
   echo "    -S: TLS base directory "
   echo " "
   echo " example: "
   echo " ./NetworkLauncher.sh -o 1 -z 2 -r 2 -p 2 -k 1 -n 1 -t kafka -f test -w 10.120.223.35 "
   echo " ./NetworkLauncher.sh -o 1 -z 2 -r 2 -p 2 -n 1 -f test -w 10.120.223.35 "
   echo " ./NetworkLauncher.sh -o 1 -z 2 -r 2 -p 2 -k 1 -n 1 -t kafka -f test -w 10.120.223.35 -S /root/gopath/src/github.com/hyperledger/fabric-sdk-node/test/fixtures/tls"
   exit
}

#defaults
PROFILE_STRING="test"
ordServType="solo"
nKafka=0
nCA=0
nOrderer=1
nOrg=1
nPeersPerOrg=1
ledgerDB="goleveldb"
hashType="SHA2"
secType="256"
CryptoBaseDir=$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen
nChannel=1
HostIP1="0.0.0.0"


while getopts ":z:d:f:h:k:n:o:p:r:t:s:c:w:F:G:S:" opt; do
  case $opt in
    # peer environment options
    z)
      nCA=$OPTARG
      echo "number of CA: $nCA"
      ;;
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
      echo "number of kafka: $nKafka"
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
      MSPDir=$OPTARG
      export MSPDIR=$MSPDir
      echo "MSPDir: $MSPDir"
      ;;

    G)
      SRCMSPDir=$OPTARG
      export SRCMSPDIR=$SRCMSPDir
      echo "SRCMSPDir: $SRCMSPDir"
      ;;

    S)
      TLSDir=$OPTARG
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

#if [ $nCA -eq 0 ]; then
#   nCA=$nOrg
#fi

# sanity check
echo " PROFILE_STRING=$PROFILE_STRING, ordServType=$ordServType, nKafka=$nKafka, nOrderer=$nOrderer"
echo " nOrg=$nOrg, nPeersPerOrg=$nPeersPerOrg, ledgerDB=$ledgerDB, hashType=$hashType, secType=$secType"

CHAN_PROFILE=$PROFILE_STRING"Channel"
ORG_PROFILE=$PROFILE_STRING"Org"

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

echo "./driver_cfgtx_x.sh -o $nOrderer -k $nKafka -p $nPeersPerOrg -r $nOrg -h $hashType -s $secType -t $ordServType -f $ORG_PROFILE -w $HostIP1"
./driver_cfgtx_x.sh -o $nOrderer -k $nKafka -p $nPeersPerOrg -r $nOrg -h $hashType -s $secType -t $ordServType -f $ORG_PROFILE -w $HostIP1

echo " "
echo "        ####################################################### "
echo "        #             create orderer.block                    # "
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
ordBlock=$ordererDir"/orderer.block"
echo "$CFGEXE -profile $ORG_PROFILE -outputBlock $ordBlock"
$CFGEXE -profile $ORG_PROFILE -outputBlock $ordBlock

#create channels configuration transaction
echo " "
echo "        ####################################################### "
echo "        #     create channel configuration transaction        # "
echo "        ####################################################### "
echo " "
for (( i=1; i<=$nChannel; i++ ))
do
    channelTx=$ordererDir"/"$CHAN_PROFILE$i".tx"
    #channelTx=$ordererDir"/mychannel.tx"
    echo "$CFGEXE -profile $ORG_PROFILE -channelID $CHAN_PROFILE"$i" -outputCreateChannelTx $channelTx"
    $CFGEXE -profile $ORG_PROFILE -channelID $CHAN_PROFILE"$i" -outputCreateChannelTx $channelTx
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
echo "./driver_GenOpt.sh -a create -z $nCA -p $nPeersPerOrg -r $nOrg -o $nOrderer -k $nKafka -t $ordServType -d $ordServType -F $MSPDir -G $SRCMSPDir -S $TLSDir"
./driver_GenOpt.sh -a create -z $nCA -p $nPeersPerOrg -r $nOrg -o $nOrderer -k $nKafka -t $ordServType -d $ordServType -F $MSPDir -G $SRCMSPDir -S $TLSDir

