# nix-compute01

Flake-driven NixOS configuration for `compute01`.

`hardware-configuration.nix` is intentionally ignored because it is machine-specific.
The flake imports it from `/etc/nixos/hardware-configuration.nix`, so rebuild with `--impure`.

## Rebuild

```bash
sudo nixos-rebuild switch --flake /etc/nixos#compute01 --impure
```

## Virtualization

The RTX 4060 is reserved for VFIO at boot and passed directly to libvirt guests.
The host does not load NVIDIA drivers and is expected to be managed over SSH.

Current VM list:

```text
configs/vms/default.nix
```

Per-VM settings live in:

```text
configs/vms/
```

Shared host/libvirt/VFIO modules live in:

```text
modules/virtualization/host/
```

Shared NixVirt domain builders live in:

```text
modules/virtualization/vms/lib/
```

GPU PCI address and VFIO device IDs live in:

```text
configs/hardware/passthrough-gpu.nix
```

Check binding after boot:

```bash
lspci -nnk -s 07:00.0
lspci -nnk -s 07:00.1
```

Both functions should be using `vfio-pci`. The local monitor may go black once Linux binds the only GPU to VFIO; that is expected.

For this single/boot-GPU setup, VFIO is intentionally loaded after the initrd and the EFI/simple framebuffers are disabled with kernel parameters. This avoids the common `vfio-pci ... vgaarb` / black-screen boot hang when the passthrough GPU is also the firmware boot display.

