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
                          
              # 1. LEGACY BOOTLOADER SPACE (1 MiB to 2 MiB)
              bios_boot = {
                start = "1M";      # Starts at 1st Megabyte
                end = "2M";        # Ends at 2nd Megabyte
                type = "EF02";       
              };

              # 2. UEFI BOOTLOADER SPACE (Almost 1 GiB)
              ESP = {
                start = "2M";      # Starts right where legacy ends
                end = "1026M";        # Ends exactly at the 1 GiB mark
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };

              # 3. NIXOS ROOT (Exactly 99 GiB)
              root = {
                start = "1026M";      # Starts exactly at the 1 GiB mark
                end = "100G";      # Ends exactly at the 100 GiB mark
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };

              # 4. IMMUTABLE DATA VAULT
              # The Indestructible Border is now locked cleanly at 100 GiB
              data = {
                start = "100G";    
                end = "100%"; 
                # No content block - Format manually
                # sudo mkfs.ext4 /dev/disk/by-id/ata-WDC_WD5000AAKX-22ERMA0_WD-WCC2E2YDJFH5-part4
                # sudo mount -a
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