{ config, lib, pkgs, ... }:
{
  # Enables declarative user configuration, preventing manual creation of users with "useradd".
  users.mutableUsers = true;

  # Declares a group named "${USER}" with GID 1000 and assigns "${USER}" as a member.
  users.groups.${USER} = {
    name = "${USER}";
    members = ["${USER}"];
    gid = 1000;
  };

  # Declares a user named "${USER}" with specific properties.
  users.users.${USER} = {
    hashedPassword = "${USER_PWD}";
    isNormalUser = true; # Specifies that this is a regular user (not a system user).
    description = ""; # Description of the user.
    uid = 1000; # Sets the user ID.
    group = "${USER}"; # Primary group for the user.
    extraGroups = [ # Additional groups the user belongs to.
      "networkmanager" # Allows managing network connections.
      "wheel"          # Grants sudo/root access.
      "libvirtd"       # Allows managing virtual machines.
      "audio"          # Access to audio devices.
      "video"          # Access to video devices.
      "plugdev"        # Access to plug-and-play devices like USB.
      "input"          # Access to input devices like keyboards and mice.
      #"kvm"            # Access to KVM virtualization.
      #"qemu-libvirtd"  # Access to QEMU virtual machines.
    ];

    home = "/home/${USER}"; # Sets the home directory for the user.
    createHome = true; # Ensures the home directory is created.

    # Packages installed specifically for this user.
    packages = with pkgs; [
      firefox             # Firefox browser.
      ghostty             # Fast, native, feature-rich terminal emulator pushing modern features.
      hunspell            # Spell checker.
      hunspellDicts.${DICTIONARY} # Dictionary for Hunspell.
      libreoffice-qt6     # LibreOffice with Qt6 integration.
      mpv                 # Media player.
      neovim              # Modern Vim-based text editor.
      remmina             # Remote desktop client.
      spotify             # Spotify desktop client.
      starship            # Cross-shell prompt for the terminal.
      telegram-desktop    # Telegram messaging application.
      yazi                # A fast and modern terminal-based file manager.
      zoxide              # A smarter `cd` command for the terminal.
    ];
  };

  # Setting up directories for the user
  systemd.tmpfiles.settings = {
    "home-directories" = { # Block name: used to identify the group of configurations, customizable.
      # Create the ~/Documents directory if it does not exist with the following attributes:
      # - Ownership: user "${USER}" and group "${USER}"
      # - Permissions: 0755 (read, write, and execute for the owner; read and execute for others)
      "/home/${USER}/Documents" = {
        d = {
          user = "${USER}";
          group = "${USER}";
          mode = "0755";
          age = "-";
        };
      };
      # Create the ~/Download directory
      "/home/${USER}/Download" = {
        d = {
          user = "${USER}";
          group = "${USER}";
          mode = "0755";
          age = "-";
        };
      };
      # Create the ~/Images directory
      "/home/${USER}/Images" = {
        d = {
          user = "${USER}";
          group = "${USER}";
          mode = "0755";
          age = "-";
        };
      };
      # Create the ~/Videos directory
      "/home/${USER}/Videos" = {
        d = {
          user = "${USER}";
          group = "${USER}";
          mode = "0755";
          age = "-";
        };
      };
    };

    # Copy dotfiles in user's .config directory
    "dotfiles" = {
      "/home/${USER}/.config" = {
        "C+" = {
          argument = "${BASEURL}/nixos_configs/users/${USER}/dotfiles/";
          user = "${USER}";
          group = "${USER}";
          mode = "0755";
          age = "-";
        };
      };
    };
  };

  # Defines shell aliases for convenience.
  environment.shellAliases = {
    l = "ls -l -a -h --color=auto"; # Lists all files with details and colored output.
    ll = "ls -l -a -h --color=auto"; # Similar to `l`, but a separate alias.
    la = "ls -a"; # Lists all files, including hidden ones.
    grep = "grep --color=auto"; # Enables colored output for grep.
  };

  # Configures environment variables.
  environment.variables = {
    HISTSIZE = "3000"; # Sets the maximum number of history entries in memory.
    HISTFILESIZE = "3000"; # Sets the maximum number of history entries in the history file.
  };

  # Configuration for Syncthing.
  #services.syncthing.user = "${USER}"; # Specifies the user for Syncthing.
  #services.syncthing.group = "${USER}"; # Specifies the group for Syncthing.

  # Configuration for Virtual Machine Manager.
  #users.groups.libvirtd.members = ["${USER}"]; # Adds the user to the libvirtd group to manage virtual machines.
}
