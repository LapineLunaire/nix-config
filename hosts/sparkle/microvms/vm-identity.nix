# Guest-side identity derived from vm-registry.nix: vsock CID, tap interface, MAC, hostname, static IP, and the default state share.
# The MAC prefix is a randomly generated locally-administered unicast OUI (02 + 4 random bytes) so the VMs can never collide with real hardware or another 02:00:... scheme on the LAN.
name: let
  vm = (import ./vm-registry.nix).${name};
  net = import ./vm-net.nix;
  # Indices below 10 would produce a one-digit MAC octet and vsock CIDs below 3 are reserved; above 99 overflows the octet.
  octet =
    if vm.index >= 10 && vm.index <= 99
    then toString vm.index
    else throw "vm-registry index ${toString vm.index} for ${name} is outside 10-99; it is spliced into the MAC and IP as a two-digit octet";
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
      # State share for every VM; VM configs add extra shares (media, certs) on top.
      shares = [
        {
          tag = "state";
          source = "/persist/vms/${name}";
          mountPoint = "/persist";
          proto = "virtiofs";
        }
      ];
    };
    networking.hostName = name;
    networking.interfaces.eth0.ipv4.addresses = [
      {
        address = net.vmAddress.${name};
        prefixLength = 24;
      }
    ];
  }
