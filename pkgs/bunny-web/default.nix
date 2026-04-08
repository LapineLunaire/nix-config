{pkgs}:
pkgs.runCommand "bunny-web" {} ''
  cp -r ${./.} $out
  chmod -R u+w $out
''
