FROM debian:10

ENV RUNTIME_PACKAGES="cpanminus gnupg graphviz libssl1.1 zlib1g libgd3 libexpat1 libpq5 perl-modules w3m elinks links html2text lynx" \
  BUILD_PACKAGES="build-essential wget libssl-dev zlib1g-dev libgd-dev libexpat1-dev libpq-dev"

# Install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -q -y install $RUNTIME_PACKAGES \
  && apt-get -q -y install $BUILD_PACKAGES

# Set up environment
# do not ask CPAN questions
ENV PERL_MM_USE_DEFAULT 1
ENV HOME /root
ENV RT rt-5.0.1
ENV RT_SHA256 6c181cc592c48a2cba8b8df1d45fda0938d70f84ceeba1afc436f16a6090f556
ENV RT_USER rt

# Autoconfigure cpan
RUN echo q | /usr/bin/perl -MCPAN -e shell

# Create RT user
RUN useradd -ms /bin/bash ${RT_USER}

# Install RT
RUN mkdir -p /src \
  && wget -O /src/${RT}.tar.gz -nv https://download.bestpractical.com/pub/rt/release/${RT}.tar.gz \
  && echo "${RT_SHA256} /src/${RT}.tar.gz" | sha256sum -c - \
  && tar -C /src -xzf /src/${RT}.tar.gz \
  && rm -f /src/${RT}.tar.gz \
  && cd /src/${RT} \
  && ./configure --with-db-type=Pg --enable-gpg --enable-gd --enable-graphviz --with-web-user=${RT_USER} \
  && cpanm --install LWP::Protocol::https IO::Socket::SSL Net::SSLeay HTML::FormatText HTML::TreeBuilder HTML::FormatText::WithLinks HTML::FormatText::WithLinks::AndTables \
  && make -C /src/${RT} fixdeps \
  && make -C /src/${RT} testdeps \
  && make -C /src/${RT} install \
  && cpanm --install RT::Extension::MergeUsers

RUN apt-get -q -y purge $BUILD_PACKAGES \
  && apt-get -q -y autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /opt/rt5/var/data/gpg

EXPOSE 8080

USER rt

CMD [ "/opt/rt5/sbin/rt-server", "--port", "8080"]
