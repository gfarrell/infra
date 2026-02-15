# This postgres module makes some assumptions.
#
# It expects you to pass a list of databases ([string]) where each item in the list is the name of the service-user, the name of the database, and the name of the database-user. These will all be the same.
#
# It also will automatically create a postgres-exporter user mapping to allow prometheus metrics.
{
  postgresql_16,
  lib,
  port,
  databases,
}: {
  services.postgresql = {
    enable = true;
    package = postgresql_16;

    settings = {inherit port;};

    # Services will each have their own user, which then connects to the database via this identmap.
    # We have some default mappings to start, and we add dynamically from the passed-in databases list.
    identMap = let
      users-map =
        [
          {
            sys = "postgres";
            db = "postgres";
          }
          {
            sys = "gideon";
            db = "postgres";
          }
          {
            sys = "root";
            db = "postgres";
          }
          {
            sys = "postgres-exporter";
            db = "postgres";
          }
        ]
        ++ map (name: {
          sys = name;
          db = name;
        })
        databases;
    in
      lib.concatStringsSep "\n" (map (m: "users_map ${m.sys} ${m.db}") users-map);

    authentication = lib.mkOverride 10 ''
      #type   database   DBUser     auth-method   optional_ident_map
      local   all        postgres   peer          map=users_map
      local   sameuser   all        peer          map=users_map
    '';

    # Now make sure we have users and databases setup for every database in the list.
    ensureDatabases = databases;
    ensureUsers =
      map (db: {
        name = db;
        ensureDBOwnership = true;
      })
      databases;
  };
}
