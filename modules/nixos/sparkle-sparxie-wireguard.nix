# The sparkle<->sparxie WireGuard tunnel: a /31 point-to-point pair with each host's address and public key, plus sparxie's listen port. Used by both hosts' wireguard configs and by the pub.bunny.enterprises proxy chain to reach sparkle's file server over the tunnel.
{
  prefixLength = "31";
  listenPort = 47329;
  sparxie = {
    ip = "10.73.212.1";
    publicKey = "VjVuhnnTEHuGssQOp0iM1yU0BLT34VWm3k00e8tDkSg=";
  };
  sparkle = {
    ip = "10.73.212.0";
    publicKey = "fU36EC/ymy4d1XwJCfqAXKEX8dRK/WuMFBbh6OtKBRM=";
  };
}
