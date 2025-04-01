{
  disko.devices = {
    disk = {
      main = {
        # Indicates that we're working with a disk (as opposed to a partition)
        type = "disk";
        # Device path for the disk, e.g., /dev/sda (substituted via ${DISK_DEVICE})
        device = "/dev/${DISK_DEVICE}";

        content = {
          # Use a GPT partition table for this disk
          type = "gpt";
          partitions = {
            # EFI System Partition (ESP)
            ESP = {
              size = "500M";   # Allocate 500 MiB for the EFI partition
              type = "EF00";   # GPT type code for EFI System Partition
              content = {
                # Format this partition as a filesystem
                type = "filesystem";
                format = "vfat";       # FAT32 needed by EFI
                mountpoint = "/boot";  # Mount the EFI partition at /boot
                # Restricts file permissions to owner only
                mountOptions = [ "umask=0077" ];
              };
            };

            # LUKS-encrypted partition for the rest of the disk
            luks = {
              size = "100%";  # Occupies all remaining space
              content = {
                # Designate this partition as a LUKS container
                type = "luks";
                name = "crypted";       # Name for the LUKS volume
                settings.allowDiscards = true; # Enables TRIM operations on the encrypted volume
                # Use a password file instead of interactive entry
                passwordFile = "/tmp/secret.key";

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