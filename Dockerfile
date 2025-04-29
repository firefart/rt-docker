# syntax=docker/dockerfile:1

FROM debian:12-slim AS msmtp-builder

ENV MSMTP_VERSION="1.8.28"
ENV MSMTP_GPG_KEY="2F61B4828BBA779AECB3F32703A2A4AB1E32FD34"

# Install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -q -y install --no-install-recommends \
  wget ca-certificates libgnutls28-dev xz-utils \
  gpg dirmngr gpg-agent libgsasl-dev libsecret-1-dev \
  build-essential automake libtool gettext texinfo pkg-config

RUN wget -O /msmtp.tar.xz -nv https://marlam.de/msmtp/releases/msmtp-${MSMTP_VERSION}.tar.xz \
  && wget -O /msmtp.tar.xz.sig -nv https://marlam.de/msmtp/releases/msmtp-${MSMTP_VERSION}.tar.xz.sig \
  && gpg --keyserver hkps://keyserver.ubuntu.com --keyserver-options timeout=10 --recv-keys ${MSMTP_GPG_KEY} \
  && gpg --verify /msmtp.tar.xz.sig /msmtp.tar.xz \
  && tar -xf /msmtp.tar.xz \
  && cd /msmtp-${MSMTP_VERSION} \
  && ./configure --sysconfdir=/etc \
  && make \
  && make install

#############################################################################

FROM perl:5.40.2 AS builder

ENV RT="5.0.8"
ENV RTIR="5.0.6"
ENV RT_GPG_KEY="C49B372F2BF84A19011660270DF0A283FEAC80B2"

ARG ADDITIONAL_CPANM_ARGS=""

# use cpanm for dependencies
ENV RT_FIX_DEPS_CMD="cpanm --no-man-pages ${ADDITIONAL_CPANM_ARGS}"
# cpan non interactive mode
ENV PERL_MM_USE_DEFAULT=1

# Create RT user
RUN groupadd -g 1000 rt && useradd -u 1000 -g 1000 -Ms /bin/bash -d /opt/rt5 rt

# Install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -q -y install --no-install-recommends \
  ca-certificates wget gnupg graphviz libssl3 zlib1g \
  gpg dirmngr gpg-agent \
  libgd3 libexpat1 libpq5 w3m elinks links html2text lynx openssl libgd-dev

# Download and extract RT
RUN mkdir -p /src \
  # import RT signing key
  && gpg --keyserver hkps://keyserver.ubuntu.com --keyserver-options timeout=10 --recv-keys ${RT_GPG_KEY} \
  # download and extract RT
  && wget -O /src/rt.tar.gz -nv https://download.bestpractical.com/pub/rt/release/rt-${RT}.tar.gz \
  && wget -O /src/rt.tar.gz.asc -nv https://download.bestpractical.com/pub/rt/release/rt-${RT}.tar.gz.asc \
  && gpg --verify /src/rt.tar.gz.asc /src/rt.tar.gz \
  && mkdir -p /src/rt \
  && tar --strip-components=1 -C /src/rt -xzf /src/rt.tar.gz \
  # download and extract RTIR
  && wget -O /src/rtir.tar.gz -nv https://download.bestpractical.com/pub/rt/release/RT-IR-${RTIR}.tar.gz \
  && wget -O /src/rtir.tar.gz.asc -nv https://download.bestpractical.com/pub/rt/release/RT-IR-${RTIR}.tar.gz.asc \
  && gpg --verify /src/rtir.tar.gz.asc /src/rtir.tar.gz \
  && mkdir -p /src/rtir \
  && tar --strip-components=1 -C /src/rtir -xzf /src/rtir.tar.gz

# Configure RT
RUN cd /src/rt \
  # configure with all plugins and with the newly created user
  && ./configure --with-db-type=Pg --enable-gpg --enable-gd --enable-graphviz --enable-smime --enable-externalauth --with-web-user=rt --with-web-group=rt --with-rt-group=rt --with-bin-owner=rt --with-libs-owner=rt

# install https support for cpanm
RUN cpanm --no-man-pages install LWP::Protocol::https

# Install Sever::Starter without tests
# as they constanly fail with timeouts and thus break
# the build
# Also install CSS::Inliner so users can use $EmailDashboardInlineCSS
RUN cpanm --no-man-pages -n install Server::Starter CSS::Inliner

# Install dependencies
RUN make -C /src/rt fixdeps \
  && make -C /src/rt testdeps \
  && make -C /src/rt install \
  # https://metacpan.org/pod/RT::Extension::MergeUsers
  && cpanm --install --no-man-pages ${ADDITIONAL_CPANM_ARGS} RT::Extension::MergeUsers \
  # https://metacpan.org/pod/RT::Extension::TerminalTheme
  && cpanm --install --no-man-pages ${ADDITIONAL_CPANM_ARGS} RT::Extension::TerminalTheme \
  # https://metacpan.org/pod/RT::Extension::Announce
  && cpanm --install --no-man-pages ${ADDITIONAL_CPANM_ARGS} RT::Extension::Announce \
  # https://metacpan.org/pod/RT::Extension::Assets::Import::CSV
  && cpanm --install --no-man-pages ${ADDITIONAL_CPANM_ARGS} RT::Extension::Assets::Import::CSV \
  # https://metacpan.org/pod/RT::Extension::ExcelFeed
  && cpanm --install --no-man-pages ${ADDITIONAL_CPANM_ARGS} RT::Extension::ExcelFeed \
  # https://metacpan.org/pod/RT::Extension::Import::CSV
  && cpanm --install --no-man-pages ${ADDITIONAL_CPANM_ARGS} RT::Extension::Import::CSV \
  # https://github.com/bestpractical/app-wsgetmail
  # https://metacpan.org/dist/App-wsgetmail
  && cpanm --install --no-man-pages ${ADDITIONAL_CPANM_ARGS} App::wsgetmail

