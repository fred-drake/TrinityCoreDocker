FROM debian:10

RUN apt-get update && \
	apt-get install -y git clang cmake make gcc g++ libmariadbclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev \
			libboost-all-dev mariadb-server p7zip default-libmysqlclient-dev wget nodejs && \
	update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 && \
	update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang 100 && \
	rm -rf /var/lib/apt/lists/*

ARG trinitycore_branch=master
ARG latest_commit=b1eb4c2b3e0745e0d801bfa4111c692cc3bb00a1

RUN cd ~/ && \
	git clone -b $trinitycore_branch --depth 1 git://github.com/TrinityCore/TrinityCore.git && \
	cd ~/TrinityCore && \
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
	wget `node /get_tdb_release.js path $trinitycore_branch` && \
	7zr x `node /get_tdb_release.js file $trinitycore_branch` && \
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

RUN apt-get remove -y git clang cmake make gcc g++ libmariadbclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev \
		libboost-all-dev mariadb-server p7zip default-libmysqlclient-dev wget nodejs

VOLUME /data
VOLUME /config
VOLUME /logs

ADD entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
