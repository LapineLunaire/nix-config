# Guest-side identity derived from vm-registry.nix: vsock CID, tap interface, MAC, hostname, and static IP.
# The MAC prefix is a randomly generated locally-administered unicast OUI (02 + 4 random bytes) so the VMs can never collide with real hardware or another 02:00:... scheme on the LAN.
name: let
  vm = (import ./vm-registry.nix).${name};
  octet = toString vm.index;
in
  {...}: {
    microvm = {
      vsock.cid = vm.index;
      interfaces = [
        {
          type = "tap";
          id = name;
          mac = "02:76:96:0e:fe:${octet}";
        }
      ];
    };
    networking.hostName = name;
    networking.interfaces.eth0.ipv4.addresses = [
      {
        address = "10.28.34.${octet}";
        prefixLength = 24;
      }
    ];
  }
