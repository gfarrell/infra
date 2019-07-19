# Use debian as the exim in alpine is weird
# But use slim to reduce image size
FROM debian:buster-slim

# Port 25 is used for incoming SMTP connections
EXPOSE 25

# Install exim4-daemon-light. exim4-daemon-heavy contains
# features we really don't need as can be seen at
# https://packages.debian.org/buster/exim4-daemon-heavy
# Also add spf-tools-perl for spf queries.
RUN apt-get update && \
    apt-get install -y exim4-daemon-light spf-tools-perl

# Copy the main config file (yes, it needs two `.conf`s)
COPY exim4-config.conf /etc/exim4/update-exim4.conf.conf

# Delete the bits of config we are replacing wholesale
RUN rm /etc/exim4/conf.d/router/*

# Copy some extra config files into the right places. These will be
# stitched together when we run `update-exim4.conf`. The numbers just
# denote the order in which files will be concatenated (alphabetical).
COPY acl_check_rcpt /etc/exim4/conf.d/acl/30_exim4-config_check_rcpt
COPY main_mm3_macros /etc/exim4/conf.d/main/25_mm3_macros
COPY router_all /etc/exim4/conf.d/router/00_routing
COPY transport_mm3 /etc/exim4/conf.d/transport/55_mm3_transport

# Update /etc/mailname
RUN echo "lists.gtf.io" > /etc/mailname

# Update the configuration with the copied settings
RUN update-exim4.conf

# Run exim as a daemon (`-bd`) and verbosely (`-v`):
# https://www.exim.org/exim-html-current/doc/html/spec_html/ch-the_exim_command_line.html
# This image should use the --init option to kill zombies and shut down
# cleanly: https://docs.docker.com/compose/compose-file/#init
CMD ["exim", "-bd", "-v"]
