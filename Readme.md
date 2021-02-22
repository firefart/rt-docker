# RT

## Create Certificate and put it in ./nginx/certs

openssl req -x509 -newkey rsa:4096 -keyout priv.pem -out pub.pem -days 3650 -nodes

## Init database

```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action init'
```

Hint: Add `--skip-create` in dev

## Updgrade steps

### Upgrade Database

```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action upgrade --upgrade-from 4.4.4' | tee output.txt
```

### Fix data inconsitencies

Run multiple times until no errors occur

```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-validator --check' | tee output.txt
```

## TODO:

chown nobody:nobody on RT_SiteConfig.pm and gpg data files
