Network Launcher
-------



The network Launcher can execute the following task:

1. generate crypto using cryptogen
2. create confitx.yml
3. create a docker-compose.yml and launch a network

The usages of each script is given below so that they can be executed separately as needed.  However, the script, v1launcher.sh, is designed to execute all tasks sequentially.


#NetworkLauncher.sh

This is the main script to execute all tasks.


##Usage:

    ./NetworkLauncher.sh [opt] [value]
       options:
         -d: ledger database type, default=goleveldb
         -f: profile string, default=testOrg
         -h: hash type, default=SHA2
         -k: number of kafka, default=solo
         -n: number of channels, default=1
         -o: number of orderers, default=1
         -p: number of peers per organization, default=1
         -r: number of organizations, default=1
         -s: security type, default=256
         -t: ledger orderer service type [solo|kafka], default=solo
         -c: crypto directory, default=$GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen
         -w: host ip 1, default=0.0.0.0
         -F: local MSP base directory, default=/root/gopath/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config
         -G: src MSP base directory, default=/opt/hyperledger/fabric/msp/crypto-config

    
##Example:
    ./NetworkLauncher.sh -o 1 -r 2 -p 2 -k 1 -n 5 -t kafka -f testOrg -w 10.120.223.35

The above command will invoke cryptogen, cfgtxgen, and launch network.

#cryptogen

The executable is in $GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen and is used to create crypto

    cd $GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen
    apt-get install libltdl-dev
    go build

##Usage
    ./cryptogen -baseDir . -ordererNodes <int> -peerOrgs <int> -peersPerOrg <int>
    -baseDir string
        directory in which to place artifacts (default ".")
    -ordererNodes int
        number of ordering service nodes (default 1)
    -peerOrgs int
        number of unique organizations with peers (default 2)
    -peersPerOrg int
        number of peers per organization (default 1)



#driver_cfgtx_x.sh

The script is used to create configtx.yml.

##Usage
    ./driver_cfgtx_x.sh [opt] [value] 

    options:
       -o: number of orderers, default=1
       -k: number of kafka, default=0
       -p: number of peers per organiztion, default=1
       -h: hash type, default=SHA2
       -r: number of organization, default=1
       -s: security service type, default=256
       -t: orderer service [solo|kafka], default=solo
       -f: profile name, default=testOrg
       -b: MSP directory, default=/mnt/crypto-config
       -w: host ip 1, default=0.0.0.0


##Example:"
    ./driver_cfgtx.sh -o 1 -k 1 -p 2 -r 6 -h SHA2 -s 256 -t kafka -b /root/gopath/src/github.com/hyperledger/fabric/common/tools/cryptogen/ -w 10.120.223.35



#configtx.yaml-in
This is a sample of configtx.yaml to be used to generate the desired configtx.yml. The key words in the sample file are:

+ &ProfileString: the profile string
+ *Org0: used by the script to list all organizations
+ &OrdererOrg: used by the script to list all Organization with its attributes
+ &Org0: used for the list of peers in organization
+ OrdererType: used for the orderer service type

#driver_GenOpt.sh
The script is used to create a docker-compose.yml and launch the network with specified number of peers, orderers, orderer service type etc.

##Usage
    driver_GenOpt.sh [opt] [value]

    options:
       network variables
       -a: action [create|add]
       -p: number of peers
       -o: number of orderers
       -k: number of brokers
        -r: number of organiztions
        -F: local MSP base directory, default=/root/gopath/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config
        -G: src MSP base directory, default=/opt/hyperledger/fabric/msp/crypto-config

       peer environment variables
       -l: core logging level [(default = not set)|CRITICAL|ERROR|WARNING|NOTICE|INFO|DEBUG]
       -d: core ledger state DB [goleveldb|couchdb]

       orderer environment variables
       -b: batch size [10|msgs in batch/block]
       -t: orderer type [solo|kafka]
       -c: batch timeout [10s|max secs before send an unfilled batch]


##Example
    ./driver_GenOpt.sh -a create -p 2 -r 2 -o 1 -k 1 -t kafka -d goleveldb -F /root/gopath/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config -G /opt/hyperledger/fabric/msp/crypto-config


##IP address and port

All IP addresses and ports of orderer, peer, event hub are specified in network.json.

    "ordererAddress": "0.0.0.0",
    "ordererPort": "7050",
    "couchdbAddress": "0.0.0.0",
    "couchdbPort": "5984",
    "vp0Address": "0.0.0.0",
    "vp0Port": "7061",
    "evtAddress": "0.0.0.0",
    "evtPort": "9061",


##Images

All images (peer, kafka, and orderer etc) path (location) are specified in network.json

        "zookeeper": {
            "image": "hyperledger/fabric-zookeeper",


        "kafka": {
            "image": "hyperledger/fabric-kafka",


        "orderer": {
            "image": "hyperledger/fabric-orderer",


        "peer": {
            "image": "hyperledger/fabric-peer",


