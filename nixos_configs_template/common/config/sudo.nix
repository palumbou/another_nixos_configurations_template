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
          # Allows mount without requiring a password
          command = "${pkgs.util-linux}/bin/mount";
          options = [ "NOPASSWD" ];
        }
        {
          # Allows unmount without requiring a password
          command = "${pkgs.util-linux}/bin/umount";
          options = [ "NOPASSWD" ];
        }
        {
          # Allows mounting SMB/CIFS shares without requiring a password (helper called by mount)
          command = "${pkgs.cifs-utils}/bin/mount.cifs";
          options = [ "NOPASSWD" ];
        }
        {
          # Allows unmounting SMB/CIFS shares without requiring a password
          command = "${pkgs.cifs-utils}/bin/umount.cifs";
          options = [ "NOPASSWD" ];
        }
      ];
      # Specifies which group these rules apply to
      groups = [ "wheel" ];
    }];
  };
}