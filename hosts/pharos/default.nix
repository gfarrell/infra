{
  config,
  modulesPath,
  inputs,
  lib,
  pkgs,
  ...
}: let
  website-server-port = 8080;
  draft-server-port = 8082;
  wedding-website-port = 8084;
  postgres-port = 5432;

  databases = {
    wedding = {
      name = "wedding-website";
      user = "wedding-website";
    };
  };
in {
  imports = [
    "${modulesPath}/virtualisation/digital-ocean-image.nix"
    inputs.agenix.nixosModules.default
    ../../services/gtf-io.nix
    ../../services/gtf-io-drafts.nix
    ../../services/wedding-website.nix
  ];

  virtualisation.digitalOceanImage.compressionMethod = "bzip2";

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;

    settings = {
      port = postgres-port;
    };

    # Services will each have their own user, which then connects to
    # the database via this identmap
    identMap = ''
      users_map postgres postgres
      users_map gideon postgres
      users_map postgres-exporter postgres
      users_map root postgres
      users_map wedding-website wedding-website
    '';

    authentication = lib.mkOverride 10 ''
      #type   database   DBUser     auth-method   optional_ident_map
      local   all        postgres   peer          map=users_map
      local   sameuser   all        peer          map=users_map
    '';

    ensureDatabases = [databases.wedding.name];

    ensureUsers = [
      {
        name = databases.wedding.user;
        ensureDBOwnership = true;
      }
    ];
  };

  services.caddy = {
    enable = true;
    globalConfig = ''
      servers {
        metrics
      }
    '';
    virtualHosts."gtf.io".extraConfig = ''
      redir http://www.{host}{uri}
      log {
        output file /var/log/caddy/gtf.io.log {
          mode 644
        }
        format json
      }
    '';
    virtualHosts."www.gtf.io".extraConfig = ''
      encode gzip
      reverse_proxy localhost:${toString config.gtf.gtf-io.port}
      log {
        output file /var/log/caddy/gtf.io.log {
          mode 644
        }
        format json
      }
    '';
    virtualHosts."g-and-t.wedding".extraConfig = ''
      redir http://www.{host}{uri}
      log {
        output file /var/log/caddy/g-and-t.wedding.log {
          mode 644
        }
        format json
      }
    '';
    virtualHosts."www.g-and-t.wedding".extraConfig = ''
      encode gzip
      reverse_proxy localhost:${toString config.gtf.wedding-website.port}
      log {
        output file /var/log/caddy/g-and-t.wedding.log {
          mode 644
        }
        format json
      }
    '';
    virtualHosts."prometheus.gtf.io".extraConfig = ''
      basicauth {
        gideon $2a$14$fxieAGKHEnHRgTDTl7AhQ.1NxAakImNUDbVasXVp0OPpDcyZsJgk2
      }
      encode gzip
      reverse_proxy localhost:${toString config.services.prometheus.port}
      log {
        output file /var/log/caddy/prometheus.gtf.io.log {
          mode 644
        }
        format json
      }
    '';
    virtualHosts.${config.services.grafana.settings.server.domain}.extraConfig = ''
      encode gzip
      reverse_proxy localhost:${toString config.services.grafana.settings.server.http_port}
      log {
        output file /var/log/caddy/${config.services.grafana.settings.server.domain}.log {
          mode 644
        }
        format json
      }
    '';
    virtualHosts."drafts.gtf.io".extraConfig = ''
      encode gzip
      reverse_proxy localhost:${toString config.gtf.draft-server.port}
      log {
        output file /var/log/caddy/drafts.gtf.io.log {
          mode 644
        }
        format json
      }
    '';
  };

  # configure the gtf-io website module
  gtf.gtf-io = {
    enable = true;
    port = website-server-port;
  };
  gtf.draft-server = {
    enable = true;
    port = draft-server-port;
  };

  # configure the wedding website module
  gtf.wedding-website = {
    enable = true;
    port = wedding-website-port;
    db-host = "/run/postgresql";
    db-port = postgres-port;
    db-user = databases.wedding.user;
    db-name = databases.wedding.name;
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };

  # Export data to prometheus
  # https://wiki.nixos.org/wiki/Prometheus
  services.prometheus.exporters.node = {
    enable = true;
    port = 9000;
    enabledCollectors = ["systemd"];
    listenAddress = "localhost";
  };
  services.prometheus.exporters.postgres = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9187;
  };
  # And run a local prometheus server
  services.prometheus = {
    enable = true;
    port = 9090;
    globalConfig.scrape_interval = "15s";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.node.port}" # pharos system metrics
              "localhost:${toString config.services.prometheus.exporters.postgres.port}" # postgres metrics
              "localhost:2019" # caddy exports its own metrics here
            ];
          }
        ];
      }
    ];
  };
  # Use grafana for graphing metrics and logs
  services.grafana = {
    enable = true;
    settings.server = {
      http_addr = "127.0.0.1";
      http_port = 9080;
      domain = "monitor.gtf.io";
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        }
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
        }
      ];
    };
  };

  # Ingest logs with loki
  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 9085;
      auth_enabled = false;
      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore.store = "inmemory";
            replication_factor = 1;
          };
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 999999;
        chunk_retain_period = "30s";
      };
      schema_config = {
        configs = [
          {
            from = "2024-07-01";
            schema = "v13";
            store = "tsdb";
            object_store = "filesystem";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };
      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb-index";
          cache_location = "/var/lib/loki/tsdb-cache";
        };
        filesystem.directory = "/var/lib/loki/chunks";
      };
      query_scheduler = {
        max_outstanding_requests_per_tenant = 32768;
      };
      querier = {
        max_concurrent = 16;
      };
      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };
      table_manager = {
        retention_deletes_enabled = false;
        retention_period = "0s";
      };
      compactor = {
        working_directory = "/var/lib/loki";
        compactor_ring.kvstore.store = "inmemory";
      };
    };
  };

  # promtail collects system logs
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9086;
        grpc_listen_port = 0;
      };
      positions.filename = "/tmp/positions.yaml";
      clients = [
        {
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = config.networking.hostName;
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
          ];
        }
        {
          job_name = "caddy";
          static_configs = [
            {
              targets = ["localhost"];
              labels = {
                job = "caddy";
                __path__ = "/var/log/caddy/*.log";
              };
            }
          ];
          pipeline_stages = [
            {
              json = {
                expressions = {
                  level = "level";
                  timestamp = "ts";
                  message = "msg";
                  remote_ip = "request.remote_ip";
                  method = "request.method";
                  host = "request.host";
                  uri = "request.uri";
                  referer = "request.headers.Referer[0]";
                  agent = "request.headers.\"User-Agent\"[0]";
                  duration = "duration";
                  status = "status";
                };
              };
            } {
              labels = {
                level = null;
                timestamp = null;
                message = null;
                remote_ip = null;
                method = null;
                host = null;
                uri = null;
                referer = null;
                agent = null;
                duration = null;
                status = null;
              };
            } {
              timestamp = {
                source = "timestamp";
                format = "RFC3339";
              };
            } {
              output = {
                source = "message";
              };
            }
          ];
        }
      ];
    };
  };

  networking.hostName = "pharos";
}
