{ vm }:

{
  cpu = {
    mode = "host-passthrough";
    check = "none";
    migratable = false;
    topology = vm.cpu.topology // {
      dies = 1;
    };
    cache.mode = "passthrough";
    feature = {
      policy = "require";
      name = "topoext";
    };
  };
}
