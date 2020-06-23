FROM centos:8

WORKDIR /tmp
RUN dnf install -y epel-release \
&&  dnf groupinstall -y "Development Tools" \
&& dnf install -y git wget net-tools sqlite-devel psmisc ncurses-devel libtermcap-devel newt-devel libxml2-devel libtiff-devel gtk2-devel libtool libuuid-devel subversion kernel-devel crontabs cronie-anacron mariadb mariadb-server
RUN git clone https://github.com/akheron/jansson.git \
&& cd jansson \
&& autoreconf -i \
&& ./configure --prefix=/usr/ \
&& make -j12 && make install
RUN cd /tmp \
&& git clone https://github.com/pjsip/pjproject.git \
&& cd pjproject \
&& ./configure CFLAGS="-DNDEBUG -DPJ_HAS_IPV6=1" --prefix=/usr --libdir=/usr/lib64 --enable-shared --disable-video --disable-sound --disable-opencore-amr \
&& make dep && make -j12 && make install 
RUN cd /tmp \
&& wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz \
&& tar -xf asterisk-16-current.tar.gz \
&& cd asterisk-16.11.1 \
&& ./contrib/scripts/install_prereq install \
&& ./contrib/scripts/get_mp3_source.sh \
&& dnf config-manager --set-enabled PowerTools \
&& dnf install -y libedit-devel \
&& ./configure --libdir=/usr/lib64 \
&& make -j12 \
&& ./menuselect/menuselect --enable format_mp3 --enable CORE-SOUNDS-RU-WAV --enable EXTRA-SOUNDS-EN-WAV \
&& make -j12 && make install && make samples && make config 
RUN groupadd asterisk \
&& useradd -r -d /var/lib/asterisk -g asterisk asterisk \
&& usermod -aG audio,dialout asterisk \
&& chown -R asterisk.asterisk /etc/asterisk /var/{lib,log,spool}/asterisk /usr/lib64/asterisk
RUN sed -i 's/TTY=9/TTY=/g' /usr/sbin/safe_asterisk
CMD /usr/sbin/asterisk -f -U asterisk -G asterisk -vvvg -c