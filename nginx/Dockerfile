FROM nginx:alpine

RUN apk add --no-cache bind-tools \
  && rm -rf /var/cache/apk \
  && mkdir -p /var/cache/apk

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY mailgate.conf /etc/nginx/conf.d/mailgate.conf
COPY full.conf /etc/nginx/full.conf
RUN rm -f /usr/share/nginx/html/index.html
