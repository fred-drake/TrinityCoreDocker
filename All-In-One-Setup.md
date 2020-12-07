# Trinity Core All-In-One Setup

Currently, the all-in-one setup is only supported through the 3.3.5 branch (Wrath of the Lich King).

## App Data Volume Setup
You will only expose one volume, which will contain subdirectories for various areas of data and configuration.  The only one you must create yourself is the `client` folder.  This folder will contain your WoW client files.

**NOTE:** Once the application has extracted the client data, you no longer need the `client` folder.

### Environment Variables
The only required variable is `EXTERNAL_ADDRESS`.  The container will still run without it set, but you will not be able to connect into your WoW server.

Most of the settings are MySQL connection variables.  Because the database is embedded, it is not necessary for you to touch any of them, but they are still exposed in case you wanted to tinker with an outside database that you configured on your own.

* **EXTERNAL_ADDRESS**: The external address of the machine.  If you're exposing this to the outside world, this is your real world IP address.
* **INTERNAL_ADDRESS**: Optional, defaults to the external address.  The internal address of the machine.  If you're not exposing this to the outside world, it can be the same as your external address.
* **MYSQL_USER**: Optional, defaults to `trinity`.  The MySQL username that the application uses.
* **MYSQL_PASSWORD**: Optional, defaults to `trinity`.  The MySQL password that the application uses.
* **MYSQL\_USER\_HOST**: Optional, defaults to `%`.  The scope of the MySQL username for connection purposes.
* **MYSQL_HOST**: Optional, defaults to `localhost`.  The hostname of the MySQL server
* **MYSQL_PORT**: Optional, defaults to `3306`.  The port of the MySQL server
* **MYSQL\_ROOT\_PASSWORD**: Optional, defaults to `root`.  The root password for the MySQL server

## Running Your Realm
To run in the all-in-one configuration, simply execute the container using the following model:

```
docker run -it \
	-v <APP DATA VOLUME>:/appdata \
	--name trinitycore -d \
	-p 8085:8085 -p 3724:3724 \
	-e EXTERNAL_ADDRESS=<IP ADDRESS> \
	fdrake/trinitycore:3.3.5-trinitybots
```
**NOTE:** Be sure to run your container with the `-it` parameter in order to allow interaction with your world server.

Assuming you're running this for the very first time, the following initialization will take place:

* Client data will be extracted out of the appdata `client` folder and stored into the appdata `client_data` folder
* The appdata `db_data` folder will be created and seeded with MySQL data, MySQL root password set, and seeded with TrinityCore data
* An appdata `logs` folder is created which houses the server's log files
* An appdata `config` folder is created, and passed in with default worldserver.conf and authserver.conf files.  The database, data directory and log directory configurations will be automatically adjusted so it will "just work" right out of the box

From there, the auth and world servers are kicked off and any SQL update files are applied by the application as normal.

## Accessing Your World Server
Once the container is initialized, you can access your world server directly through the following (assuming your container name is `trinitycore`):

```
docker attach trinitycore
```
To detach when you're finished, press `Control-P` then `Control-Q`.

### Admin Account Setup
Once attched into your world server instance, and use the following command to create an account:

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
The goal of was to streamline as much of the setup as possible within reason, but please refer to [the wiki](https://trinitycore.atlassian.net/wiki/spaces/tc/pages/2130077/Installation+Guide) for step by step details if you run into issues.
