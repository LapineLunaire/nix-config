{...}: {
  systemd.tmpfiles.rules = [
    # DynamicUser services get a private /var/lib/private/<name> bind-mounted into the unit's namespace.
    # Impermanence can't bind-mount individual subdirs of this, so the entire /var/lib/private directory is persisted instead.
    "d '/var/lib/private' 0700 root root - -"
    "z '/var/lib/private' 0700 root root - -"

    # ejabberd upload directory
    "d '/var/lib/ejabberd/upload' 0750 ejabberd ejabberd - -"
    "z '/var/lib/ejabberd/upload' 0750 ejabberd ejabberd - -"
  ];
}
