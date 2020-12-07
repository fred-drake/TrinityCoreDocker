#!/bin/bash

function db_init {
	echo "Initializing database"
	cp ~/TrinityCore/sql/create/create_mysql.sql /tmp
	sed -i "s/'trinity'@'localhost'/'$MYSQL_USER'@'$MYSQL_USER_HOST'/g" /tmp/create_mysql.sql
	sed -i "s/IDENTIFIED BY 'trinity'/IDENTIFIED BY '$MYSQL_PASSWORD'/g" /tmp/create_mysql.sql

	mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD < /tmp/create_mysql.sql
	
	rm -f /tmp/create_mysql.sql
}

# Initialize variables
ALL_IN_ONE=true
if [ -z "$MYSQL_USER" ]; then
	MYSQL_USER="trinity"
fi
if [ -z "$MYSQL_PASSWORD" ]; then
	MYSQL_PASSWORD="trinity"
fi
if [ -z "$MYSQL_USER_HOST" ]; then
	MYSQL_USER_HOST="%"
fi
if [ -z "$MYSQL_HOST" ]; then
	MYSQL_HOST="localhost"
fi
if [ -z "$MYSQL_PORT" ]; then
	MYSQL_PORT="3306"
fi
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
	MYSQL_ROOT_PASSWORD="root"
fi
if [ -z "$EXTERNAL_ADDRESS" ]; then
	EXTERNAL_ADDRESS="127.0.0.1"
fi
if [ -z "$INTERNAL_ADDRESS" ]; then
	INTERNAL_ADDRESS="$EXTERNAL_ADDRESS"
fi


