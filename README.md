# lwldap

The lightest-weight openldap image you ever did see.

No automatic schema loading or configuration, no certificate generation, no auto-configured replication -- just a container with slapd running in it and a minimal startup script to facilitate initial setup.

## Why?

As someone that's familiar with LDAP administration, I got frustrated at how opinionated most of the existing images and wanted something simple that I could use to easily test configurations and work with preexisting nonstandard schemas.

This is literally just a container that runs slapd. It will only be as production ready as you make it. There are many, many offerings available with sane defaults, web GUIs, etc. preconfigued for you. If you want those things, use one.

## How?

### Configuring lwldap

A small number of environment variables are provided to configure the build and startup behavior of **lwldap**.

Configuration of slapd should be managed via a `config.ldif` file as described below.

#### Build-time

| Environment Variable  | Allowed Values           | Description                                                                                   |
|-----------------------|--------------------------|-----------------------------------------------------------------------------------------------|
| LWLDAP_UID            | number                   | Overrides the default Alpine uid of the openldap user (100)                                   |
| LWLDAP_GID            | number                   | Overrides the default Alpine gid of the openldap user (101)                                   |

#### Runtime

| Environment Variable   | Allowed Values          | Description                                                                                   |
|------------------------|-------------------------|-----------------------------------------------------------------------------------------------|
| LWLDAP_BIND_DN         | string                  | The DN of a read-write account to use for seeding.                                            |
| LWLDAP_BIND_PW         | string                  | The password of a read-write account to use for seeding.                                      |
| LWLDAP_SKIP_CONFIG     | any                     | If set, skips [configuring slapd](#configuring-slapd) on startup.                             |
| LWLDAP_SKIP_SEED       | any                     | If set, skips [seeding the directory](#seeding-the-directory) on startup.                     |
| LWLDAP_SEED_METHOD     | "auto"\|"add"\|"modify" | Sets the [seeding method](#seeding-the-directory) for the seed ldif files.                    |
| LWLDAP_SLAPD_LOG_LEVEL | number                  | Sets the slapd log level.                                                                     |
| LWLDAP_DEBUG_STARTUP   | any                     | If set, sets -x on the startup script.                                                        |

### Configuring slapd

To configure slapd, mount a `config.ldif` file to `/ldif/config.ldif`. This will be used to initialize the config db with `slapadd`.

This initial configuration will be automatically skipped if:
 * `/ldif/config.ldif` is missing
 * `LWLDAP_SKIP_CONFIG` is set
 * Config initialization has already completed once

Skipping initial configuration can be useful when mounted a preconfigured database.

### Seeding the directory

To seed the directory, mount additional ldif files to `/ldif/ldif.d` inside the container. These will processed in order.

Unlike many openldap images, **lwldap** does not create its own credentials for your database and is not aware of your admin credentials by default. In order to seed, you must provide read-write credentials via `LWLDAP_BIND_DN` and `LWLDAP_BIND_PW`.

By default, **lwldap** will use `ldapadd` for any files that do not contain a `changeType` line and `ldapmodify` for those that do. This behavior can be changed by setting `LWLDAP_SEED_METHOD`.

Note that while `ldapadd` will not create duplicate entries, `ldapmodify` *will* repeatedly modify an existing entry if new nodes are spun up to join an existing cluster. You may wish to set `LWLDAP_SKIP_SEED` on new nodes after initial setup is complete.

### LDIF Variable Substition

The startup script will substitue arbitrary environment `$variables` using `envsubst` in both `config.ldif` and `ldif.d` files. `$ESCAPE_DOLLAR` can be used to escape a literal `$`. If an appropriate environment variable is not set, the substitution will be silently skipped.

For example, to configure an admin password:

```ldif
olcRootPW: $ADMIN_PASSWORD
```

```bash
docker run --env ADMIN_PASSWORD="{SSHA}BQeR1iZiG5ZK2nq4Q9r3u1i0BsE3vBms" carriejv/lwldap
```

### Persistance

Config data will be stored in `/etc/openldap/slapd.d` as normal. Directory databases will be stored wherever you choose, based on your config. In order to persist this data (or to use an already-existing database), mount the appropriate paths as external volumes.
