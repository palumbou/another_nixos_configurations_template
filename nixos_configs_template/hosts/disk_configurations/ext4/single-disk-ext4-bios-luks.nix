{
  disko.devices = {
    disk = {
      main = {
        # Specifies that we are configuring a disk device
        device = "/dev/${DISK_DEVICE}";
        type = "disk";

        content = {
          # Use a GPT partition table on this disk
          type = "gpt";
          partitions = {
            # BIOS Boot Partition (for GRUB on a GPT disk)
            bios = {
              size = "1M";   # A small partition for GRUB's core image
              type = "EF02"; # GPT code for BIOS Boot Partition (GRUB MBR support)
            };

            # Separate /boot partition (unencrypted, needed for GRUB with LUKS)
            boot = {
              size = "1G";   # Allocate 1 GiB for /boot partition
              content = {
                type = "filesystem";
                format = "ext4";       # Use ext4 for the boot partition
                mountpoint = "/boot";  # Mount at /boot
              };
            };

            # LUKS-encrypted root partition
            root = {
              size = "100%"; # Occupies the rest of the disk
              content = {
                # Designate this partition as a LUKS container
                type = "luks";
                name = "crypted";  # Name for the LUKS volume

                # Use a password file instead of interactive entry
                passwordFile = "/tmp/secret.key";
                settings = {
                  allowDiscards = true; # Enables TRIM commands on this encrypted partition
                  # Unlock at boot with a USB key instead of typing the passphrase (see LUKS_KEYS.md):
                  # keyFile = "/dev/usbkey";   # udev symlink to the USB key stick
                  # keyFileSize = 4096;        # read only the first 4096 bytes as the key
                  # keyFileTimeout = 10;       # fall back to the passphrase prompt after 10 seconds
                };
                # Enroll extra keys (e.g. USB sticks) at format time (see LUKS_KEYS.md):
                # additionalKeyFiles = [ "/tmp/usbkey1.key" "/tmp/usbkey2.key" ];

                # Inside the LUKS container, format as an ext4 filesystem
                content = {
                  type = "filesystem";
                  format = "ext4";
                  # Mount the resulting filesystem at the root directory
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
