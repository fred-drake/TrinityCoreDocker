#!/bin/bash

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
	echo "Initializing database"
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
		MYSQL_HOST="host.docker.internal"
	fi
	if [ -z "$MYSQL_PORT" ]; then
		MYSQL_PORT="3306"
	fi
	if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
		MYSQL_ROOT_PASSWORD="root"
	fi

	cp ~/TrinityCore/sql/create/create_mysql.sql /tmp
	sed -i "s/'trinity'@'localhost'/'$MYSQL_USER'@'$MYSQL_USER_HOST'/g" /tmp/create_mysql.sql
	sed -i "s/IDENTIFIED BY 'trinity'/IDENTIFIED BY '$MYSQL_PASSWORD'/g" /tmp/create_mysql.sql

	mysql -h$MYSQL_HOST -uroot -P$MYSQL_PORT -p$MYSQL_ROOT_PASSWORD < /tmp/create_mysql.sql

	rm -f /tmp/create_mysql.sql
	
	exit 0
fi

if [ -z "$1" ]; then
	echo "You must have a parameter of --[worldserver|auth|builddata|dbinit]"
	exit 1
fi

exec "$@"
