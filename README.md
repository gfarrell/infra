# Gideon's Personal Infrastructure

My infrastructure is setup as a nix flake, with each host configured as a separate `nixosConfiguration` using `flake-parts`. A `justfile` contains common commands like building and deploying.

## What's in here?

### Pharos

Pharos, named after the lighthouse at Alexandria, hosts public-facing services, currently just the gtf.io website while I work out how to do other things.

* [gtf-io](https://github.com/gfarrell/gtf-io)

## Usage

### Creating a new host droplet on digitalocean

1. Build the virtual image for the host: `just make-image HOST`
2. Upload the image from `./result/nixos.qcow.gz` to digitalocean cloud.digitalocean.com/images
3. Create a new droplet with this image
4. Point HOST.gtf.io at that droplet

### Building the host configuration

    just make-config HOST

### Update the service dependencies

Things like the gtf.io website need to be explicitly updated in the flake.lock file before you will be able to deploy changes. To do that, just run:

    just update-my-deps