# Configure RTIR
RUN cd /src/rtir \
  && perl -I /src/rtir/lib Makefile.PL --defaultdeps \
  && make install

#############################################################################

FROM perl:5.40.2-slim
LABEL org.opencontainers.image.authors="firefart <firefart@gmail.com>"
LABEL org.opencontainers.image.title="Request Tracker"
LABEL org.opencontainers.image.source="https://github.com/firefart/rt-docker"
LABEL org.opencontainers.image.description="Request Tracker Docker Setup"

# Install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -q -y install --no-install-recommends \
  procps spawn-fcgi ca-certificates getmail6 wget curl gnupg graphviz libssl3 \
  zlib1g libgd3 libexpat1 libpq5 w3m elinks links html2text lynx openssl cron bash \
  libfcgi-bin libgsasl18 libsecret-1-0 tzdata \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
# msmtp - disabled for now to use the newer version

# Create RT user
RUN useradd -u 1000 -Ms /bin/bash -d /opt/rt5 rt

# copy msmtp
COPY --from=msmtp-builder /usr/local/bin/msmtp /usr/bin/msmtp
COPY --from=msmtp-builder  /usr/local/share/locale /usr/local/share/locale

# copy all needed stuff from the builder image
COPY --from=builder /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=builder /opt/rt5 /opt/rt5
# run a final dependency check if we copied all
RUN perl /opt/rt5/sbin/rt-test-dependencies --with-pg --with-fastcgi --with-gpg --with-graphviz --with-gd

# msmtp config
RUN mkdir /msmtp \
  && chown rt:rt /msmtp \
  # also fake sendmail for cronjobs
  && ln -s /usr/bin/msmtp /usr/sbin/sendmail

# getmail
RUN mkdir -p /getmail \
  && chown rt:rt /getmail

# gpg
RUN mkdir -p /opt/rt5/var/data/gpg \
  && chown rt:rt /opt/rt5/var/data/gpg

# smime
RUN mkdir -p /opt/rt5/var/data/smime \
  && chown rt:rt /opt/rt5/var/data/smime

# shredder dir
RUN mkdir -p /opt/rt5/var/data/RT-Shredder \
  && chown rt:rt /opt/rt5/var/data/RT-Shredder

# RTIR Database stuff for setup
COPY --chown=rt:rt --from=builder /src/rtir/etc /opt/rtir

# wsgetmail
COPY --chown=rt:rt --from=builder /usr/local/bin/wsgetmail /usr/local/bin/wsgetmail

# remove default cron jobs
RUN rm -f /etc/cron.d/* \
  && rm -f /etc/cron.daily/* \
  && rm -f /etc/cron.hourly/* \
  && rm -f /etc/cron.monthly/* \
  && rm -f /etc/cron.weekly/* \
  && rm -f /var/spool/cron/crontabs/*

COPY --chown=root:root --chmod=0700 cron_entrypoint.sh /root/cron_entrypoint.sh

# update PATH
ENV PATH="${PATH}:/opt/rt5/sbin:/opt/rt5/bin"

EXPOSE 9000

USER rt
WORKDIR /opt/rt5/

# spawn-fcgi v1.6.4 (ipv6) - spawns FastCGI processes

# Options:
#  -f <path>      filename of the fcgi-application (deprecated; ignored if
#                 <fcgiapp> is given; needs /bin/sh)
#  -d <directory> chdir to directory before spawning
#  -a <address>   bind to IPv4/IPv6 address (defaults to 0.0.0.0)
#  -p <port>      bind to TCP-port
#  -s <path>      bind to Unix domain socket
#  -M <mode>      change Unix domain socket mode (octal integer, default: allow
#                 read+write for user and group as far as umask allows it)
#  -C <children>  (PHP only) numbers of childs to spawn (default: not setting
#                 the PHP_FCGI_CHILDREN environment variable - PHP defaults to 0)
#  -F <children>  number of children to fork (default 1)
#  -b <backlog>   backlog to allow on the socket (default 1024)
#  -P <path>      name of PID-file for spawned process (ignored in no-fork mode)
#  -n             no fork (for daemontools)
#  -v             show version
#  -?, -h         show this help
# (root only)
#  -c <directory> chroot to directory
#  -S             create socket before chroot() (default is to create the socket
#                 in the chroot)
#  -u <user>      change to user-id
#  -g <group>     change to group-id (default: primary group of user if -u
#                 is given)
#  -U <user>      change Unix domain socket owner to user-id
#  -G <group>     change Unix domain socket group to group-id
CMD [ "/usr/bin/spawn-fcgi", "-d", "/opt/rt5/", "-p" ,"9000", "-a","0.0.0.0", "-u", "1000", "-n", "--", "/opt/rt5/sbin/rt-server.fcgi" ]

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 CMD REQUEST_METHOD=GET REQUEST_URI=/ SCRIPT_NAME=/ cgi-fcgi -connect localhost:9000 -bind || exit 1
