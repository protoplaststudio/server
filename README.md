# server

# This creates a file named 'key.txt' containing your private key
nix run nixpkgs#age-keygen -- -o key.txt
age-keygen -o key.txt

# This will ask you to enter a passphrase
nix run nixpkgs#age -- -p -o key.txt.age key.txt
age -p -o key.txt.age key.txt

ssh-keygen -t ed25519 -f <path> -C "name"

env -u SOPS_AGE_KEY_FILE SOPS_AGE_KEY=$(nix run nixpkgs#age -- -d secrets/protoplast.age 2>/dev/null | grep AGE-SECRET-KEY) nix run nixpkgs#sops -- secrets/server.yaml


env -u SOPS_AGE_KEY_FILE SOPS_AGE_KEY=$(nix run nixpkgs#age -- -d secrets/protoplast.age 2>/dev/null | grep AGE-SECRET-KEY) nix run nixpkgs#sops -- updatekeys secrets/server.yaml

sudo SOPS_AGE_KEY_FILE=/etc/laptopboot.txt EDITOR=nano sops secrets/laptop.yaml

nix --extra-experimental-features "nix-command flakes" run nixpkgs#age-plugin-tpm -- --generate -o /etc/serverboot.txt




NIX_CONFIG="experimental-features = nix-command flakes pipe-operators" nix run nixpkgs#disko -- --mode disko --flake github:protoplaststudio/server#protoplast-server

NIX_CONFIG="experimental-features = nix-command flakes pipe-operators" nixos-install --flake github:protoplaststudio/server#protoplast-server

NIX_CONFIG="experimental-features = nix-command flakes pipe-operators" nixos-rebuild switch --flake github:protoplaststudio/server#protoplast-server


protoplast_erpnext:
  # Core / Auth
  ERPNEXT_VERSION: "v16.25.0"
  SITE_NAME: "erp.protoplast.in"
  ADMIN_PASSWORD: "your_secure_web_admin_password_here"
  
  # Database
  DB_PASSWORD: "your_secure_database_root_password_here"
  DB_HOST: "erpnext-db"
  DB_PORT: "3306"
  
  # Redis
  REDIS_CACHE: "erpnext-redis-cache:6379"
  REDIS_QUEUE: "erpnext-redis-queue:6379"
  
  # Tuning
  GUNICORN_THREADS: "4"
  GUNICORN_WORKERS: "3"
  GUNICORN_TIMEOUT: "120"
  
  # Nginx / Frontend
  UPSTREAM_REAL_IP_ADDRESS: "127.0.0.1"
  UPSTREAM_REAL_IP_HEADER: "X-Forwarded-For"
  UPSTREAM_REAL_IP_RECURSIVE: "off"
  PROXY_READ_TIMEOUT: "120"
  CLIENT_MAX_BODY_SIZE: "50m"