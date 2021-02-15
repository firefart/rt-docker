# RT

openssl req -x509 -newkey rsa:4096 -keyout priv.pem -out pub.pem -days 3650 -nodes

TODO:
chown nobody:nobody on RT_SiteConfig.pm and gpg data files
