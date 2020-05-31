#!/bin/bash

#------------------
# CONTAINER VARIABLES
#------------------
export BITBUCKET_VERSION=7.2.4

docker build -t teamatldocker/bitbucket .

if [ "${CIRCLE_BRANCH}" == "master" ]; then
  docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}
  docker push teamatldocker/bitbucket
  docker tag teamatldocker/bitbucket teamatldocker/bitbucket:${BITBUCKET_VERSION}
  docker push teamatldocker/bitbucket:${BITBUCKET_VERSION}
fi
