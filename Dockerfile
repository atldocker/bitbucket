FROM adoptopenjdk/openjdk8:alpine
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

ARG BITBUCKET_VERSION=7.2.4
# permissions
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000

ENV BITBUCKET_HOME=/var/atlassian/bitbucket \
    BITBUCKET_INSTALL=/opt/bitbucket \
    BITBUCKET_PROXY_NAME= \
    BITBUCKET_PROXY_PORT= \
    BITBUCKET_PROXY_SCHEME= \
    BITBUCKET_BACKUP_CLIENT=/opt/backupclient/bitbucket-backup-client \
    BITBUCKET_BACKUP_CLIENT_HOME=/opt/backupclient \
    BITBUCKET_BACKUP_CLIENT_VERSION=300600000

RUN export MYSQL_DRIVER_VERSION=5.1.48 && \
    export CONTAINER_USER=bitbucket &&  \
    export CONTAINER_GROUP=bitbucket &&  \
    addgroup --gid $CONTAINER_GID $CONTAINER_GROUP &&  \
    adduser -u $CONTAINER_UID \
            -g $CONTAINER_GROUP \
            -h /home/$CONTAINER_USER \
            -s /bin/bash \
            -S $CONTAINER_USER &&  \
    apk add --update \
      bash \
      ca-certificates \
      gzip \
      curl \
      openssh \
      util-linux \
      git \
      perl \
      wget  \
      ttf-dejavu \
      git-daemon \
      tini \
      xmlstarlet && \
    wget -O /tmp/bitbucket.tar.gz https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-${BITBUCKET_VERSION}.tar.gz && \
    tar zxf /tmp/bitbucket.tar.gz -C /tmp && \
    mv /tmp/atlassian-bitbucket-${BITBUCKET_VERSION} /tmp/bitbucket && \
    mkdir -p ${BITBUCKET_HOME} && \
    mkdir -p /opt && \
    mv /tmp/bitbucket /opt/bitbucket && \
    # Install database drivers
    rm -f                                               \
      ${BITBUCKET_INSTALL}/lib/mysql-connector-java*.jar &&  \
    wget -O /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz                                              \
      http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz && \
    tar xzf /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz                                              \
      -C /tmp && \
    cp /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar     \
      ${BITBUCKET_INSTALL}/lib/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar                                &&  \
    # Adding letsencrypt-ca to truststore
    export KEYSTORE=$JAVA_HOME/jre/lib/security/cacerts && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x2-cross-signed.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x4-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx1 -file /tmp/lets-encrypt-x1-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx2 -file /tmp/lets-encrypt-x2-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx3 -file /tmp/lets-encrypt-x3-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx4 -file /tmp/lets-encrypt-x4-cross-signed.der && \
    # Install atlassian ssl tool
    wget -O /home/${CONTAINER_USER}/SSLPoke.class https://confluence.atlassian.com/kb/files/779355358/779355357/1/1441897666313/SSLPoke.class && \
    # Container user permissions
    chown -R bitbucket:bitbucket /home/${CONTAINER_USER} && \
    chown -R bitbucket:bitbucket ${BITBUCKET_HOME} && \
    chown -R bitbucket:bitbucket ${BITBUCKET_INSTALL}

RUN mkdir -p ${BITBUCKET_BACKUP_CLIENT_HOME} && \
    wget -O /tmp/bitbucket-backup-distribution.zip \
      https://marketplace.atlassian.com/download/plugins/com.atlassian.stash.backup.client/version/${BITBUCKET_BACKUP_CLIENT_VERSION} && \
    unzip -d ${BITBUCKET_BACKUP_CLIENT_HOME} /tmp/bitbucket-backup-distribution.zip && \
    mv /opt/backupclient/$(ls /opt/backupclient/) /opt/backupclient/bitbucket-backup-client && \
    chown -R bitbucket:bitbucket ${BITBUCKET_BACKUP_CLIENT_HOME}

# Remove obsolete packages
RUN apk del \
      ca-certificates \
      gzip \
      util-linux \
      wget &&  \
    # Clean caches and tmps
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/* && \
    rm -rf /var/log/*

USER bitbucket
WORKDIR /var/atlassian/bitbucket
VOLUME ["/var/atlassian/bitbucket"]
EXPOSE 7990 7990
EXPOSE 7999 7999
EXPOSE 7992 7992
COPY imagescripts/docker-entrypoint.sh /home/bitbucket/
COPY imagescripts/ps_opt_p_enabled_for_alpine.sh /usr/bin/ps
COPY imagescripts/dockerwait.sh /usr/bin/dockerwait
ENTRYPOINT ["/sbin/tini","--","/home/bitbucket/docker-entrypoint.sh"]
CMD ["bitbucket"]
