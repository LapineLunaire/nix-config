{pkgs}:
pkgs.runCommand "bunny-web" {} ''
  cp -r ${./site} $out
  chmod -R u+w $out
''
