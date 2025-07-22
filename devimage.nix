{ pkgs ? import <nixpkgs> { }
, system ? builtins.currentSystem
}:

let
  # Create the coder user configuration
  coderUser = {
    uid = 1000;
    gid = 1000;
    home = "/home/coder";
    shell = "${pkgs.bash}/bin/bash";
  };

  # Mise installation script
  miseInstallScript = pkgs.writeScript "install-mise.sh" ''
    #!${pkgs.bash}/bin/bash
    set -e
    export HOME=/home/coder
    export MISE_DATA_DIR="$HOME/.local/share/mise"
    export MISE_CONFIG_DIR="$HOME/.config/mise"
    export MISE_CACHE_DIR="$HOME/.cache/mise"
    export MISE_INSTALL_PATH="$HOME/.local/bin/mise"
    
    mkdir -p $HOME/.local/bin
    ${pkgs.curl}/bin/curl -fsSL https://mise.run | ${pkgs.bash}/bin/bash
  '';

  # Declaratively create user files
  userFiles = pkgs.runCommand "user-files" {} ''
    mkdir -p $out/etc
    
    # Create /etc/passwd
    cat > $out/etc/passwd <<EOF
    root:x:0:0:root:/root:/bin/sh
    nobody:x:65534:65534:nobody:/var/empty:/bin/false
    coder:x:${toString coderUser.uid}:${toString coderUser.gid}:Coder User:${coderUser.home}:${coderUser.shell}
    EOF
    
    # Create /etc/group
    cat > $out/etc/group <<EOF
    root:x:0:
    nobody:x:65534:
    coder:x:${toString coderUser.gid}:
    EOF
    
    # Create /etc/shadow
    cat > $out/etc/shadow <<EOF
    root:!:19000:0:99999:7:::
    nobody:!:19000:0:99999:7:::
    coder:!:19000:0:99999:7:::
    EOF
    
    chmod 0644 $out/etc/passwd $out/etc/group
    chmod 0600 $out/etc/shadow
    
    # Create sudoers file
    mkdir -p $out/etc/sudoers.d
    echo "coder ALL=(ALL) NOPASSWD:ALL" > $out/etc/sudoers.d/nopasswd
    chmod 0440 $out/etc/sudoers.d/nopasswd
  '';

in
pkgs.dockerTools.streamLayeredImage {
  name = "devimage";
  tag = "latest";
  
  fromImage = pkgs.dockerTools.pullImage {
    imageName = "debian";
    imageDigest = "sha256:2424c1850714a4d94666ec928e24d86de958646737b1d113f5b2207be44d37d8";
    sha256 = "sha256-O6oFV3kh1WYF60Pv6nMGtJ/q3ujNbxxqLFpKzopfe48=";
    finalImageTag = "bookworm-slim";
    finalImageName = "debian";
  };

  contents = pkgs.buildEnv {
    name = "image-root";
    paths = [
      userFiles  # Include our declarative user configuration
    ] ++ (with pkgs; [
      # Core system
      bash
      coreutils
      findutils
      gnugrep
      gawk
      gnused
      
      # Build tools
      gcc
      gnumake
      cmake
      pkg-config
      
      # Development tools
      git
      git-lfs
      curl
      wget
      rsync
      jq
      htop
      man
      sudo
      vim
      neovim
      unzip
      
      # Language support
      python3
      python3Packages.pip
      
      # Modern CLI tools
      ripgrep
      fd
      
      # Archive tools
      atool
      zip
      p7zip
      xz
      bzip2
      
      # System libraries
      cacert
      gnupg
      lsb-release
      
      # Docker tools
      docker
      docker-compose
      
      # Locale data
      glibcLocales
    ]);
    pathsToLink = [ "/bin" "/etc" "/lib" "/share" "/usr" "/sbin" ];
  };

  config = {
    Cmd = [ "${pkgs.bash}/bin/bash" ];
    
    Env = [
      "DEBIAN_FRONTEND=noninteractive"
      "SHELL=/bin/bash"
      "DOCKER_BUILDKIT=1"
      "LANG=en_US.UTF-8"
      "LANGUAGE=en_US.UTF-8"
      "LC_ALL=en_US.UTF-8"
      "PATH=/home/coder/.local/share/mise/shims:/home/coder/.local/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      "HOME=/home/coder"
      "MISE_DATA_DIR=/home/coder/.local/share/mise"
      "MISE_CONFIG_DIR=/home/coder/.config/mise"
      "MISE_CACHE_DIR=/home/coder/.cache/mise"
      "MISE_INSTALL_PATH=/home/coder/.local/bin/mise"
    ];
    
    User = "coder";
    WorkingDir = "/home/coder";
  };

  extraCommands = ''
    # Create home directory structure
    mkdir -p home/coder/.local/bin
    mkdir -p home/coder/.local/share/mise/shims
    mkdir -p home/coder/.config/mise
    mkdir -p home/coder/.cache/mise
    
    # Create standard directories
    mkdir -p usr/bin usr/sbin bin sbin
    
    # Create locale configuration
    mkdir -p etc/default
    echo "LANG=en_US.UTF-8" > etc/default/locale
  '';

  fakeRootCommands = ''
    # Create home directory with proper ownership first
    mkdir -p ${coderUser.home}
    chown ${toString coderUser.uid}:${toString coderUser.gid} ${coderUser.home}
    
    # Install mise as coder user
    sudo -u coder ${miseInstallScript}
    
    # Ensure ownership of all home directory contents
    chown -R ${toString coderUser.uid}:${toString coderUser.gid} ${coderUser.home}
  '';
  
  enableFakechroot = true;
}