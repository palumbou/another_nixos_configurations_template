{ config, ... }:
{
  # TLP replaces power-profiles-daemon, which KDE Plasma and GNOME enable
  # by default: the two conflict, so disable it explicitly.
  services.power-profiles-daemon.enable = false;

  # Enable TLP for battery management and power saving
  services.tlp = {
    enable = true;
    settings = {
      # Battery charge thresholds.
      # Some laptops expose the battery as BAT0 (Lenovo, Dell), others as BAT1
      # (e.g. Framework): both are set, TLP ignores the one that doesn't exist.
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1 = 80;

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

  # UPower: last-resort protection against a dying battery.
  # Hibernates automatically at 7% while discharging, so a drained battery
  # results in a clean hibernation instead of a hard power loss.
  # Keep percentageAction below any user-space battery watcher threshold
  # to avoid racing with it. No-op on hosts without a battery.
  services.upower = {
    enable = true;
    percentageLow = 15;             # battery is considered low
    percentageCritical = 10;        # battery is considered critical
    percentageAction = 7;           # threshold that triggers the action below
    criticalPowerAction = "Hibernate";
  };
}