FROM debian:10

ENV RT="rt-5.0.1"
ENV RT_SHA256="6c181cc592c48a2cba8b8df1d45fda0938d70f84ceeba1afc436f16a6090f556"

# libipc-run-perl is needed as is currently fails to build on debian
ENV RUNTIME_PACKAGES="tini ca-certificates spawn-fcgi getmail sendmail wget curl cpanminus gnupg graphviz libssl1.1 zlib1g libgd3 libexpat1 libpq5 perl-modules w3m elinks links html2text lynx openssl cron libipc-run-perl" \
  BUILD_PACKAGES="build-essential libssl-dev zlib1g-dev libgd-dev libexpat1-dev libpq-dev"

# Install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -q -y install --no-install-recommends $RUNTIME_PACKAGES \
  && apt-get -q -y install --no-install-recommends $BUILD_PACKAGES

# Set up environment
# do not ask CPAN questions
ENV PERL_MM_USE_DEFAULT="1"
# use cpanm for dependencies
ENV RT_FIX_DEPS_CMD="cpanm --self-contained --no-man-pages"

# Autoconfigure cpan
RUN echo q | /usr/bin/perl -MCPAN -e shell

# Create RT user
RUN useradd -Ms /bin/bash -d /opt/rt5 rt

# Install RT
RUN mkdir -p /src \
  # download and extract RT
  && wget -O /src/${RT}.tar.gz -nv https://download.bestpractical.com/pub/rt/release/${RT}.tar.gz \
  && echo "${RT_SHA256} /src/${RT}.tar.gz" | sha256sum -c - \
  && tar -C /src -xzf /src/${RT}.tar.gz \
  && rm -f /src/${RT}.tar.gz \
  && cd /src/${RT} \
  # configure with all plugins and with the newly created user
  && ./configure --with-db-type=Pg --enable-gpg --enable-gd --enable-graphviz --enable-smime --with-web-user=rt --with-web-group=rt --with-rt-group=rt --with-bin-owner=rt --with-libs-owner=rt \
  # move out of the dir as some following commands fail if we are in this directory after removing it later on
  && cd ${HOME} \
  # base dependencies
  # rt dependencies
  && make -C /src/${RT} fixdeps \
  && make -C /src/${RT} testdeps \
  && make -C /src/${RT} install \
  && cpanm --install RT::Extension::MergeUsers \
  # get rid of build packages
  && apt-get -q -y purge $BUILD_PACKAGES \
  && apt-get -q -y autoremove \
  && make -C /src/${RT} testdeps \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && rm -rf /root/.cpanm \
  && rm -rf /src/${RT} \
  # run a final dependency check as the purge above also removes some perl system modules that
  # might be needed
  && perl /opt/rt5/sbin/rt-test-dependencies

RUN mkdir -p /opt/rt5/var/data/gpg \
  && chown rt:rt /opt/rt5/var/data/gpg \
  && mkdir -p /opt/rt5/var/data/smime \
  && chown rt:rt /opt/rt5/var/data/smime \
  && mkdir -p /opt/rt5/etc/getmail \
  && chown rt:rt /opt/rt5/etc/getmail

# update PATH
ENV PATH="${PATH}:/opt/rt5/sbin"

EXPOSE 8080

USER rt

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD [ "spawn-fcgi", "-n", "-u", "rt", "-g", "rt", "-a", "0.0.0.0", "-p", "9000", "--", "/opt/rt5/sbin/rt-server.fcgi" ]
