{ pkgs, vm }:

pkgs.writeText "${vm.name}.xml" ''
  <domain type='kvm'>
    <name>${vm.name}</name>
    <metadata>
      <nixos:managed-by xmlns:nixos='https://nixos.org'>nix-compute01</nixos:managed-by>
    </metadata>

    <memory unit='GiB'>${toString vm.memoryGiB}</memory>
    <currentMemory unit='GiB'>${toString vm.memoryGiB}</currentMemory>
    <vcpu placement='static'>${toString vm.vcpus}</vcpu>
    <iothreads>1</iothreads>

    <os firmware='efi'>
      <type arch='x86_64' machine='q35'>hvm</type>
      <firmware>
        <feature enabled='no' name='secure-boot'/>
      </firmware>
      <boot dev='cdrom'/>
      <boot dev='hd'/>
    </os>

    <features>
      <acpi/>
      <apic/>
      <hyperv mode='custom'>
        <relaxed state='on'/>
        <vapic state='on'/>
        <spinlocks state='on' retries='8191'/>
        <vpindex state='on'/>
        <runtime state='on'/>
        <synic state='on'/>
        <stimer state='on'/>
        <frequencies state='on'/>
        <tlbflush state='on'/>
        <ipi state='on'/>
        <vendor_id state='on' value='compute01'/>
      </hyperv>
      <kvm>
        <hidden state='on'/>
      </kvm>
      <vmport state='off'/>
      <ioapic driver='kvm'/>
    </features>

    <cpu mode='host-passthrough' check='none' migratable='off'>
      <topology sockets='${toString vm.cpuTopology.sockets}' dies='1' cores='${toString vm.cpuTopology.cores}' threads='${toString vm.cpuTopology.threads}'/>
      <cache mode='passthrough'/>
      <feature policy='require' name='topoext'/>
    </cpu>

    <clock offset='localtime'>
      <timer name='rtc' tickpolicy='catchup'/>
      <timer name='pit' tickpolicy='delay'/>
      <timer name='hpet' present='no'/>
      <timer name='hypervclock' present='yes'/>
    </clock>

    <on_poweroff>destroy</on_poweroff>
    <on_reboot>restart</on_reboot>
    <on_crash>restart</on_crash>

    <pm>
      <suspend-to-mem enabled='no'/>
      <suspend-to-disk enabled='no'/>
    </pm>

    <devices>
      <disk type='file' device='disk'>
        <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
        <source file='${vm.diskPath}'/>
        <target dev='vda' bus='virtio'/>
        <boot order='2'/>
      </disk>

      <disk type='file' device='cdrom'>
        <driver name='qemu' type='raw'/>
        <target dev='sda' bus='sata'/>
        <readonly/>
        <boot order='1'/>
      </disk>

      <disk type='file' device='cdrom'>
        <driver name='qemu' type='raw'/>
        <source file='${pkgs.virtio-win}/iso/virtio-win.iso'/>
        <target dev='sdb' bus='sata'/>
        <readonly/>
      </disk>

      <controller type='pci' model='pcie-root'/>
      <controller type='pci' model='pcie-root-port'>
        <model name='pcie-root-port'/>
        <target chassis='1' port='0x10'/>
      </controller>
      <controller type='usb' model='qemu-xhci' ports='15'/>
      <controller type='sata' index='0'/>
      <controller type='virtio-serial' index='0'/>

      <interface type='network'>
        <source network='default'/>
        <model type='virtio'/>
      </interface>

      <input type='tablet' bus='usb'/>
      <input type='mouse' bus='ps2'/>
      <input type='keyboard' bus='ps2'/>

      <graphics type='spice' autoport='yes' listen='127.0.0.1'>
        <listen type='address' address='127.0.0.1'/>
        <image compression='off'/>
      </graphics>
      <channel type='spicevmc'>
        <target type='virtio' name='com.redhat.spice.0'/>
      </channel>
      <video>
        <model type='virtio' heads='1' primary='yes'/>
      </video>

      <hostdev mode='subsystem' type='pci' managed='yes'>
        <driver name='vfio'/>
        <source>
          <address domain='${vm.gpu.video.domain}' bus='${vm.gpu.video.bus}' slot='${vm.gpu.video.slot}' function='${vm.gpu.video.function}'/>
        </source>
        <rom bar='on'/>
      </hostdev>

      <hostdev mode='subsystem' type='pci' managed='yes'>
        <driver name='vfio'/>
        <source>
          <address domain='${vm.gpu.audio.domain}' bus='${vm.gpu.audio.bus}' slot='${vm.gpu.audio.slot}' function='${vm.gpu.audio.function}'/>
        </source>
      </hostdev>

      <tpm model='tpm-crb'>
        <backend type='emulator' version='2.0'/>
      </tpm>

      <memballoon model='none'/>
    </devices>
  </domain>
''
