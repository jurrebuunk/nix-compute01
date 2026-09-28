# nix-compute01

Flake-driven NixOS configuration for `compute01`.

`hardware-configuration.nix` is intentionally ignored because it is machine-specific.
The flake imports it from `/etc/nixos/hardware-configuration.nix`, so rebuild with `--impure`.

## Rebuild

```bash
sudo nixos-rebuild switch --flake /etc/nixos#compute01 --impure
```

## GPU passthrough VMs

The RTX 4060 is dedicated to VFIO/libvirt VMs. The host does not use the GPU through NVIDIA anymore; manage the host over SSH.

Defined VMs:

- `win11-gaming`
- `ubuntu-compute-vm`

Only one VM can run at a time because both pass through the same RTX 4060 and NVIDIA audio device.

Readable settings live in:

```text
configs/windows-gaming-vm.nix
configs/ubuntu-compute-vm.nix
configs/passthrough-gpu.nix
configs/default-network.nix  # br0/enp6s0 LAN bridge
```

Virtualization modules live in:

```text
modules/virtualization/
├── default.nix
├── libvirt.nix      # shared libvirt/NixVirt setup
├── network.nix      # shared LAN bridge br0 on enp6s0
├── storage.nix      # shared libvirt storage dirs
├── vfio.nix         # shared GPU VFIO binding
├── windows-gaming-vm/
└── ubuntu-compute-vm/
```

Check VMs:

```bash
sudo virsh list --all
```

Attach installers:

```bash
sudo virsh attach-disk win11-gaming /path/to/windows.iso sda --type cdrom --mode readonly --config
sudo virsh attach-disk ubuntu-compute-vm /path/to/ubuntu.iso sda --type cdrom --mode readonly --config
```

Start one VM:

```bash
sudo virsh start win11-gaming
# or
sudo virsh start ubuntu-compute-vm
```

Stop it before starting the other:

```bash
sudo virsh shutdown win11-gaming
# if needed:
sudo virsh destroy win11-gaming
```

Check GPU binding:

```bash
lspci -nnk -s 07:00.0
lspci -nnk -s 07:00.1
```

Expected on the host after boot and when VMs are off: no NVIDIA/nouveau driver should be bound to the GPU. Libvirt binds it to `vfio-pci` when a VM starts.
