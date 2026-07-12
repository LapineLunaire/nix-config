{
  config,
  lib,
  ...
}: let
  entries =
    lib.mapAttrsToList (name: entry: {
      inherit name entry;
      ports = "{ " + lib.concatMapStringsSep ", " toString entry.ports + " }";
    })
    config.ip-whitelist;

  sets =
    lib.concatMapStrings ({
      name,
      entry,
      ...
    }: ''
      set ${name}4 {
        type ipv4_addr
        flags interval
        auto-merge
        include "${entry.ipv4File}"
      }

      set ${name}6 {
        type ipv6_addr
        flags interval
        auto-merge
        include "${entry.ipv6File}"
      }

    '')
    entries;

  rules = lib.concatMapStrings ({
    name,
    ports,
    ...
  }: "  tcp dport ${ports} ip saddr != @${name}4 drop\n  tcp dport ${ports} ip6 saddr != @${name}6 drop\n")
  entries;
in {
  options.ip-whitelist = lib.mkOption {
    default = {};
    description = "Named whitelists: the TCP ports are only reachable from the addresses in the whitelist files. Nothing is exempt, even loopback and tunnel traffic is dropped unless listed.";
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        ports = lib.mkOption {
          type = lib.types.nonEmptyListOf lib.types.port;
          description = "Destination ports the whitelist applies to.";
        };

        ipv4File = lib.mkOption {
          type = lib.types.str;
          description = "File containing an nftables elements statement with the allowed IPv4 sources, e.g. elements = { x.x.x.x, x.x.x.0/24 }. An empty file allows no IPv4 source.";
        };

        ipv6File = lib.mkOption {
          type = lib.types.str;
          description = "File containing an nftables elements statement with the allowed IPv6 sources, e.g. elements = { x:x:x::x, x:x:x::/48 }. An empty file allows no IPv6 source.";
        };
      };
    });
  };

  config = lib.mkIf (entries != []) {
    # The allowed addresses are included from runtime files so they stay out of the world-readable nix store.
    # This table only vetoes non-whitelisted traffic, the nixos-fw table still decides what is accepted.
    networking.nftables.tables.ip-whitelist = {
      family = "inet";
      content = ''
        ${sets}chain input {
          type filter hook input priority filter - 1;
        ${rules}}
      '';
    };

    # The included files do not exist in the build sandbox, so drop the include lines before the build-time ruleset check.
    networking.nftables.preCheckRuleset =
      lib.concatMapStrings ({entry, ...}: ''
        sed -i '\|include "${entry.ipv4File}"|d; \|include "${entry.ipv6File}"|d' ruleset.conf
      '')
      entries;
  };
}
