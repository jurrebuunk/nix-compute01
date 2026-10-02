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

Because this RTX 4060 is also the firmware boot GPU, the kernel only exposes a small legacy shadow ROM through `/sys/bus/pci/devices/0000:07:00.0/rom`. OVMF needs a clean UEFI/GOP VBIOS image for monitor output. Place a matching RTX 4060 UEFI VBIOS at:

```text
/var/lib/libvirt/vbios/rtx4060-uefi.rom
```

The matching TechPowerUp entry researched for this card is `Inno3D.RTX4060.8192.230529.rom` / VBIOS `95.07.31.00.F4` / device `10DE:2882`.

