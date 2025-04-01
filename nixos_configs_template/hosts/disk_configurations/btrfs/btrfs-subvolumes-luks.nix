{
  disko.devices = {
    disk = {
      main = {
        # Identifies that we're configuring a disk
        type = "disk";
        # Specifies the device path that we are partitioning and formatting
        device = "/dev/${DISK_DEVICE}";

        content = {
          # Use a GPT partition table on this disk
          type = "gpt";
          partitions = {
            # EFI System Partition (ESP)
            ESP = {
              size = "512M";  # Partition size for the EFI boot partition
              type = "EF00";  # GPT partition type code for EFI
              content = {
                # Specifies a filesystem on this partition
                type = "filesystem";
                format = "vfat";     # FAT32 needed by EFI
                mountpoint = "/boot"; # Mount the ESP at /boot
                # Restricts access for increased security
                mountOptions = [ "umask=0077" ];
              };
            };

            # Encrypted partition (LUKS)
            luks = {
              size = "100%";  # Occupies all remaining space
              content = {
                # Indicates a LUKS-encrypted container
                type = "luks";
                name = "crypted";  # Name for the opened LUKS device
                # Allows a password file rather than interactive entry
                passwordFile = "/tmp/secret.key"; # Set to enable interactive or file-based decryption
                settings = {
                  allowDiscards = true; # Enables TRIM commands on this encrypted partition
                  # keyFile = "/tmp/secret.key";  # Uncomment to use a key file
                };
                # additionalKeyFiles = [ "/tmp/additionalSecret.key" ]; # Optionally specify multiple key files

                content = {
                  # Formats the inside of the LUKS container as Btrfs
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # Force override if a filesystem is already present
                  # Defines multiple Btrfs subvolumes
                  subvolumes = {
                    "/root" = {
                      # The primary root volume
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/home" = {
                      # A separate subvolume for /home
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      # A separate subvolume for /nix
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/swap" = {
                      # A subvolume intended for a swap file
                      mountpoint = "/.swapvol";
                      # Defines a 20MB swap file in this subvolume
                      swap.swapfile.size = "20M";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}