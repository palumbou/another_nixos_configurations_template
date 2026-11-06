{ lib, ... }:
{
  imports = [ ./energy_profiles.nix ];

  # TLP replaces power-profiles-daemon, which KDE Plasma and GNOME enable
  # by default: the two conflict, so disable it explicitly.
  services.power-profiles-daemon.enable = false;

  # Enable TLP for battery management and power saving
  services.tlp = {
    enable = true;
    settings = {
      # TLP >= 1.9: AC = performance, BAT = balanced, SAV = manual power saver.
      # Smart switching preserves a manually selected SAV profile. The native
      # `tlp ac` / `tlp bat` overrides also survive charger changes and resume.
      # `energy-profile auto` or a reboot restores source-based selection.
      TLP_AUTO_SWITCH = 2;

      # Battery charge thresholds.
      # Some laptops expose the battery as BAT0 (Lenovo, Dell), others as BAT1
      # (e.g. Framework): both are set, TLP ignores the one that doesn't exist.
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1 = 80;

      # These governors target intel_pstate / amd-pstate in active mode.
      # Hosts with a different scaling driver can override the defaults below
      # (for example, use schedutil with acpi-cpufreq instead of powersave).
      CPU_SCALING_GOVERNOR_ON_AC = lib.mkDefault "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = lib.mkDefault "powersave";
      CPU_SCALING_GOVERNOR_ON_SAV = lib.mkDefault "powersave";

      # Keep battery operation responsive; reserve stronger savings for SAV.
      CPU_ENERGY_PERF_POLICY_ON_AC = lib.mkDefault "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = lib.mkDefault "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_SAV = lib.mkDefault "balance_power";

      # Allow turbo for interactive bursts in balanced mode.
      CPU_BOOST_ON_AC = lib.mkDefault 1;
      CPU_BOOST_ON_BAT = lib.mkDefault 1;
      CPU_BOOST_ON_SAV = lib.mkDefault 0;

      # Firmware names vary by host. Override these defaults when needed,
      # using the values exposed by platform_profile_choices.
      PLATFORM_PROFILE_ON_AC = lib.mkDefault "performance";
      PLATFORM_PROFILE_ON_BAT = lib.mkDefault "balanced";
      PLATFORM_PROFILE_ON_SAV = lib.mkDefault "balanced";

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
    percentageLow = 15; # battery is considered low
    percentageCritical = 10; # battery is considered critical
    percentageAction = 7; # threshold that triggers the action below
    criticalPowerAction = "Hibernate";
  };
}
