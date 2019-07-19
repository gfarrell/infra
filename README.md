# Gideon's Personal Infrastructure

This project is designed to implement and run my personal
infrastructure, which is composed of:

- GNU Mailman instance to run my mailing lists.
- Jenkins CI to build my projects.
- Nginx serving a couple of sites, and providing reverse-proxies for other
  services or projects.

All these services are run inside docker containers, defined in
`docker-compose.yml`.

## Services / Containers

### GNU Mailman

Mailman consists of three containers, `mailman-core`, `mailman-web`, and
`exim` (the MTA).

It's worth noting that to configure the list domains you need to edit
`exim/main_mm3_macros` as well as `exim/exim4-config.conf`. The local
subnet in `docker-compose.yml` also has to match the main relay nets in
`exim/exim4-config.conf`.

#### NOTES / TODO:

- [x] Exim configuration: change the config file to use the split config.
- [x] Exim configuration: reorder the routers so the mailman router comes earlier than dns looup.
- [x] Use ACL to stop exim acting as an open relay on the internet.
- [ ] Add SPF or something to stop emails being marked as spam.
- [ ] Abstract out some of the variables so they can be configured by `docker-compose`.

For access control we want to allow emails from the known subnet (i.e. mailman)
or for email addresses on our local relay domain, but not for anything else. We
should also drop the email if it's for a non-existent list.

### Jenkins CI

Jenkins runs simply in a container, fronted by an nginx reverse proxy.

### Nginx

This hosts the gtf.io website, both HTTP and HTTPS. It will also provide
reverse proxies for mailman and jenkins, and any other apps. The nginx
image needs the certificates from LetsEncrypt to be linked in as a
volume, as well as the site files which are uploaded to the server. Just
remember to ensure that there is a cronjob for LetsEncrypt:

    certbot renew --deploy-hook "docker restart infra_nginx_1"

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
