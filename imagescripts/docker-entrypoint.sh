#!/bin/bash
#
# A helper script for ENTRYPOINT.
#
# If first CMD argument is 'bitbucket', then the script will start bitbucket
# If CMD argument is overriden and not 'bitbucket', then the user wants to run
# his own process.

set -e

[[ ${DEBUG} == true ]] && set -x

bitbucket_embedded_search="false"

if [ -n "${BITBUCKET_EMBEDDED_SEARCH}" ]; then
  bitbucket_embedded_search=${BITBUCKET_EMBEDDED_SEARCH}
fi

function updateBitbucketProperties() {
  local propertyfile=$1
  local propertyname=$2
  local propertyvalue=$3
  set +e
  grep -q "${propertyname}=" ${propertyfile}
  if [ $? -eq 0 ]; then
    set -e
    if [[ $propertyvalue == /* ]]; then
      sed -i "s/\(${propertyname/./\\.}=\).*\$/\1\\${propertyvalue}/" ${propertyfile}
    else
      sed -i "s/\(${propertyname/./\\.}=\).*\$/\1${propertyvalue}/" ${propertyfile}
    fi
  else
    set -e
    echo "${propertyname}=${propertyvalue}" >> ${propertyfile}
  fi
}

function updateElasticsearchProperties() {
  local propertyfile=$1
  local propertyname=$2
  local propertyvalue=$3
  set +e
  grep -q ^"${propertyname}" ${propertyfile}
  if [ $? -eq 0 ]; then
    set -e
    sed -i "s/\(${propertyname/./\\.}\).*\$/\1${propertyvalue}/" ${propertyfile}
  else
    set -e
    echo "${propertyname}${propertyvalue}" >> ${propertyfile}
  fi
}

function processBitbucketProxySettings() {
  if [ -n "${BITBUCKET_CONTEXT_PATH}" ] || [ -n "${BITBUCKET_PROXY_NAME}" ] || [ -n "${BITBUCKET_PROXY_PORT}" ] || [ -n "${BITBUCKET_DELAYED_START}" ] || [ -n "${BITBUCKET_CROWD_SSO}" ] ; then
    if [ ! -d ${BITBUCKET_HOME}/shared ]; then
      mkdir ${BITBUCKET_HOME}/shared
      chmod 750 ${BITBUCKET_HOME}/shared
    fi

    if [ ! -f ${BITBUCKET_HOME}/shared/bitbucket.properties ]; then
      touch ${BITBUCKET_HOME}/shared/bitbucket.properties
    fi
  fi

  if [ -n "${BITBUCKET_CONTEXT_PATH}" ]; then
    updateBitbucketProperties ${BITBUCKET_HOME}/shared/bitbucket.properties "server.context-path" ${BITBUCKET_CONTEXT_PATH}
  fi

  if [ -n "${BITBUCKET_PROXY_NAME}" ]; then
    updateBitbucketProperties ${BITBUCKET_HOME}/shared/bitbucket.properties "server.proxy-name" ${BITBUCKET_PROXY_NAME}
  fi

  if [ -n "${BITBUCKET_PROXY_PORT}" ]; then
    updateBitbucketProperties ${BITBUCKET_HOME}/shared/bitbucket.properties "server.proxy-port" ${BITBUCKET_PROXY_PORT}
  fi

  if [ -n "${BITBUCKET_PROXY_SCHEME}" ]; then
    if [ "${BITBUCKET_PROXY_SCHEME}" = 'https' ]; then
      local secure="true"
      updateBitbucketProperties ${BITBUCKET_HOME}/shared/bitbucket.properties "server.secure" ${secure}
      updateBitbucketProperties ${BITBUCKET_HOME}/shared/bitbucket.properties "server.scheme" ${BITBUCKET_PROXY_SCHEME}
    else
      local secure="false"
      updateBitbucketProperties ${BITBUCKET_HOME}/shared/bitbucket.properties "server.secure" ${secure}
      updateBitbucketProperties ${BITBUCKET_HOME}/shared/bitbucket.properties "server.scheme" ${BITBUCKET_PROXY_SCHEME}
    fi
  fi

  if [ -n "${BITBUCKET_CROWD_SSO}" ] ; then
    updateBitbucketProperties ${BITBUCKET_HOME}/shared/bitbucket.properties "plugin.auth-crowd.sso.enabled" ${BITBUCKET_CROWD_SSO}
  fi
}

if [ -n "${BITBUCKET_DELAYED_START}" ]; then
  sleep ${BITBUCKET_DELAYED_START}
fi

processBitbucketProxySettings

# Configure embedded Elasticsearch JVM heap size options
if [ "${bitbucket_embedded_search}" = 'true' ]; then
  if [ -n "${ES_JVM_MINIMUM_MEMORY}" ]; then
    updateElasticsearchProperties ${BITBUCKET_HOME}/shared/search/jvm.options "-Xms" ${ES_JVM_MINIMUM_MEMORY}
  fi
  if [ -n "${ES_JVM_MAXIMUM_MEMORY}" ]; then
    updateElasticsearchProperties ${BITBUCKET_HOME}/shared/search/jvm.options "-Xmx" ${ES_JVM_MAXIMUM_MEMORY}
  fi
fi

# If there is a 'ssh' directory, copy it to /home/bitbucket/.ssh
if [ -d /var/atlassian/bitbucket/ssh ]; then
  mkdir -p /home/bitbucket/.ssh
  cp -R /var/atlassian/bitbucket/ssh/* /home/bitbucket/.ssh
  chmod -R 700 /home/bitbucket/.ssh
fi

if [ "$1" = 'bitbucket' ] || [ "${1:0:1}" = '-' ]; then
  source /usr/bin/dockerwait
  umask 0027
  if [ "${bitbucket_embedded_search}" = 'true' ]; then
    exec ${BITBUCKET_INSTALL}/bin/start-bitbucket.sh -fg
  else
    exec ${BITBUCKET_INSTALL}/bin/start-bitbucket.sh --no-search -fg
  fi
else
  exec "$@"
fi
