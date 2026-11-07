{
  git,
  writers,
}:
writers.writePython3Bin "t3-pull" {flakeIgnore = ["E501"];} (
  builtins.replaceStrings ["@git@"] ["${git}/bin/git"] (builtins.readFile ./t3-pull.py)
)
