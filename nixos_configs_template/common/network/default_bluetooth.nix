{ config, ... }:
{
  # Enable Bluetooth support in the kernel
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;  # Turn on Bluetooth adapter at boot
    settings = {
      General = {
        DiscoverableTimeout = 180;  # Disable discoverable timeout
        Experimental = true;  # Enable experimental features (e.g. some codecs)
        FastConnectable = true;
        MultiProfile = "off";  # Disable multi-profile support; possible values: "off", "single", "multiple"
      };
      Policy = {
        AutoEnable = true;  # Turn on Bluetooth adapters automatically
      };
    };
  };

  # Some Broadcom or Realtek BT drivers require extra firmware.
  hardware.enableAllFirmware = true;

  # Increase compatibility for older BT devices
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=0
  '';
}