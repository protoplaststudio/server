{ inputs, lib, ... }:
# ls -l /dev/disk/by-id/
{
  flake.nixosModules.server-hardware = { pkgs, config, modulesPath,... }: {

    imports = [ 
      inputs.disko.nixosModules.disko
      (modulesPath + "/installer/scan/not-detected.nix") 
    ];
    
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    boot = {
      boot.loader.grub = {
        enable = true;
        efiSupport = false; # Required for Legacy/BIOS
        device = "/dev/disk/by-id/ata-WDC_WD5000AAKX-22ERMA0_WD-WCC2E2YDJFH5"; 
      };
      initrd.systemd.enable = true;      
      binfmt.emulatedSystems = [ "aarch64-linux" ];
      kernelPackages = pkgs.linuxPackages_latest;
      extraModulePackages = [ config.boot.kernelPackages.zenpower ];
      kernelModules = [ "kvm-intel" ];
      initrd.availableKernelModules = [ 
        "nvme" "xhci_pci" "usb_storage" "usbhid" "sd_mod" "tpm_crb" "tpm_tis" 
      ];
      initrd.kernelModules = [ ];
    };

    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;


    disko.devices = {
      disk = {
        main = {
          device = "/dev/disk/by-id/ata-WDC_WD5000AAKX-22ERMA0_WD-WCC2E2YDJFH5"; 
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              bios_boot = {
                size = "1M";
                type = "EF02"; 
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };          
          };
        };
      };
    };
  };
}