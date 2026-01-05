# Lanzaboote source definition
# This file defines the source for the Lanzaboote project
# https://github.com/nix-community/lanzaboote
#
#
# Version: v1.0.0 (latest stable release)
# Last updated: January 2026

{
  lanzaboote = builtins.fetchTarball {
    url = "https://github.com/nix-community/lanzaboote/archive/refs/tags/v1.0.0.tar.gz";
    sha256 = "17srvx92f0xymayfislm5d87bjd6n1p80s350my8si737iaa16a4";
  };
}
