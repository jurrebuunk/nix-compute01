# nix-compute01

Bare-bones flake-driven NixOS configuration for `compute01`.

`hardware-configuration.nix` is intentionally ignored because it is machine-specific.
The flake imports it from `/etc/nixos/hardware-configuration.nix`, so rebuild with `--impure`.

## Rebuild

```bash
sudo nixos-rebuild switch --flake /etc/nixos#compute01 --impure
```

There is also a temporary `#nixos` alias for the first rebuild while the current hostname is still `nixos`.

## Windows gaming VM

The repo defines a libvirt VM named `win11-gaming` with dynamic RTX 4060 passthrough.

- VM off: NVIDIA driver owns the GPU on the NixOS host.
- VM starting: libvirt hook unloads NVIDIA and binds the GPU to VFIO.
- VM stopped: libvirt hook reattaches the GPU to the host NVIDIA driver.

The VM config lives in `configs/gaming-vm.nix` and the module is `modules/windows-gaming-vm.nix`.

After rebuilding and rebooting, attach your Windows ISO:

```bash
sudo virsh attach-disk win11-gaming /path/to/windows.iso sda --type cdrom --mode readonly --config
```

Then start the VM:

```bash
sudo virsh start win11-gaming
```

The host display will go headless while the VM is running. SSH should remain available.

Useful checks:

```bash
sudo virsh list --all
sudo virsh domstate win11-gaming
sudo journalctl -u libvirt-define-win11-gaming.service
sudo tail -f /var/log/libvirt/qemu/win11-gaming-gpu-hook.log
```
