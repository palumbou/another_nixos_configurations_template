{ config, ... }:
{
  # Enable TLP for battery management and power saving
  services.tlp = {
    enable = true;
    settings = {
      # Battery charge thresholds
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;

      # CPU profiles
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      
      # Boost CPU
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      
      # Platform profiles
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # Disable USB autosuspend (avoid issues with mouse/keyboard)
      USB_AUTOSUSPEND = 0;
    };
  };
}