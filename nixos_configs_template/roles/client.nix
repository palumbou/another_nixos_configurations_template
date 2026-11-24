{ ... }:
{
  imports = [
    ./base.nix
    ../common/config/os_compatibility.nix
    ../common/config/os_optimization.nix
    ../common/config/sudo.nix
  ];
}
