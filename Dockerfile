FROM perl:latest as builder

ENV RT="rt-5.0.1"
ENV RT_SHA256="6c181cc592c48a2cba8b8df1d45fda0938d70f84ceeba1afc436f16a6090f556"

# use cpanm for dependencies
ENV RT_FIX_DEPS_CMD="cpanm --no-man-pages"

# Create RT user
RUN useradd -Ms /bin/bash -d /opt/rt5 rt

# Install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -q -y install --no-install-recommends \
  ca-certificates wget gnupg graphviz libssl1.1 zlib1g \
  libgd3 libexpat1 libpq5 w3m elinks links html2text lynx openssl libgd-dev

# Download and extract RT
RUN mkdir -p /src \
  # download and extract RT
  && wget -O /src/${RT}.tar.gz -nv https://download.bestpractical.com/pub/rt/release/${RT}.tar.gz \
  && echo "${RT_SHA256} /src/${RT}.tar.gz" | sha256sum -c - \
  && tar -C /src -xzf /src/${RT}.tar.gz \
  && rm -f /src/${RT}.tar.gz

# Configure RT
RUN cd /src/${RT} \
  # configure with all plugins and with the newly created user
  && ./configure --with-db-type=Pg --enable-gpg --enable-gd --enable-graphviz --enable-smime --with-web-user=rt --with-web-group=rt --with-rt-group=rt --with-bin-owner=rt --with-libs-owner=rt

# Install dependencies
RUN make -C /src/${RT} fixdeps \
  && make -C /src/${RT} testdeps \
  && make -C /src/${RT} install \
  && cpanm --install RT::Extension::MergeUsers

# cleanup
RUN rm -rf /root/.cpanm \
  && rm -rf /src/ \
  && rm -rf /tmp/* \
  && rm -rf /var/tmp/*

# run a final dependency check as the purge above also removes some perl system modules that
  # might be needed. Need to pass the with parameters here as we don't have the makefile here
RUN perl /opt/rt5/sbin/rt-test-dependencies --with-pg --with-fastcgi --with-gpg --with-graphviz --with-gd

RUN mkdir -p /opt/rt5/var/data/gpg \
  && chown rt:rt /opt/rt5/var/data/gpg \
  && mkdir -p /opt/rt5/var/data/smime \
  && chown rt:rt /opt/rt5/var/data/smime \
  && mkdir -p /opt/rt5/etc/getmail \
  && chown rt:rt /opt/rt5/etc/getmail

FROM perl:slim
COPY --from=builder /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=builder /opt/rt5 /opt/rt5

# Install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -q -y install --no-install-recommends \
  supervisor msmtp ca-certificates getmail wget curl gnupg graphviz libssl1.1 zlib1g \
  libgd3 libexpat1 libpq5 w3m elinks links html2text lynx openssl cron libgd-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Create RT user
RUN useradd -Ms /bin/bash -d /opt/rt5 rt

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

# update PATH
ENV PATH="${PATH}:/opt/rt5/sbin"

EXPOSE 9000

USER rt
WORKDIR /opt/rt5/

CMD [ "/usr/bin/supervisord" ]
