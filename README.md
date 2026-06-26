# server

# This creates a file named 'key.txt' containing your private key
nix run nixpkgs#age-keygen -- -o key.txt
age-keygen -o key.txt

# This will ask you to enter a passphrase
nix run nixpkgs#age -- -p -o key.txt.age key.txt
age -p -o key.txt.age key.txt

ssh-keygen -t ed25519 -f <path> -C "name"

env -u SOPS_AGE_KEY_FILE SOPS_AGE_KEY=$(nix run nixpkgs#age -- -d secrets/protoplast.age 2>/dev/null | grep AGE-SECRET-KEY) nix run nixpkgs#sops -- secrets/protoplast-server.yaml


env -u SOPS_AGE_KEY_FILE SOPS_AGE_KEY=$(nix run nixpkgs#age -- -d secrets/protoplast.age 2>/dev/null | grep AGE-SECRET-KEY) nix run nixpkgs#sops -- updatekeys secrets/protoplast-server.yaml

sudo SOPS_AGE_KEY_FILE=/etc/laptopboot.txt EDITOR=nano sops secrets/laptop.yaml

nix --extra-experimental-features "nix-command flakes" run nixpkgs#age-plugin-tpm -- --generate -o /etc/serverboot.txt




NIX_CONFIG="experimental-features = nix-command flakes pipe-operators" nix run nixpkgs#disko -- --mode disko --flake github:protoplaststudio/server#protoplast-server

NIX_CONFIG="experimental-features = nix-command flakes pipe-operators" nixos-install --flake github:protoplaststudio/server#protoplast-server

NIX_CONFIG="experimental-features = nix-command flakes pipe-operators" nixos-rebuild switch --flake github:protoplaststudio/server#protoplast-server


