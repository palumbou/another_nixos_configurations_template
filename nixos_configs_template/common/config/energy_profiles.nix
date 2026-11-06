{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tlp;

  # Only these fixed TLP operations can run with elevated privileges. TLP owns
  # its temporary state; no additional state files or persistent overrides are
  # needed. `start` returns to automatic selection, `ac`/`bat` force a profile,
  # and smart switching retains SAV because it is never a power-source default.
  applyProfile = pkgs.writeShellApplication {
    name = "energy-profile-apply";
    text = ''
      if [[ "$EUID" -ne 0 || "$#" -ne 1 ]]; then
        printf '%s\n' 'Use energy-profile auto|performance|balanced|saver.' >&2
        exit 2
      fi

      case "$1" in
        auto)        exec ${cfg.package}/bin/tlp start ;;
        performance) exec ${cfg.package}/bin/tlp ac ;;
        balanced)    exec ${cfg.package}/bin/tlp bat ;;
        saver)       exec ${cfg.package}/bin/tlp power-saver ;;
        *)
          printf '%s\n' 'Unknown energy profile.' >&2
          exit 2
          ;;
      esac
    '';
  };

  energyProfile = pkgs.writeShellApplication {
    name = "energy-profile";
    text = ''
      if [[ "$#" -ne 1 ]]; then
        printf '%s\n' 'Usage: energy-profile auto|performance|balanced|saver|status' >&2
        exit 2
      fi

      case "$1" in
        status)
          profile=unknown
          mode=unknown
          power_source=unknown
          profile_code=
          source_code=
          extra=

          # Native TLP 1.9 state: profile (PRF=0, BAL=1, SAV=2), source (AC=0,
          # BAT=1). Read as data, never source a file into this shell.
          if [[ -r /run/tlp/last_pwr ]] &&
             IFS=' ' read -r profile_code source_code extra < /run/tlp/last_pwr &&
             [[ -z "$extra" ]]; then
            case "$profile_code" in
              0) profile=performance ;;
              1) profile=balanced ;;
              2) profile=saver ;;
            esac
            case "$source_code" in
              0) power_source=ac ;;
              1) power_source=battery ;;
            esac
          fi

          if [[ "$profile" != unknown ]]; then
            if [[ -e /run/tlp/manual_mode || "$profile_code" == 2 ]]; then
              mode=manual
            elif [[ "$power_source" != unknown ]]; then
              if [[ "$profile_code" == "$source_code" ]]; then
                mode=auto
              else
                mode=manual
              fi
            fi
          fi

          printf '{"profile":"%s","mode":"%s","power_source":"%s"}\n' \
            "$profile" "$mode" "$power_source"
          ;;
        auto|performance|balanced|saver)
          if [[ "$EUID" -eq 0 ]]; then
            exec ${applyProfile}/bin/energy-profile-apply "$1"
          else
            exec ${config.security.wrapperDir}/pkexec \
              ${applyProfile}/bin/energy-profile-apply "$1"
          fi
          ;;
        *)
          printf '%s\n' 'Usage: energy-profile auto|performance|balanced|saver|status' >&2
          exit 2
          ;;
      esac
    '';
  };

  policy = pkgs.writeTextDir "share/polkit-1/actions/org.nixos.energy-profile.policy" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE policyconfig PUBLIC
      "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
      "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
    <policyconfig>
      <action id="org.nixos.energy-profile.apply">
        <description>Change the temporary TLP energy profile</description>
        <message>Authorization is required to change the energy profile</message>
        <defaults>
          <allow_any>no</allow_any>
          <allow_inactive>no</allow_inactive>
          <allow_active>no</allow_active>
        </defaults>
        <annotate key="org.freedesktop.policykit.exec.path">${applyProfile}/bin/energy-profile-apply</annotate>
      </action>
    </policyconfig>
  '';
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.versionAtLeast (lib.getVersion cfg.package) "1.9";
        message = "energy-profile requires TLP 1.9 or newer (three energy profiles).";
      }
      {
        assertion = cfg.settings.TLP_AUTO_SWITCH == 2 && cfg.settings.TLP_PERSISTENT_DEFAULT == 0;
        message = "energy-profile requires TLP_AUTO_SWITCH=2 and TLP_PERSISTENT_DEFAULT=0 for temporary manual choices.";
      }
    ];

    services.tlp.settings = {
      TLP_AUTO_SWITCH = lib.mkDefault 2;
      TLP_PERSISTENT_DEFAULT = lib.mkDefault 0;
    };

    environment.systemPackages = [
      energyProfile
      policy
    ];

    security.polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id === "org.nixos.energy-profile.apply" &&
              subject.local && subject.active && subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';
    };
  };
}
