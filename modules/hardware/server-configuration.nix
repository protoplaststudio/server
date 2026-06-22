{ ... }:
{
  flake.nixosModules.server-configuration = { pkgs, ... }: 
  {
    
    nix = {
      settings = { 
        experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
      };
    };
    
    nixpkgs.config.allowUnfree = true;
    programs.nix-ld.enable = true;
    system.stateVersion = "26.05";
    time.timeZone = "Asia/Kolkata";
    services.timesyncd.enable = true;
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "us";
    virtualisation.docker.enable = true;
    services = {
      openssh.enable = true;
      pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        wireplumber.enable = true; 
      };
      avahi = {
        enable = true;
        nssmdns4 = true; 
      };
      
      postgresql = {
        enable = true;
        package = pkgs.postgresql_18; # Or your preferred version
        # THIS IS THE MAGIC: Point the DB to your persistent vault
        dataDir = "/mnt/data/postgresql/data";
        authentication = pkgs.lib.mkOverride 10 ''
          # TYPE  DATABASE        USER            ADDRESS                 METHOD
          local   all             all                                     trust
          host    all             all             127.0.0.1/32            trust
        '';
      };
  
      
    };

    systemd.tmpfiles.rules = [
          # The 'z' type ensures permissions are applied recursively 
          # and sets the folder up before the service starts.
          "d /mnt/data/postgresql 0750 postgres postgres -"
          "d /mnt/data/postgresql/data 0700 postgres postgres -"
        ];
    
    environment.variables = {
      EDITOR = "nano"; VISUAL = "nano"; 
    };
    environment.systemPackages = with pkgs; [
      age age-plugin-tpm 
      bind
      cloudflared curl
      droidcam docker
      git gptfdisk
      home-manager htop
      jq
      mtr
      pciutils
      sbctl sops ssh-to-age
      tcpdump tree
      util-linux unzip
      vim
      wget
      yggdrasil
    ];
    networking = {
      networkmanager.enable = true;
      firewall.enable = true;
    };
  };
}

