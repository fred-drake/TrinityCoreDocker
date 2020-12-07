FROM debian:10

RUN apt-get update && \
	apt-get install -y git clang cmake make gcc g++ libmariadbclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev \
			libboost-all-dev mariadb-server p7zip default-libmysqlclient-dev wget nodejs && \
	update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 && \
	update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang 100 && \
	rm -rf /var/lib/apt/lists/*

ARG trinitycore_branch=3.3.5
ARG latest_commit=cfb585de1a94018b3ddfed7d6ec67a57ceefa900
ARG trinity_bot_commit=24a2cbc028b1f3f6a4cf84360ad98b8680fb1483
ARG trinitycore_commit=c2a0b78a051ea3301d8769b2c11fae00e14fe095

RUN cd ~/ && \
	git clone git://github.com/trickerer/Trinity-Bots.git && \
	cd ~/Trinity-Bots && git checkout $trinity_bot_commit && cd ~/ && \
	git clone -b $trinitycore_branch git://github.com/TrinityCore/TrinityCore.git && \
	cd ~/TrinityCore && git checkout $trinitycore_commit && \
	cp ~/Trinity-Bots/last/NPCBots.patch . && \
	mv ~/Trinity-Bots/last/SQL sql/Trinity-Bots && \
	cp sql/Trinity-Bots/updates/characters/* sql/updates/characters/$trinitycore_branch && \
	cp sql/Trinity-Bots/updates/world/* sql/updates/world/$trinitycore_branch && \
	rm -rf ~/Trinity-Bots && \
	patch -p1 < NPCBots.patch && \
	mkdir build && \
	cd build && \
	cmake ../ -DCMAKE_INSTALL_PREFIX=/server && \
	make -j $(nproc) install && \
	cd .. && \
	mv sql .. && \
	rm -rf * && \
	mv ../sql .

ADD get_tdb_release.js /
RUN mkdir ~/TDB && \
	cd ~/TDB && \
	wget https://github.com/TrinityCore/TrinityCore/releases/download/TDB335.20101/TDB_full_world_335.20101_2020_10_15.7z && \
	7zr x TDB_full_world_335.20101_2020_10_15.7z && \
	mv *.sql /server/bin && \
	cd / && \
	rm -rf ~/TDB && \
	rm -f /get_tdb_release.js
RUN mkdir ~/unrar && \
	cd ~/unrar && \
	wget http://www.rarlab.com/rar/unrarsrc-5.8.3.tar.gz && \
	tar zxvf unrarsrc-5.8.3.tar.gz && \
	cd unrar && \
	make -f makefile && \
	install -v -m755 unrar /usr/bin && \
	cd / && \
	rm -rf ~/unrar

RUN sed -i "s/\/var\/lib\/mysql/\/appdata\/db_data/g" /etc/mysql/mariadb.conf.d/50-server.cnf
#ADD dblockdown.sh /
#RUN export DEBIAN_FRONTEND=noninteractive && /dblockdown.sh

#RUN ["/bin/bash", "-c", "debconf-set-selections <<< 'mariadb-server-10.3 mysql-server/root_password password rootpass'"]
#RUN ["/bin/bash", "-c", "debconf-set-selections <<< 'mariadb-server-10.3 mysql-server/root_password_again password rootpass'"]
#RUN apt-get -y install mariadb-server-10.3

#ADD mysql57debsetup.sh /
#RUN export DEBIAN_FRONTEND=noninteractive && \
#	/mysql57debsetup.sh

#RUN apt-get update && apt-get install -y lsb-release gnupg && \
#	wget http://dev.mysql.com/get/mysql-apt-config_0.8.16-1_all.deb && \
#	dpkg -i mysql-apt-config_0.8.16-1_all.deb && \
#	apt-get update && \
#	apt-get install -y mysql-server && \
#	rm -rf /var/lib/apt/lists/*

RUN apt-get remove -y git clang cmake make gcc g++ libmariadbclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev \
		libboost-all-dev mariadb-server p7zip default-libmysqlclient-dev wget nodejs

#VOLUME /data
#VOLUME /config
#VOLUME /logs
VOLUME /appdata

ADD entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
