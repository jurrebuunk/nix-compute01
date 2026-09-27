{ }:

{
  on_poweroff = "destroy";
  on_reboot = "restart";
  on_crash = "restart";

  pm = {
    suspend-to-mem.enabled = false;
    suspend-to-disk.enabled = false;
  };
}
