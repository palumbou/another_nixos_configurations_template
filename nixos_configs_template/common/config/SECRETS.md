# Secrets with sops-nix

[English](SECRETS.md) | [Italiano](SECRETS.it.md)

Nix configuration and build outputs may enter the readable Nix store. Keep password hashes, Wi-Fi credentials and tokens out of Nix source. The pinned [sops-nix](https://github.com/Mic92/sops-nix) module in `secrets.nix` decrypts encrypted YAML during activation, before account creation where required. Secret values are read from runtime files rather than interpolated into store files.

## Files and ownership

| File/key | Scope | Consumer |
| --- | --- | --- |
| `.sops.yaml` | Public age recipients and file rules | SOPS editing/encryption |
| `secrets/common.yaml`: `admin_hashedPassword` | Shared administrator credential | `users/<admin>/admin.nix`; `neededForUsers = true` |
| `secrets/common.yaml`: `admin_ssh_publicKey` | Shared administrator authorized public key | Host runtime SSH key template |
| `secrets/<hostname>.yaml`: `worker_hashedPassword` | Worker account on this host | `users/<worker>/worker.nix`; `neededForUsers = true` |
| `secrets/<hostname>.yaml`: `worker_ssh_publicKey` | Worker-only authorized public key | Server host runtime SSH key template |
| `secrets/<hostname>.yaml`: `wifi_env` | This host's Wi-Fi environment | Host `nm_configurations.nix` |

The common file is readable by the editor and every authorized host. A host file is readable by the editor and that host only. Keep a separate rule for each host. Client host files can retain unused worker example keys or remove them if the client declares no worker secrets. Public SSH keys are encrypted here for consistent account provisioning; their private counterparts never belong in the configuration tree.

Every host imports `common/config/secrets.nix` and selects `sops.defaultSopsFile = ../../../secrets/<hostname>.yaml`. The administrator password explicitly uses `../../secrets/common.yaml` relative to its account module. The worker password uses the host default. Both password secrets use `neededForUsers` and are available before account creation under `/run/secrets-for-users`; normal secrets and rendered templates use `/run/secrets*`.

## Prepare recipients

Work from the root of your configured tree, where `.sops.yaml`, `secrets/`, `users/` and `hosts/` will live. On a system without the tools, start `nix-shell -p sops age ssh-to-age mkpasswd`.

Create an editor age key outside this tree:

```bash
mkdir -p ~/.config/sops/age
chmod 700 ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

Record the printed public recipient. Protect and back up the private key separately. `secrets.nix` configures each host to decrypt with its existing `/etc/ssh/ssh_host_ed25519_key`. Obtain only its public recipient on that host:

```bash
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

For a fresh installation, prepare the target's SSH host key after mounting it at `/mnt` and before installation, without overwriting an existing key:

```bash
sudo mkdir -p /mnt/etc/ssh
sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
sudo ssh-to-age < /mnt/etc/ssh/ssh_host_ed25519_key.pub
```

Copy `.sops.yaml.template` to `.sops.yaml`. Replace `REPLACE_WITH_EDITOR_AGE_RECIPIENT` and `REPLACE_WITH_HOST_AGE_RECIPIENT` with those public recipients. Replace `${HOSTNAME}` in its host rule with the hostname. The markers are deliberately invalid recipients and must be configured manually. Add an anchor/rule for each further host; include every permitted host in the common rule while keeping each host file limited to its own recipient.

## Create encrypted YAML

For a generic host named `example-node`:

```bash
cp secrets/common.yaml.template secrets/common.yaml
cp secrets/ABC.yaml.template secrets/example-node.yaml
mkpasswd -m sha-512
```

If the host example already has the hostname in its filename, copy that file instead of `ABC.yaml.template`. Replace the YAML markers with your chosen password hashes, complete public SSH key lines and Wi-Fi passphrase. Use the interactive `mkpasswd` prompt rather than putting a password on a command line. Never use the placeholder values as credentials. The `wifi_env` block contains `WIFI_PSK=...`; the host NetworkManager profile references exactly `$WIFI_PSK`.

Encrypt both files before they are committed, synchronized or used by NixOS:

```bash
sops --encrypt --in-place secrets/common.yaml
sops --encrypt --in-place secrets/example-node.yaml
```

After encryption, edit only with `sops secrets/common.yaml` or `sops secrets/example-node.yaml`. Review encrypted-file metadata to confirm the expected recipients. Protect editor backups and temporary plaintext according to the editor you use. Plaintext templates contain examples only; deploy encrypted `.yaml` files, not the `.yaml.template` files.

## Runtime SSH authorized keys

The host declares `admin_ssh_publicKey` from the common file and, on a server host, `worker_ssh_publicKey` from the host file. `sops.templates` renders `ssh-authorized-keys/<admin>` owned by the administrator with mode `0400`. A server host also renders `ssh-authorized-keys/<worker>` owned by the worker, containing both the administrator and worker public keys. This allows the administrator to log in as either account while the worker key grants access only to the worker.

OpenSSH reads `/run/secrets/rendered/ssh-authorized-keys/%u`, where `%u` is the requested account. These files are rendered during activation; no public-key value needs evaluation-time decryption. Existing host examples include these declarations and `AllowUsers`. A standalone account module does not supply the SSH templates by itself. Preserve a working administrative access route until the new configuration has been verified.

## Updates and removal

- Change a password by running `mkpasswd -m sha-512` and updating the matching key with SOPS. Shared administrator changes apply to every host consuming the common file; worker changes affect the selected host.
- Change a host's Wi-Fi value inside its `wifi_env`; `restartUnits` refreshes `NetworkManager-ensure-profiles.service`. Add a corresponding profile if you add another variable/network.
- Add a host recipient to `.sops.yaml`, then run `sops updatekeys secrets/common.yaml` and `sops updatekeys secrets/<hostname>.yaml` for the relevant files before activation.
- Remove a recipient from the rules, update affected files and rotate the values it could previously read. Removing a recipient does not revoke old decrypted copies or repository history.

## Check before activation

A parse, evaluation or build does not prove that the target can decrypt. Check recipients and the host's public identity before installation/rebuild. When you intentionally test decryption with your editor key, discard stdout rather than displaying the values:

```bash
sops --decrypt secrets/common.yaml > /dev/null
sops --decrypt secrets/example-node.yaml > /dev/null
```

This proves editor access only; host access must be checked using that host's configured identity. Failure to decrypt `neededForUsers` secrets can block account provisioning and activation. `users.mutableUsers = true` on clients does not guarantee recovery from a failed activation. Correct the recipients/key path before proceeding.
