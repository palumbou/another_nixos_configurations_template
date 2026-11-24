{ ... }:
{
  # The graphical client can also manage remote libvirt hosts.
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
}
