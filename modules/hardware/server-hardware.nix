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
      initrd.systemd.enable = true;      
      binfmt.emulatedSystems = [ "aarch64-linux" ];
      kernelPackages = pkgs.linuxPackages_latest;
      extraModulePackages = [ config.boot.kernelPackages.zenpower ];
      kernelModules = [ "kvm-intel" ];
      
      # Standard systemd-boot must be turned OFF for lanzaboote to manage the EFI stub
      loader.systemd-boot.enable = lib.mkForce false;
      loader.efi.canTouchEfiVariables = true;

      # Enable GRUB as the universal bootloader
      loader.grub = {
        enable = true;
        efiSupport = true;
        # Install the Legacy GRUB payload directly to the disk's MBR
        device = lib.mkDefault "/dev/disk/by-id/ata-WDC_WD5000AAKX-22ERMA0_WD-WCC2E2YDJFH5"; 
      };
  
      initrd.availableKernelModules = [ 
        "nvme" "xhci_pci" "usb_storage" "usbhid" "sd_mod" "tpm_crb" "tpm_tis" 
      ];
      initrd.kernelModules = [ ];
    };

    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;


    disko.devices = {
      disk = {
        main = {
          device = lib.mkDefault "/dev/disk/by-id/ata-WDC_WD5000AAKX-22ERMA0_WD-WCC2E2YDJFH5"; 
          type = "disk";
          content = {
            type = "gpt";
            partitions = {                                      
              bios_boot = {
                start = "1M";
                end = "2M";
                type = "EF02";       
              };
              ESP = {
                start = "2M";
                end = "1026M";     
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              root = {
                start = "1026M";
                end = "100G";      
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
              data = {
                start = "100G";    
                end = "100%"; 
              };
            };          
          };
        };
      };
    };
    
    fileSystems."/mnt/data" = {
      device = "/dev/disk/by-id/ata-WDC_WD5000AAKX-22ERMA0_WD-WCC2E2YDJFH5-part4"; 
      fsType = "ext4"; 
      options = [ "nofail" ];
    };
  };
}