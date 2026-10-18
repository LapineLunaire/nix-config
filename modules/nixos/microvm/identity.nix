{
  config,
  dmz,
  net,
  guestRegistry,
  ...
}: let
  name = config.networking.hostName;
  index = guestRegistry.${name}.index;
  macPrefix = "02:76:96:0e:fe";
in {
  microvm = {
    vsock.cid = index;
    interfaces = [
      {
        type = "tap";
        id = name;
        # Preserve the decimal digits used as the hexadecimal MAC suffix.
        mac =
          if index >= 10 && index <= 99
          then "${macPrefix}:${toString index}"
          else throw "microVM index for ${name} must be between 10 and 99";
      }
    ];
    shares = [
      {
        tag = "state";
        source = "/persist/vms/${name}";
        mountPoint = "/persist";
        proto = "virtiofs";
      }
    ];
  };
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = net.vmAddress.${name};
      inherit (dmz) prefixLength;
    }
  ];
}
