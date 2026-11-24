{ pkgs, ... }:
{
  # libvirt uses Polkit authorization even without a desktop session.
  security.polkit.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "start";
    onShutdown = "shutdown";

    qemu = {
      package = pkgs.qemu_kvm;
      # Run guests under the dedicated qemu-libvirtd account.
      runAsRoot = false;
      swtpm.enable = true;
    };
  };

  # Preserve automatic startup of the default libvirt network.
  systemd.services.libvirt-default-network = {
    description = "Start libvirt default network";
    after = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.libvirt}/bin/virsh net-autostart default
      ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
    '';
  };
}
