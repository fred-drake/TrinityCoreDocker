# Trinity Core
This image will allow you to run your own complete dockerized WoW Wrath of the Lich King private server, using the Trinity Core open source MMO framework.

## Initial Setup
Before running your private realm, you need to set up your data files, and initialize your database.

### Data Setup
First, you need to build data files using your WoW Wrath of the Lich King client (3.3.5a).  Store this in a data volume or host location.  Your data will be stored in /data, and the client will be pulled from /wowclient.  You only need to do this once.  Note that due to the nature of the data pulling files, there will be temporary data written to the WoW client directory so it cannot be mounted as read-only.

```
docker run -it --rm -v <WOW CLIENT VOLUME>:/wowclient -v <DATA VOLUME>:/data fdrake/trinitycore:3.3.5 --builddata
```

### Database Initialization
Next, you need to initialize your database with the create script which will create the necessary databases, and the non-root user that will be used in the application.  This is also executed only once.  There following environment variables are used:

* MYSQL_PORT: The port for your database (defaults to *3306*)
* MYSQL_HOST: The MySQL hostname (defaults to host.docker.internal)
* MYSQL_USER: The username of the non-root user to be used (defaults to *trinity*)
* MYSQL_PASSWORD: the password of the non-root user to be used (defaults to *trinity*)
* MYSQL\_USER_HOST: The host mask to be allowed for the non-root user (defaults to *%* which is any host)

Example:

```
docker run --rm -e MYSQL_PORT=3306 -e MYSQL_HOST=mysql -e MYSQL_ROOT_PASSWORD=wow --network trinitycore_default fdrake/trinitycore:3.3.5 --dbinit
```

Note, that if you are running MySQL 5.7 that you should disable strict mode in your database:
```
mysql -u root -p -e "SET GLOBAL sql_mode = 'NO_ENGINE_SUBSTITUTION';" 
```

### Configuration File Setup

Create a config volume which will store your `worldserver.conf` and `authserver.conf` files.  You can copy the distribution's versions from `/server/etc`.  A few quick commands that will accomplish this:

```
docker run -it --rm -v <CONFIG VOLUME>:/config fdrake/trinitycore:3.3.5 cp /server/etc/worldserver.conf.dist /config/worldserver.conf
docker run -it --rm -v <CONFIG VOLUME>:/config fdrake/trinitycore:3.3.5 cp /server/etc/authserver.conf.dist /config/authserver.conf
```

The mandatory configurations are as follows:

* In both `worldserver.conf` and `authserver.conf`, change all database references to your MySQL database.
* In `worldserver.conf`, change the `DataDir` variable to /data.

Optionally, you can create your own logs volume.  Set the `LogsDir` variable to `/logs` in both `worldserver.conf` and `authserver.conf` files.

Finally, update the `realmlist` MySQL table in the `auth` to set the external and internal IP addresses of your realm by setting both to your docker host address.

## Run Your Realm
Run your realm by kicking off two containers, one for the world server and the other for the auth server.  Use the command line options `--worldserver` and `--authserver`, respectively.  Note that for the world server you must enable STDIN and TTY (e.g. `docker run -it`) and for the auth server you must enable TTY.

A complete example Docker Compose file which encapsulates everything (but with persistent volumes that are created externally of the compose file):

```
version: '2'

services:
  mysql:
    restart: always
    image: mysql:5.7
    environment:
      - MYSQL_ROOT_PASSWORD=wow
    volumes:
      - tc335_db_data:/var/lib/mysql
  worldserver:
    image: fdrake/trinitycore:3.3.5
    command: --worldserver
    tty: true
    stdin_open: true
    ports:
      - '8085:8085'
    volumes:
      - tc335_data:/data
      - tc335_config:/config
      - tc335_logs:/logs 
  authserver:
    image: fdrake/trinitycore:3.3.5
    command: --authserver
    tty: true
    ports:
      - '3724:3724'
    volumes:
      - tc335_config:/config
      - tc335_logs:/logs
volumes:
  tc335_db_data:
    external: true
  tc335_data:
    external: true
  tc335_config:
    external: true
  tc335_logs:
    external: true
```

### Admin Account Setup
Use `docker attach` to attach into your world server instance, and use the following command to create an account:

```
account create <username> <password>
```

Optionally, you can elevate the user to have GM powers:

```
account set gmlevel <username> 3 -1
```

### WoW Client Setup
Modify your `realmlist.wtf` file inside your `Data` directory to the following:

```
set realmlist <DOCKER HOST IP ADDRESS>
set patchlist <DOCKER HOST IP ADDRESS>
```

That's it!  Fire up your WoW client and log in using the username and password that you used when creating your account.

## Caveats
The goal of the docker image was to streamline as much of the setup as possible within reason, but it was not designed to be a complete keyturn solution.  Please refer to [the wiki](https://trinitycore.atlassian.net/wiki/spaces/tc/pages/2130077/Installation+Guide) for step by step details if you run into issues.
