{ ... }:
{
  imports = [
    "${builtins.fetchTarball {
      url = "https://github.com/nix-community/disko/archive/refs/tags/v1.13.0.tar.gz";
      sha256 = "03jz60kw0khm1lp72q65z8gq69bfrqqbj08kw0hbiav1qh3g7p08";
    }}/module.nix"
  ];
}
