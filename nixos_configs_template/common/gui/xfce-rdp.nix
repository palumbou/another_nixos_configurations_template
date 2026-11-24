{ lib, pkgs, ... }:
{
  # Install Xfce for remote sessions without starting a local display manager.
  services.xserver.enable = lib.mkDefault false;
  services.xserver.desktopManager.xfce.enable = true;
  services.dbus.enable = true;

  services.xrdp = {
    enable = true;

    # Firewall access is controlled by the host's network configuration.
    openFirewall = false;

    # Initialize Xfce with a dedicated D-Bus session.
    defaultWindowManager =
      "${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.xfce4-session}/bin/startxfce4";

    # Disable direct root login over RDP.
    extraConfDirCommands = ''
      substituteInPlace $out/sesman.ini --replace-fail "AllowRootLogin=true" "AllowRootLogin=false"
    '';
  };

  # Require a password for RDP, overriding the upstream PAM default.
  security.pam.services.xrdp-sesman.allowNullPassword = lib.mkForce false;
}
