#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

#
# usage: ./clearNetwork.sh [opt] [value]
#

#bring down network
echo "bring down network"
docker-compose down

#remove dead docker containers
echo "remove dead docker containers"
#docker rm -f $(docker ps -aq)
CONTAINER_IDS=$(docker ps -aq)
if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" = " " ]; then
    echo "---- No containers available for deletion ----"
else
    docker rm -f $CONTAINER_IDS
fi

#remove dead docker images
echo "remove dead docker images"
DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" = " " ]; then
    echo "---- No images available for deletion ----"
else
    docker rmi -f $DOCKER_IMAGE_IDS
fi
#docker rmi -f $(docker images | grep sample | awk '{print $3}')

