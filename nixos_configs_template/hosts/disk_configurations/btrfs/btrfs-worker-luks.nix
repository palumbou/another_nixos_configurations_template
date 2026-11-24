{ ... }:
let
  btrfsMountOptions = [ "compress=zstd" "noatime" ];
in
{
  disko.devices.disk.main = {
    type = "disk";

    # Target disk and swap size are explicit host parameters.
    device = "/dev/${DISK_DEVICE}";

    content = {
      type = "gpt";

      partitions = {
        ESP = {
          priority = 1;
          size = "1G";
          type = "EF00";

          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        swap = {
          priority = 2;
          size = "${SWAP_SIZE}";
          type = "8200";

          content = {
            type = "swap";
            randomEncryption = true;
            priority = 10;
          };
        };

        luks = {
          size = "100%";

          content = {
            type = "luks";
            name = "crypted";
            askPassword = true;
            extraFormatArgs = [ "--type" "luks2" ];

            # Allow TRIM through LUKS on the NVMe SSD.
            settings.allowDiscards = true;

            content = {
              type = "btrfs";

              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = btrfsMountOptions;
                };

                "/home" = {
                  mountpoint = "/home";
                  mountOptions = btrfsMountOptions;
                };

                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsMountOptions;
                };

                "/work" = {
                  mountpoint = "${WORK_ROOT}";
                  mountOptions = btrfsMountOptions;
                };
              };
            };
          };
        };
      };
    };
  };
}
