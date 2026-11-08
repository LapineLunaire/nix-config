{
  git,
  less,
  writers,
}:
writers.writePython3Bin "t3-pull" {flakeIgnore = ["E501"];} (
  builtins.replaceStrings ["@git@" "@less@"] ["${git}/bin/git" "${less}/bin/less"] (builtins.readFile ./t3-pull.py)
)
