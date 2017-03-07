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
       -d: ledger database type, default=goleveldb
       -f: profile string, default=testOrg
       -h: hash type, default=SHA2
       -k: number of kafka, default=solo
       -o: number of orderers, default=1
       -p: number of peers per organization, default=1
       -r: number of organizations, default=1
       -s: security type, default=256
       -t: ledger orderer service type [solo|kafka], default=solo

##Example:
    ./NetworkLauncher.sh -o 1 -k 1 -r 2 -p 3 -f myOrg



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

##Example:
    ./v1launcher.sh -o 1 -r 2 -p 3 -f testOrg -k 1 -t kafka -d goleveldb -c .


#driver_cfgtx.sh

The script is used to create configtx.yml.

##Usage
    ./driver_cfgtx.sh [opt] [value] 

    options:

       -o: number of orderers, default=1
       -p: number of peers per organiztion, default=1
       -h: hash type, default=SHA2
       -r: number of organization, default=1
       -s: security service type, default=256
       -t: orderer service [solo|kafka], default=solo
       -f: profile string, default=testOrg

#Example
    ./driver_cfgtx.sh -o 2 -p 3 -r 2 -h SHA2 -s 256 -t kafka

#configtx.yaml-in
This is a sample of configtx.yaml to be used to generate the desired configtx.yml. The key words in the sample file are:

+ &ProfileString: the profile string
+ *Org0: used by the script to list all organizations
+ &OrdererOrg: used by the script to list all Organization with its attributes
+ &Org0: used for the list of peers in organization
+ OrdererType: used for the orderer service type

#driver_GenOpt.sh
The script is used to create a docker-compose.yml and launch the network with specified number of peers, orderers, orderer type etc.

##Usage
    driver_GenOpt.sh [opt] [value]

    options:
       network variables
       -a: action [create|add]
       -p: number of peers
       -o: number of orderers
       -k: number of brokers

       peer environment variables
       -l: core logging level [(default = not set)|CRITICAL|ERROR|WARNING|NOTICE|INFO|DEBUG]
       -d: core ledger state DB [goleveldb|couchdb]

       orderer environment variables
       -b: batch size [10|msgs in batch/block]
       -t: orderer type [solo|kafka]
       -c: batch timeout [10s|max secs before send an unfilled batch]


##Example
    ./driver_GenOpt.sh -p 4 -o 1 -k 1 -t kafka -d goleveldb


##IP address and port

The user needs to specify the IP addresses and ports of orderer, peer, event in network.json.

##Images

All images (peer, kafka, and orderer etc) path (location) are specified in network.json





