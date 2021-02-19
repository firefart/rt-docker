# RT

openssl req -x509 -newkey rsa:4096 -keyout priv.pem -out pub.pem -days 3650 -nodes

TODO:
chown nobody:nobody on RT_SiteConfig.pm and gpg data files

docker-compose -f docker-compose.yml -f docker-compose.prod.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action upgrade --upgrade-from 4.4.4' | tee output.txt

Run multiple times until no errors:
docker-compose -f docker-compose.yml -f docker-compose.prod.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-validator --check' | tee output.txt
