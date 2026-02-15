# This caddy config is basically for generating a load of reverse proxies.
# 1. Logs are standardised and given 0644 so that promtail can read them; www and plain logs are in the same file.
# 2. If has_www is specified, then we create a plain->www redirect and make the www the reverse-proxy.
# 3. Custom config can be added with with_custom.
{
  simple_proxies,
  lib,
}: let
  mkLog = domain: ''
    log {
      output file /var/log/caddy/${domain}.log {
        mode 644
      }
      format json
    }
  '';
  mkVhosts = {
    domain,
    port,
    has_www ? false,
    with_custom ? "",
  }:
    if has_www
    then [
      {
        name = domain;
        value.extraConfig = ''
          redir https://www.{host}{uri}
          ${mkLog domain}
        '';
      }
      {
        name = "www.${domain}";
        value.extraConfig = ''
          encode gzip
          reverse_proxy localhost:${toString port}
          ${mkLog domain}
          ${with_custom}
        '';
      }
    ]
    else [
      {
        name = domain;
        value.extraConfig = ''
          encode gzip
          reverse_proxy localhost:${toString port}
          ${mkLog domain}
          ${with_custom}
        '';
      }
    ];
in {
  services.caddy = {
    enable = true;
    globalConfig = ''
      servers {
        metrics
      }
    '';
    virtualHosts = lib.listToAttrs (lib.concatMap mkVhosts simple_proxies);
  };
}
