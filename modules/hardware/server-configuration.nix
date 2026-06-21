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
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "us";
    virtualisation.docker.enable = true;
    services = {
      printing.enable = true;
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
      ollama = {
        enable = true;
      };
      pcscd.enable = true;
    };
    
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

