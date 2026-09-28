{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/REPLACE_WITH_NIXOS_SYSTEM_DISK";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "FIRMWARE";
          start = "1M";
          end = "1025M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot/firmware";
            mountOptions = [
              "fmask=0022"
              "dmask=0022"
            ];
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
                mountOptions = [
                  "compress=zstd:3"
                  "noatime"
                ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [
                  "compress=zstd:3"
                  "noatime"
                ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd:3"
                  "noatime"
                ];
              };
              "@log" = {
                mountpoint = "/var/log";
                mountOptions = [
                  "compress=zstd:3"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };
}
