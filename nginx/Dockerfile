FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY mailgate.conf /etc/nginx/conf.d/mailgate.conf
RUN rm -f /usr/share/nginx/html/index.html
