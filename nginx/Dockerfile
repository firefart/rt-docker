FROM nginx:alpine

RUN apk add --no-cache bind-tools \
  && rm -rf /var/cache/apk \
  && mkdir -p /var/cache/apk

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY mailgate.conf /etc/nginx/conf.d/mailgate.conf
COPY healthcheck.conf /etc/nginx/conf.d/healthcheck.conf
COPY full.conf /etc/nginx/full.conf
RUN rm -f /usr/share/nginx/html/index.html

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 CMD curl -f http://localhost:9001/health || exit 1