if [ "$ALL_IN_ONE" = true ] && [ -z "$1" ]; then
	# Start with a number of checks to see if the server is initialized, starting with the WoW client data.
	# If the data folder exists and has anything in it then we assume a data check has been performed.
	[ ! -d "/appdata/client_data" ] && mkdir /appdata/client_data

	if [ -z "$(ls -A /appdata/client_data)" ]; then
		# We need to populate the data directory using the WoW client found in /appdata/client.
		[ ! -d "/appdata/client" ] && mkdir /appdata/client
		if [ -z "$(ls -A /appdata/client)" ]; then
			echo "Data needs to be compiled from the WoW client but the client cannot be found."
			echo "Copy the contents of the WoW client into your app data's /client directory, then re-run this."
			exit 1
		fi
		
		echo "Extracting data from WoW client..."
		cd /appdata/client && \
			/server/bin/mapextractor && \
			cp -r dbc maps /appdata/client_data && \
			/server/bin/vmap4extractor && \
			mkdir vmaps && \
			/server/bin/vmap4assembler Buildings vmaps && \
			cp -r vmaps /appdata/client_data && \
			mkdir mmaps && \
			/server/bin/mmaps_generator && \
			cp -r mmaps /appdata/client_data && \
			cp -r Cameras /appdata/client_data && \
			rm -rf dbc Cameras maps Buildings vmaps mmaps
		echo "Data extraction complete."
	fi

	# Check if the database data directory exists, and initialize it if not.
	DB_NEEDS_SECURE=false
	if [ ! -d "/appdata/db_data" ]; then
		echo "The DB data directory doesn't exist.  Creating and seeding with MySQL data."
		cp -a /var/lib/mysql /appdata/db_data
		DB_NEEDS_SECURE=true
	fi

	echo "Starting database..."
	service mysql start
	if [ "$DB_NEEDS_SECURE" = true ]; then
		echo "Database is new.  Securing with root password."
		mysqladmin -h $MYSQL_HOST -u root password $MYSQL_ROOT_PASSWORD
	fi

	WORLD_EXISTS=`mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD -e "show databases" | grep world | wc -l`
	if [ "$WORLD_EXISTS" == 0 ]; then
		echo "Database is empty.  Initializing."
		db_init

		echo "Applying auth database schema..."
		mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD auth < /root/TrinityCore/sql/base/auth_database.sql
		echo "Applying characters database schema..."
		mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD characters < /root/TrinityCore/sql/base/characters_database.sql
		echo "Applying world database schema..."
		mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD world < /server/bin/TDB*sql
		echo "Applying Trinity Bots schemas..."
		mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD world < /root/TrinityCore/sql/Trinity-Bots/1_world_bot_appearance.sql
		mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD world < /root/TrinityCore/sql/Trinity-Bots/2_world_bot_extras.sql
		mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD world < /root/TrinityCore/sql/Trinity-Bots/3_world_bots.sql
		mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD world < /root/TrinityCore/sql/Trinity-Bots/4_world_generate_bot_equips.sql
		mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD world < /root/TrinityCore/sql/Trinity-Bots/5_world_botgiver.sql
		mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD characters < /root/TrinityCore/sql/Trinity-Bots/characters_bots.sql
		echo "Schema creation complete."

	fi

	[ ! -d "/appdata/logs" ] && mkdir /appdata/logs
	[ ! -d "/appdata/config" ] && mkdir /appdata/config
	if [ ! -f /appdata/config/worldserver.conf ]; then
		echo "Creating default worldserver.conf file in appdata /config directory"
		cp /server/etc/worldserver.conf.dist /appdata/config/worldserver.conf
		sed -i "s/DataDir.*/DataDir = \"\/appdata\/client_data\"/g" /appdata/config/worldserver.conf
		sed -i "s/LogsDir.*/LogsDir = \"\/appdata\/logs\"/g" /appdata/config/worldserver.conf
		sed -i "s/LoginDatabaseInfo.*/LoginDatabaseInfo     = \"$MYSQL_HOST;$MYSQL_PORT;$MYSQL_USER;$MYSQL_PASSWORD;auth\"/g" /appdata/config/worldserver.conf
		sed -i "s/WorldDatabaseInfo.*/WorldDatabaseInfo     = \"$MYSQL_HOST;$MYSQL_PORT;$MYSQL_USER;$MYSQL_PASSWORD;world\"/g" /appdata/config/worldserver.conf
		sed -i "s/CharacterDatabaseInfo.*/CharacterDatabaseInfo = \"$MYSQL_HOST;$MYSQL_PORT;$MYSQL_USER;$MYSQL_PASSWORD;characters\"/g" /appdata/config/worldserver.conf
	fi
	if [ ! -f /appdata/config/authserver.conf ]; then
		echo "Creating default authserver.conf file in appdata /config directory"
		cp /server/etc/authserver.conf.dist /appdata/config/authserver.conf
		sed -i "s/LoginDatabaseInfo.*/LoginDatabaseInfo     = \"$MYSQL_HOST;$MYSQL_PORT;$MYSQL_USER;$MYSQL_PASSWORD;auth\"/g" /appdata/config/authserver.conf
		sed -i "s/LogsDir.*/LogsDir = \"\/appdata\/logs\"/g" /appdata/config/authserver.conf
	fi

	echo "Setting IP addresses (external: $EXTERNAL_ADDRESS, internal: $INTERNAL_ADDRESS)..."
	mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD auth -e "update realmlist set address = '$EXTERNAL_ADDRESS', localAddress = '$INTERNAL_ADDRESS'"

	cd /server/bin
	echo "Initiating auth server..."
	./authserver -c /appdata/config/authserver.conf &
	sleep 5
	echo "Initiating world server..."
        ./worldserver -c /appdata/config/worldserver.conf

	exit 0
fi

if [ "$1" == "--worldserver" ]; then
	echo "Initiating world server"
	cd /server/bin && ./worldserver -c /config/worldserver.conf
	exit 0
fi

if [ "$1" == "--authserver" ]; then
	echo "Initiating auth server"
	cd /server/bin && ./authserver -c /config/authserver.conf
	exit 0
fi

if [ "$1" == "--builddata" ]; then
	echo "Building data from WoW client"
	if [ ! -d "/wowclient" ]; then
		echo "The WoW client must be mounted under /wowclient in order to extract data"
		exit 1
	fi
	if [ ! -d "/data" ]; then
		echo "A volume just be mounted under /data to store the data to be extracted from the WoW client"
		exit 1
	fi

	cd /wowclient && \
		/server/bin/mapextractor && \
		cp -r dbc maps /data && \
		/server/bin/vmap4extractor && \
		mkdir vmaps && \
		/server/bin/vmap4assembler Buildings vmaps && \
		cp -r vmaps /data && \
		mkdir mmaps && \
		/server/bin/mmaps_generator && \
		cp -r mmaps /data && \
		cp -r Cameras /data && \
		rm -rf dbc Cameras maps Buildings vmaps mmaps
	exit 0
fi

if [ "$1" == "--dbinit" ]; then
	db_init
	exit 0
fi

if [ -z "$1" ]; then
	echo "You must have a parameter of --[worldserver|auth|builddata|dbinit]"
	exit 1
fi

exec "$@"
