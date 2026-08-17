{ pkgs, ... }:

{
  imports =
    [
      # sops-nix pinned to a specific commit for reproducibility and supply-chain safety.
      # To update: pick a commit from https://github.com/Mic92/sops-nix/commits/master and run
      #   nix-prefetch-url --unpack https://github.com/Mic92/sops-nix/archive/<commit>.tar.gz
      "${builtins.fetchTarball {
        url = "https://github.com/Mic92/sops-nix/archive/a8627b21b9107c5711c96b84f32a9a4b3d45295f.tar.gz";
        sha256 = "1j89yslxj0q29xzrjcp19r4a130k4cdihx4yw6f2bm72fgia0j42";
      }}/modules/sops"
    ];

  # Every host decrypts secrets with the age key derived from its own SSH host
  # key: no extra key material to generate or distribute on the machines.
  # Who can decrypt what is defined in .sops.yaml at the repository root.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Tools for editing and managing secrets
  environment.systemPackages = [
    pkgs.sops       # CLI/editor for the encrypted secrets files
    pkgs.age        # Encryption backend used by sops
    pkgs.ssh-to-age # Derives a host's age public key from its SSH host key
  ];
}
