# Gideon's Personal Infrastructure

This project is designed to implement and run my personal
infrastructure, which is composed of:

- GNU Mailman instance to run my mailing lists.
- Drone.io CI to build my projects.
- Nginx serving a couple of sites, and providing reverse-proxies for other
  services or projects.

All these services are run inside docker containers, defined in
`docker-compose.yml`. Note that this requires a `.env` file with some
secrets.

## Services / Containers

### GNU Mailman

Mailman consists of three containers, `mailman-core`, `mailman-web`, and
`exim` (the MTA).

It's worth noting that to configure the list domains you need to edit
`exim/main_mm3_macros` as well as `exim/exim4-config.conf`. The local
subnet in `docker-compose.yml` also has to match the main relay nets in
`exim/exim4-config.conf`.

You will also need to add DKIM keys to `/var/secure/exim-keys` (and make sure
they have the right permissions):

    mkdir -p /var/secure/exim-keys
    cd /var/secure/exim-keys
    openssl genrsa -out dkim.private.key 1024
    openssl rsa -in dkim.private.key -out dkim.public.key -pubout -outform PEM

Finally, for this to work, add the following records to DNS:

    x._domainkey.<domain>. TXT v=DKIM1; t=y; k=rsa; p=<public key>
    _domainkey.<domain>. TXT _domainkey.example.com. t=y; o=~;

Remove the `t=y` when everything is confirmed to work. That key pair
should ideally not change, and don't forget to also add spf records:

    v=spf1 mx a a:infra.gtf.io ip4:67.207.69.43 -all

This is a useful guide for [DKIM with
exim](https://mikepultz.com/2010/02/using-dkim-in-exim/).

#### NOTES / TODO:

- [x] Exim configuration: change the config file to use the split config.
- [x] Exim configuration: reorder the routers so the mailman router comes earlier than dns looup.
- [x] Use ACL to stop exim acting as an open relay on the internet.
- [x] Add SPF or something to stop emails being marked as spam.
- [ ] Abstract out some of the variables so they can be configured by `docker-compose`.

For access control we want to allow emails from the known subnet (i.e. mailman)
or for email addresses on our local relay domain, but not for anything else. We
should also drop the email if it's for a non-existent list.

### Drone.io CI

Drone runs simply in a container, fronted by an nginx reverse proxy.

### Nginx

This hosts the gtf.io website, both HTTP and HTTPS. It will also provide
reverse proxies for mailman and drone.io, and any other apps. The nginx
image needs the certificates from LetsEncrypt to be linked in as a
volume, as well as the site files which are uploaded to the server. Just
remember to ensure that there is a cronjob for LetsEncrypt:

    certbot renew --deploy-hook "docker restart infra_nginx_1"

To create the certificates for the first time, given the server setup I'm using,
run this:

    certbot certonly --webroot -w /var/www/<service>-acme -d <service>.gtf.io

#### NOTES / TODO:

- [ ] add scripts for setting up letsencrypt/certbot properly (incl webroots)

## Provisioning / Setup

### Server setup

### Deploying changes

    SERVER_ADDRESS=<SERVER ADDRESS> make deploy

This script rsyncs the entire infrastructure folder to ~/infra on the
remote, then runs docker compose to down and re-up (including building)
the services. This does, of course, pose a problem in that if a service
is removed from `docker-compose.yml`, it won't be downed and you might
have to manually do so.

#### NOTES / TODO:

- [ ] Down services before transferring data with rsync (this will increase the
  downtime but is maybe worthwhile).
- [ ] Add server setup scripts to automate provisioning (ssh config, user setup,
  docker install, security, cronjobs, etc.).
