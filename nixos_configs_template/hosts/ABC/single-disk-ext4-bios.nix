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
            boot = {
              size = "1M";   # A small partition for GRUB's core image
              type = "EF02"; # GPT code for BIOS Boot Partition (GRUB MBR support)
            };

            # Root partition
            root = {
              size = "100%"; # Occupies the rest of the disk
              content = {
                # Formats this partition as an ext4 filesystem
                type = "filesystem";
                format = "ext4";
                # Mounts the partition as the root filesystem
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}