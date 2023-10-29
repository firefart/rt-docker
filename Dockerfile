FROM debian:12-slim as msmtp-builder

ENV MSMTP_VERSION="1.8.25"
ENV MSMTP_GPG_KEY="2F61B4828BBA779AECB3F32703A2A4AB1E32FD34"

# Install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -q -y install --no-install-recommends \
  wget ca-certificates libgnutls28-dev xz-utils \
  gpg dirmngr gpg-agent \
  build-essential automake libtool gettext texinfo pkg-config

RUN wget -O /msmtp.tar.xz -nv https://marlam.de/msmtp/releases/msmtp-${MSMTP_VERSION}.tar.xz \
  && wget -O /msmtp.tar.xz.sig -nv https://marlam.de/msmtp/releases/msmtp-${MSMTP_VERSION}.tar.xz.sig \
  && gpg --keyserver hkps://keyserver.ubuntu.com --keyserver-options timeout=10 --recv-keys ${MSMTP_GPG_KEY} \
  && gpg --verify /msmtp.tar.xz.sig /msmtp.tar.xz \
  && tar -xf /msmtp.tar.xz \
  && cd /msmtp-${MSMTP_VERSION} \
  && autoreconf -i \
  && ./configure --sysconfdir=/etc \
  && make \
  && make install

#############################################################################

FROM perl:5.39 as builder

ENV RT="5.0.5"
ENV RTIR="5.0.4"
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

# Install Sever::Starter without tests
# as they constanly fail with timeouts and thus break
# the build
# Also install CSS::Inliner so users can use $EmailDashboardInlineCSS
RUN cpanm --no-man-pages -n install Server::Starter CSS::Inliner

# Install dependencies
RUN make -C /src/rt fixdeps \
  && make -C /src/rt testdeps \
  && make -C /src/rt install \
  && cpanm --install RT::Extension::MergeUsers \
  && cpanm --install RT::Extension::TerminalTheme

# Configure RTIR
RUN cd /src/rtir \
  && perl -I /src/rtir/lib Makefile.PL --defaultdeps \
  && make install

#############################################################################

FROM perl:5.39-slim
LABEL org.opencontainers.image.authors="firefart <firefart@gmail.com>"
LABEL org.opencontainers.image.title="Request Tracker"
LABEL org.opencontainers.image.source="https://github.com/firefart/rt-docker"
LABEL org.opencontainers.image.description="Request Tracker Docker Setup"

# Install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -q -y install --no-install-recommends \
  procps supervisor ca-certificates getmail6 wget curl gnupg graphviz libssl3 \
  zlib1g libgd3 libexpat1 libpq5 w3m elinks links html2text lynx openssl cron bash \
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

# supervisord config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor/ \
  && chown rt:rt /var/log/supervisor/ \
  && mkdir -p /var/run/supervisord \
  && chown rt:rt /var/run/supervisord

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

CMD [ "/usr/bin/supervisord" ]
