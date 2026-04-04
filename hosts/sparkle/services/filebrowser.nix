{pkgs, ...}: {
  systemd.services.filebrowser = {
    description = "File Browser";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.filebrowser}/bin/filebrowser --port 9000 --address 127.0.0.1 --root /mnt/samba/misc --database /var/lib/filebrowser/filebrowser.db";
      StateDirectory = "filebrowser";
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
