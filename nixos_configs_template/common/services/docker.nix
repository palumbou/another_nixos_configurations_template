{ ... }:
{
  # Enable the local Docker daemon independently of its client tools.
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = false;
    rootless.enable = false;
  };
}
