{
  disko.devices = {
    disk = {
      main = {
        # Specifies that we're dealing with a disk rather than a partition
        type = "disk";
        # Defines the device path, such as /dev/sda (substituted by ${DISK_DEVICE})
        device = "/dev/${DISK_DEVICE}";

        content = {
          # Indicates that we're using a GPT partition table on this disk
          type = "gpt";
          partitions = {
            # Defines the EFI System Partition (ESP)
            ESP = {
              size = "1G";    # Allocates 1 GiB for the EFI partition
              type = "EF00";  # GPT partition type code for EFI System Partition
              content = {
                # This partition is formatted as a filesystem
                type = "filesystem";
                format = "vfat";       # FAT32 needed for EFI
                mountpoint = "/boot";  # Mount point for the ESP
                # Sets restrictive permissions on the files in the partition
                mountOptions = [ "umask=0077" ];
              };
            };

            # Main root partition
            root = {
              size = "100%";  # Occupies the remaining space on the disk
              content = {
                # Formats this partition as an ext4 filesystem
                type = "filesystem";
                format = "ext4";
                # Sets the root partition's mount point
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}