# default disko layout for garden (new laptop) – D14
# Generic btrfs layout similar to wonderland; device will be adjusted at install time.
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            priority = 1;
            name = "ESP";
            start = "1M";
            end = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "fmask=0022" "dmask=0022" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd:3" "noatime" "autodefrag" ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd:3" "noatime" "autodefrag" ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd:3" "noatime" "autodefrag" ];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = [ "compress=zstd:3" "noatime" "autodefrag" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
