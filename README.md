# Gideon's Personal Infrastructure

This project is designed to implement and run my personal infrastructure, which
is composed of:

* GNU Mailman instance to run my mailing lists
* Jenkins CI to build my projects
* Nginx serving a couple of static sites

All these services are run inside docker containers.

## Services / Containers

### GNU Mailman

Mailman consists of three containers, `mailman-core`, `mailman-web`, and `exim`
(the MTA).

It's worth noting that to configure the list domains you need to edit
`exim/25_mm3_macros`.

### Jenkins CI

// TODO

### Nginx

This hosts the gtf.io website, both HTTP and HTTPS. It will also provide
reverse proxies for mailman and jenkins, and any other apps. The nginx
image needs the certificates from LetsEncrypt to be linked in as a
volume, as well as the site files which are uploaded to the server. Just
remember to ensure that there is a cronjob for LetsEncrypt:

    certbot renew --deploy-hook "docker restart infra_nginx_1"

## Provisioning / Setup

// TODO
