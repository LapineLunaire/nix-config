# The WireGuard tunnel that carries public web requests from Sparxie to the proxy guest.
{
  prefixLength = "31";
  proxyAddress = "10.73.212.0";
  sparxieAddress = "10.73.212.1";
  # The proxy guest serves Sparxie on this port inside the tunnel.
  port = 9000;
}
