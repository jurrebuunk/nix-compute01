# nix-compute01

Flake-driven NixOS configuration for `compute01`.

`hardware-configuration.nix` is intentionally ignored because it is machine-specific.
The flake imports it from `/etc/nixos/hardware-configuration.nix`, so rebuild with `--impure`.

## Rebuild

```bash
sudo nixos-rebuild switch --flake /etc/nixos#compute01 --impure
```

## Virtualization

The RTX 4060 is passed directly to libvirt guests.
The host does not load NVIDIA drivers, but it also does not bind the boot GPU to VFIO during early boot; libvirt performs managed VFIO attach when a VM starts.

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

Before a VM starts, the GPU may show no NVIDIA/nouveau kernel driver, but it may still be used by the Linux firmware/simple framebuffer console. When a VM starts, a libvirt qemu hook unbinds the framebuffer console and libvirt attaches the GPU/audio functions to `vfio-pci` with managed PCI passthrough.

