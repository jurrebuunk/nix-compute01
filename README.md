# nix-compute01

Bare-bones flake-driven NixOS configuration for `compute01`.

`hardware-configuration.nix` is intentionally ignored because it is machine-specific.
The flake imports it from `/etc/nixos/hardware-configuration.nix`, so rebuild with `--impure`.

## Rebuild

```bash
sudo nixos-rebuild switch --flake /etc/nixos#compute01 --impure
```

There is also a temporary `#nixos` alias for the first rebuild while the current hostname is still `nixos`.
