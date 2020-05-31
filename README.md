# Dockerized Atlassian Bitbucket

"Built for professional teams - Distributed version control system that makes it easy for you to collaborate with your team. The only collaborative Git solution that massively scales." - [[Source](https://www.atlassian.com/software/bitbucket)]

## Supported tags and respective Dockerfile links

| Product |Version | Tags  | Dockerfile |
|---------|--------|-------|------------|
| Bitbucket | 7.2.4 | 7.2.4, latest | [Dockerfile](https://github.com/blacklabelops/bitbucket/blob/master/Dockerfile) |

## Related Images

You may also like:

* [blacklabelops/jira](https://github.com/blacklabelops/jira): The #1 software development tool used by agile teams
* [blacklabelops/confluence](https://github.com/blacklabelops/confluence): Create, organize, and discuss work with your team
* [blacklabelops/bitbucket](https://github.com/blacklabelops/bitbucket): Code, Manage, Collaborate
* [blacklabelops/crowd](https://github.com/blacklabelops/crowd): Identity management for web apps

# Make It Short

Docker-CLI:

Just type and follow the manual installation procedure in your browser:

~~~~
$ docker run -d -p 7990:7990 --name bitbucket blacklabelops/bitbucket
~~~~

> Point your browser to http://yourdockerhost:7990

# Setup

1. Start database server for Bitbucket.
2. Start Bitbucket.
3. Manual Bitbucket setup.

Firstly, start the database server for Bitbucket:

> Note: Change Password!

~~~~
$ docker run --name postgres_bitbucket -d \
    -e 'POSTGRES_DB=bitbucketdb' \
    -e 'POSTGRES_USER=bitbucketdb' \
    -e 'POSTGRES_PASSWORD=jellyfish' \
    -e 'POSTGRES_ENCODING=UTF8' \
    blacklabelops/postgres
~~~~

Secondly, start Bitbucket:

~~~~
$ docker run -d --name bitbucket \
	  --link postgres_bitbucket:postgres_bitbucket \
	  -p 7990:7990 blacklabelops/bitbucket
~~~~

>  Starts Crowd and links it to the postgresql instances. JDBC URL: jdbc:postgresql://postgres_bitbucket/bitbucketdb

Thirdly, configure your Bitbucket yourself and fill it with a test license.

Point your browser to http://yourdockerhost:7990

1. Choose `External` for `Database` and fill out the form:
  * Database Type: `PostgreSQL`
  * Hostname: `postgres_bitbucket`
  * Port: `5432`
  * Database name: `bitbucketdb`
  * Database username: `bitbucketdb`
  * Database password: `jellyfish`
2. Create and enter license information
3. Fill out the rest of the installation procedure.

# Embedded Elasticsearch

You need to use the environment variable BITBUCKET_EMBEDDED_SEARCH if you want to use the Embedded Elasticsearch:

Example:

~~~~
$ docker run -d --name bitbucket \
    -v your-local-folder-or-volume:/var/atlassian/bitbucket \
    -e "BITBUCKET_EMBEDDED_SEARCH=true" \
    -p 7990:7990 \
    blacklabelops/bitbucket /opt/bitbucket/bin/start-bitbucket.sh -fg
~~~~

> A separate java process for Elasticsearch will be started.

# Database Wait Feature

The bitbucket container can wait for the database container to start up. You have to specify the
host and port of your database container and Bitbucket will wait up to one minute for the database.

You can define the waiting parameters with the environment variables:

* `DOCKER_WAIT_HOST`: The host to poll. Mandatory!
* `DOCKER_WAIT_PORT`: The port to poll Mandatory!
* `DOCKER_WAIT_TIMEOUT`: The timeout in seconds. Optional! Default: 60
* `DOCKER_WAIT_INTERVAL`: The polling interval in seconds. Optional! Default:5

Example waiting for a postgresql database:

First start the polling container:

~~~~
$ docker run -d --name bitbucket \
    -e "DOCKER_WAIT_HOST=your_postgres_host" \
    -e "DOCKER_WAIT_PORT=5432" \
    -p 80:8090 blacklabelops/bitbucket
~~~~

> Waits at most 60 seconds for the database.

Start the database within 60 seconds:

~~~~
$ docker run --name postgres -d \
    --network jiranet \
    -v postgresvolume:/var/lib/postgresql \
    -e 'POSTGRES_USER=jira' \
    -e 'POSTGRES_PASSWORD=jellyfish' \
    -e 'POSTGRES_DB=jiradb' \
    -e 'POSTGRES_ENCODING=UNICODE' \
    -e 'POSTGRES_COLLATE=C' \
    -e 'POSTGRES_COLLATE_TYPE=C' \
    blacklabelops/postgres
~~~~

> Bitbucket will start after postgres is available!

# SSH Keys

If you need to use SSH Keys to authenticate Bitbucket to other services (eg, replicating to Github), put the entire contents of what you want to have in the .ssh directory in a directory called 'ssh' on your persistent volume.

When the container is started, the contents of `/var/atlassian/bitbucket/ssh` directory will be copied to `/home/bitbucket/.ssh`, and the permissions will be set to 700.

Example:

~~~~
$ docker run -d --name bitbucket \
    -v your-local-ssh-folder-or-volume:/var/atlassian/bitbucket/ssh \
    -e "BITBUCKET_PROXY_NAME=myhost.example.com" \
    -e "BITBUCKET_PROXY_PORT=443" \
    -e "BITBUCKET_PROXY_SCHEME=https" \
    blacklabelops/bitbucket
~~~~

> ssh keys will be copied and are available at runtime.

Alternatively copy the files in your running container and restart the container:

~~~~
# Creating the folder
$ docker exec bitbucket mkdir -p /var/atlassian/bitbucket/ssh
# Copy the keys
$ docker cp your-local-ssh-folder your-container-name:/var/atlassian/bitbucket/ssh
# Restart container
$ docker restart your-container-name
~~~~

# Embedded Backup And Restore Clients

This image has the Atlassian Bitbucket Backup Client included. The homepage can be found [HERE](https://marketplace.atlassian.com/plugins/com.atlassian.stash.backup.client/server/overview).The full documentation can be found [HERE](http://confluence.atlassian.com/display/BitbucketServer/Data+recovery+and+backups).

The client must be either executed inside the running container or inside a container that has the bitbucket
home directory as an attached volume.

Executing the backup client inside the running container:

~~~~
$ docker exec bitbucket java -jar /opt/backupclient/bitbucket-backup-client/bitbucket-backup-client.jar --help
~~~~

> Displays the help page inside the container with name `bitbucket`.

Executing the restore client inside the running container:

~~~~
$ docker exec bitbucket java -jar /opt/backupclient/bitbucket-backup-client/bitbucket-restore-client.jar --help
~~~~

> Displays the help page inside the container with name `bitbucket`.

The required parameters can be passed using environment variables:

* `BITBUCKET_HOME`: Bitbucket home directory, should be already set in the running container.
* `BITBUCKET_BASEURL`: Bitbucket base url.
* `BITBUCKET_USER`: Bitbucket admin user name.
* `BITBUCKET_PASSWORD`: Bitbucket admin password.

Example:

~~~~
$ docker exec -it \
    -e "BITBUCKET_BASEURL=http://localhost:7990" \
    -e "BITBUCKET_USER=youradmin" \
    -e "BITBUCKET_PASSWORD=yourpassword" \
    bitbucket bash
$ java -jar ${BITBUCKET_BACKUP_CLIENT}/bitbucket-backup-client.jar
~~~~

> Executes the backup client.

Running in a separate container:

~~~~
$ docker run --rm --name bitbucket_backup \
    -v your-local-bitbucket-folder-or-volume:/var/atlassian/bitbucket \
    -e "BITBUCKET_BASEURL=http://yourbitbucketserverurl:yourport" \
    -e "BITBUCKET_USER=youradmin" \
    -e "BITBUCKET_PASSWORD=yourpassword" \
    blacklabelops/bitbucket \
    java -jar /opt/backupclient/bitbucket-backup-client/bitbucket-backup-client.jar
~~~~

> Executing the backup client in a separate container that has access to bitbucket volume.

# JVM memory settings

## Bitbucket

By default Bitbucket starts with `-Xms=512m -Xmx=1g`. In some cases, this may not be enough to work with.

If needed, you can specify your own memory settings:

~~~~
$ docker run -d \
    -e "JVM_MINIMUM_MEMORY=2g" \
    -e "JVM_MAXIMUM_MEMORY=3g" \
    -p 7990:7990 \
    blacklabelops/bitbucket
~~~~

This will start Bitbucket with `-Xms=2g -Xmx=3g`.

## Embedded Elasticsearch

By default Elasticsearch starts with `-Xms1g -Xmx1g`.

If needed, you can specify your own memory settings:

~~~~
$ docker run -d \
    -e "BITBUCKET_EMBEDDED_SEARCH=true" \
    -e "ES_JVM_MINIMUM_MEMORY=2g" \
    -e "ES_JVM_MAXIMUM_MEMORY=2g" \
    -p 7990:7990 \
    blacklabelops/bitbucket
~~~~

This will start embedded Elasticsearch with `-Xms2g -Xmx2g`.

Note: BITBUCKET_EMBEDDED_SEARCH need to be set to true. Otherwise, the environment variables will be ignored.

# Proxy Configuration

You can specify your proxy host and proxy port with the environment variables BITBUCKET_PROXY_NAME and BITBUCKET_PROXY_PORT. The value will be set inside the Atlassian server.xml at startup!

When you use https then you also have to include the environment variable BITBUCKET_PROXY_SCHEME.

You can also specify the context path with BITBUCKET_CONTEXT_PATH.

Example HTTPS:

* Proxy Name: myhost.example.com
* Proxy Port: 443
* Poxy Protocol Scheme: https

Just type:

~~~~
$ docker run -d --name bitbucket \
    -e "BITBUCKET_PROXY_NAME=myhost.example.com" \
    -e "BITBUCKET_PROXY_PORT=443" \
    -e "BITBUCKET_PROXY_SCHEME=https" \
    blacklabelops/bitbucket
~~~~

> Will set the values inside the bitbucket.properties in /var/atlassian/bitbucket/bitbucket.properties

# NGINX HTTP Proxy

This is an example on running Atlassian Bitbucket behind NGINX with 2 Docker commands!

First start Bitbucket:

~~~~
$ docker run -d --name bitbucket \
    -e "BITBUCKET_CONTEXT_PATH=/bitbucket" \
    -e "BITBUCKET_PROXY_NAME=myhost.example.com" \
    -e "BITBUCKET_PROXY_PORT=80" \
    -e "BITBUCKET_PROXY_SCHEME=http" \
    blacklabelops/bitbucket
~~~~

> Example with dockertools

Then start NGINX:

~~~~
$ docker run -d \
    -p 80:80 \
    --name nginx \
    --link bitbucket:bitbucket \
    -e "SERVER1SERVER_NAME=myhost.example.com" \
    -e "SERVER1REVERSE_PROXY_LOCATION1=/bitbucket" \
    -e "SERVER1REVERSE_PROXY_PASS1=http://bitbucket:7990" \
    -e "SERVER1REVERSE_PROXY_APPLICATION1: bitbucket"
    blacklabelops/nginx
~~~~

> Bitbucket will be available at http://myhost.example.com/bitbucket.

# NGINX HTTPS Proxy

This is an example on running Atlassian Bitbucket behind NGINX-HTTPS with2 Docker commands!

Note: This is a self-signed certificate! Trusted certificates by letsencrypt are supported. Documentation can be found here: [blacklabelops/nginx](https://github.com/blacklabelops/nginx)

First start Bitbucket:

~~~~
$ docker run -d --name bitbucket \
    -e "BITBUCKET_PROXY_NAME=192.168.99.100" \
    -e "BITBUCKET_PROXY_PORT=80" \
    -e "BITBUCKET_PROXY_SCHEME=http" \
    blacklabelops/bitbucket
~~~~

> Example with dockertools

Then start NGINX:

~~~~
$ docker run -d \
    -p 443:443 \
    --name nginx \
    --link bitbucket:bitbucket \
    -e "SERVER1REVERSE_PROXY_LOCATION1=/" \
    -e "SERVER1REVERSE_PROXY_PASS1=http://bitbucket:7990" \
    -e "SERVER1CERTIFICATE_DNAME=/CN=CrustyClown/OU=SpringfieldEntertainment/O=crusty.springfield.com/L=Springfield/C=US" \
    -e "SERVER1HTTPS_ENABLED=true" \
    -e "SERVER1HTTP_ENABLED=false" \
    blacklabelops/nginx
~~~~

> Bitbucket will be available at https://192.168.99.100.

# Vagrant

First install:

* [Vagrant](https://www.vagrantup.com/)
* [Virtualbox](https://www.virtualbox.org/)

Vagrant is fabulous tool for pulling and spinning up virtual machines like docker with containers. I can configure my development and test environment and simply pull it online. And so can you! Install Vagrant and Virtualbox and spin it up. Change into the project folder and build the project on the spot!

~~~~
$ vagrant up
$ vagrant ssh
[vagrant@localhost ~]$ cd /vagrant
[vagrant@localhost ~]$ docker-compose up
~~~~

> Bitbucket will be available on http://localhost:8080 on the host machine.

# Bitbucket SSO With Crowd

You enable Single Sign On with Atlassian Crowd. What is crowd?

"Users can come from anywhere: Active Directory, LDAP, Crowd itself, or any mix thereof. Control permissions to all your applications in one place – Atlassian, Subversion, Google Apps, or your own apps." - [Atlassian Crowd](https://www.atlassian.com/software/crowd/overview)

This is controlled by the environment variable `BITBUCKET_CROWD_SSO`. Possible values:

* `true`: Bitbucket configuration will be set to Crowd SSO authentication class at every restart.
* `false`: Bitbucket configuration will be set to Bitbucket Authentication class at every restart.

Example:

~~~~
$ docker run -d -p 7990:7990 -v your-local-folder-or-volume:/var/atlassian/bitbucket \
    -e "BITBUCKET_CROWD_SSO=true" \
    --name bitbucket blacklabelops/bitbucket
~~~~

 > SSO will be activated, you will need Crowd in order to authenticate.

# References

* [Atlassian Bitbucket](https://www.atlassian.com/software/bitbucket)
* [Docker Homepage](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Docker Userguide](https://docs.docker.com/userguide/)
* [Oracle Java](https://java.com/de/download/)
