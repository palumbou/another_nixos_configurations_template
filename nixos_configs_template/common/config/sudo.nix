{ pkgs, ... }:
{
  # The "security.sudo" section enables and configures sudo
  security.sudo = {
    enable = true;  # Activates the sudo service

    # Defines extra custom sudo rules
    extraRules = [{
      # List of commands granted without a password (NOPASSWD option)
      commands = [
        {
          # Allows suspending the system without requiring a password
          command = "${pkgs.systemd}/bin/systemctl suspend";
          options = [ "NOPASSWD" ];
        }
        {
          # Allows hibernating the system without requiring a password
          command = "${pkgs.systemd}/bin/systemctl hibernate";
          options = [ "NOPASSWD" ];
        }
        {
          # Allows rebooting the system without requiring a password
          command = "${pkgs.systemd}/bin/reboot";
          options = [ "NOPASSWD" ];
        }
        {
          # Allows powering off the system without requiring a password
          command = "${pkgs.systemd}/bin/poweroff";
          options = [ "NOPASSWD" ];
        }
        {
          # Allows mount the system without requiring a password
          command = "${pkgs.util-linux}/bin/mount";
          options = [ "NOPASSWD" ];
        }
        {
          # Allows unmount the system without requiring a password
          command = "${pkgs.util-linux}/bin/umount";
          options = [ "NOPASSWD" ];
        }
      ];
      # Specifies which group these rules apply to
      groups = [ "wheel" ];
    }];
  };
}