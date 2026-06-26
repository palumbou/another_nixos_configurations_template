{ pkgs, ... }:
{
  # Enable I2C bus for DDC/CI communication with external monitors
  # Required by ddcutil to control brightness, contrast, input source, etc.
  hardware.i2c.enable = true;

  environment.systemPackages = with pkgs; [
    ddcutil    # Control monitor settings via DDC/CI (brightness, contrast, input, etc.)
    v4l-utils  # Video4Linux utilities for webcam and video capture device management
    # Note: usbutils and pciutils are already in default_packages_services.nix
  ];

  # Note: users who need DDC/CI access should be added to the "i2c" group.
  # See users/<username>/user.nix for the conditional group assignment.
}
