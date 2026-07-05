# sparkle's static addressing on the DMZ subnet behind sfp0, the firewall zone all the servers sit in. hostAddress is sparkle itself; shared by the sfp0 network config, resolv.conf, the coredns zone, and the git vhost allowlist.
{
  hostAddress = "10.28.32.25";
  prefixLength = "23";
  gateway = "10.28.32.1";
  subnet = "10.28.32.0/23";
}
