{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    darktable # Photo editing and RAW processing.
    gimp      # Image editing.
  ];
}
