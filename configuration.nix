{ config, lib, pkgs, inputs, ... }: let
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  hyprland-packages = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    ./hardware-configuration.nix
    inputs.hyprland.nixosModules.default
    inputs.spicetify-nix.nixosModules.default
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "usbcore.autosuspend=-1" "btusb.enable_autosuspend=0" "hid_sony.latency_enable=1" "bluetooth.disable_ertm=1" "bluetooth.disable_esco=1" ];
  boot.kernelModules = [ "hid-sony" "hid-playstation" ];
  boot.blacklistedKernelModules = [ "hid_xpadneo" ];

  time.timeZone = "America/Puerto_Rico";

  networking.hostName = "0riDsc-AIN";
  networking.networkmanager.enable = true;
  networking.nameservers = [ "8.8.8.8" "8.8.2.2" ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    EDITOR = "nvim";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/allisnull/.steam/root/compatibilitytools.d";
  };

  environment.systemPackages = with pkgs; [
    nix-ld
    kanata-with-cmd
    vim
    xdg-user-dirs
    pavucontrol
    brightnessctl
    playerctl
    samba
    powertop
    waybar
  ];

  users.users.allisnull = {
    isNormalUser = true;
    description = "AllIsNull";
    extraGroups = [ "wheel" "networkmanager" "audio" "input" "uinput" "dialout" ];
    shell = pkgs.zsh;
    packages = (with pkgs; [
      neovim
      nvimpager
      tree-sitter

      nix-tree

      git
      stow

      fastfetch
      eza
      zoxide
      btop-rocm
      htop
      tmux

      sesh
      fzf
      ripgrep
      fd
      jq
      wget
      magic-wormhole
      bc

      binutils
      usbutils
      lm_sensors

      gcc
      gnumake
      cmake
      libclang
      rustup
      python3
      python313Packages.pip
      pyenv
      jdk
      nodejs_24
      luajit
      go
      php
      php84Packages.composer
      unzip
      lsof

      dunst
      libnotify
      imv
      grim
      grimblast
      wl-clipboard
      cliphist
      waybar
      rofi
      rofimoji
      corrupter
      # quickshell

      wezterm
      kitty
      tectonic
      ghostscript
      mermaid-cli
      imagemagick
      ffmpeg
      tealdeer

      adwaita-icon-theme
      xfce.thunar
      zip
      p7zip
      xarchiver
      blueman
      nwg-look
      qdirstat
      kdiskmark
      qdiskinfo

      neovide
      gedit

      protonvpn-gui
      ungoogled-chromium
      google-chrome
      tor-browser
      vesktop
      spotube

      vlc
      mpv
      gimp-with-plugins
      inkscape-with-extensions
      kdePackages.kdenlive
      davinci-resolve
      audacity
      blender-hip

      piper
      mangohud
      protonup-ng
      lutris
      heroic
      prismlauncher
      nestopia-ue
      sekirofpsunlock
      olympus
      linux-wallpaperengine
    ])
      ++
    (with pkgs-unstable; [
      hyprpaper
      hypridle
      hyprsunset
      hyprpicker
      hyprsysteminfo

      opencode
    ]);
  };

  security.sudo.wheelNeedsPassword = false;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraConfig.pipewire = {
      "main" = {
        context.properties = {
          "default.clock.rate" = 192000;
          "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];
          "default.clock.quantum" = 512;
          "default.clock.min-quantum" = 512;
          "default.clock.max-quantum" = 2048;
        };
      };
    };
  };

  services.openssh.enable = true;
  services.getty.autologinUser = "allisnull";

  services.xserver.videoDrivers = [ "amdgpu" ];

  systemd.user.services.waybar-multi-monitor = {
    description = "Waybar multi-monitor status bar";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "forking";
      ExecStart = let
        waybarScript = pkgs.writeShellScript "waybar-start" ''
          #!${pkgs.bash}/bin/bash
          export PATH="${lib.makeBinPath (with pkgs; [jq hyprland-packages.hyprland procps bash gawk waybar lm_sensors])}:$PATH"
          export WAYLAND_DISPLAY="wayland-1"
          export XDG_SESSION_TYPE="wayland"
          cd /home/allisnull/nixos-config
          sleep 5
          pkill -f "waybar -c.*monitor" 2>/dev/null || true
          sleep 1
          ./waybar.sh
        '';
      in "${waybarScript}";
      WorkingDirectory = "/home/allisnull/nixos-config";
      Restart = "on-failure";
      RestartSec = "15s";
    };
  };

  systemd.user.services.kanata-custom = {
    description = "Kanata keyboard remapper";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = let
        kanataScript = pkgs.writeShellScript "kanata-start" ''
          #!${pkgs.bash}/bin/bash
          export PATH="${lib.makeBinPath (with pkgs; [kanata-with-cmd libnotify procps coreutils])}:$PATH"
          export WAYLAND_DISPLAY="wayland-1"
          export XDG_SESSION_TYPE="wayland"
          export XDG_RUNTIME_DIR="/run/user/1000"
          export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
          cd /home/allisnull/nixos-config
          exec kanata --cfg ./kanata.kbd
        '';
      in "${kanataScript}";
      WorkingDirectory = "/home/allisnull/nixos-config";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  services.ratbagd.enable = true;

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
      maple-mono.NF
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" ];
    };
  };

  xdg.mime.defaultApplications = {
    "inode/directory" = "thunar.desktop";
    "x-scheme-handler/http" = "ungoogled-chromium.desktop";
    "x-scheme-handler/https" = "ungoogled-chromium.desktop";
    "x-scheme-handler/about" = "ungoogled-chromium.desktop";
    "x-scheme-handler/unknown" = "ungoogled-chromium.desktop";
    "text/html" = "ungoogled-chromium.desktop";
    "application/xhtml+xml" = "ungoogled-chromium.desktop";
    "text/plain" = "neovide.desktop";
    "text/x-log" = "neovide.desktop";
    "image/png" = "imv.desktop";
    "image/jpeg" = "imv.desktop";
    "image/gif" = "imv.desktop";
    "image/webp" = "imv.desktop";
    "image/svg+xml" = "imv.desktop";
    "application/pdf" = "ungoogled-chromium.desktop";
    "video/mp4" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/quicktime" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "audio/mpeg" = "vlc.desktop";
    "audio/mp3" = "vlc.desktop";
    "audio/flac" = "vlc.desktop";
    "audio/ogg" = "vlc.desktop";
    "audio/wav" = "vlc.desktop";
    "application/zip" = "xarchiver.desktop";
    "application/x-7z-compressed" = "xarchiver.desktop";
    "application/x-rar-compressed" = "xarchiver.desktop";
    "application/x-tar" = "xarchiver.desktop";
    "application/gzip" = "xarchiver.desktop";
    "x-scheme-handler/discord" = "vesktop.desktop";
    "x-scheme-handler/terminal" = "wezterm.desktop";
    "application/x-nes-rom" = "nestopia.desktop";
  };

  programs = {
    zsh.enable = true;
    yazi.enable = true;

    hyprland = {
      package = hyprland-packages.hyprland;
      portalPackage = hyprland-packages.xdg-desktop-portal-hyprland;
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      plugins = [ inputs.hyprhook.packages.${pkgs.stdenv.hostPlatform.system}.hyprhook ];
    };

    dconf.profiles.user.databases = [{
      settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        cursor-theme = "Milk-icons";
        gtk-theme = "Milk-Outside-a-Bag-of-Milk";
        icon-theme = "Milk-icons";
        font-name = "Adwaita Sans Regular 11";
        document-font-name = "JetbrainsMono NF 11";
        monospace-font-name = "JetbrainsMono NF 11";
      };
    }];

    gtklock = {
      enable = true;
      modules = [ pkgs.gtklock-userinfo-module ];
      config.main.gtk-theme = "Milk-Outside-a-Bag-of-Milk";
      style = toString ./gtklock.css;
    };

    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    gamemode.enable = true;

    obs-studio.enable = true;

    spicetify = let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in {
      enable = true;
      theme = spicePkgs.themes.lucid;
      # colorScheme = "mocha";

      enabledExtensions = with spicePkgs.extensions; [
        adblock
        catJamSynced
        loopyLoop
        betterGenres
        beautifulLyrics
        songStats
        history
        allOfArtist
      ];
      enabledCustomApps = with spicePkgs.apps; [];
      enabledSnippets = with spicePkgs.snippets; [];
    };
  };

  hardware = {
    graphics = let
      hyprland-legacy = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in {
      package = hyprland-legacy.mesa;
      package32 = hyprland-legacy.pkgsi686Linux.mesa;
      enable = true;
      enable32Bit = true;
    };

    uinput.enable = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      package = pkgs.bluez.overrideAttrs (oldAttrs: {
        configureFlags = oldAttrs.configureFlags ++ [ "--enable-sixaxis" ];
      });
      settings = {
        General = {
          ControllerMode = "dual";
          FastConnectable = true;
          JustWorksRepairing = "always";
          Privacy = "off";
          MultiProfile = "multiple";
          Experimental = false;
        };
      };
    };
  };

  systemd.user.services.dualsense-repair = {
    description = "Repair DualSense Bluetooth connection";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = let
        repairScript = pkgs.writeShellScript "dualsense-repair" ''
          #!${pkgs.bash}/bin/bash
          export PATH="${lib.makeBinPath (with pkgs; [bluez coreutils procps])}:$PATH"
          export XDG_RUNTIME_DIR="/run/user/1000"
          export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
          
          DUALSENSE_MAC="58:10:31:BB:CF:D4"
          
          while true; do
            if bluetoothctl info "$DUALSENSE_MAC" 2>/dev/null | grep -q "Connected: no"; then
              echo "DualSense disconnected, attempting repair..."
              bluetoothctl disconnect "$DUALSENSE_MAC" 2>/dev/null || true
              sleep 2
              bluetoothctl connect "$DUALSENSE_MAC" 2>/dev/null || true
            fi
            sleep 10
          done
        '';
      in "${repairScript}";
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };

  services.udev.extraRules = ''
    # Sony DualSense (USB)
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0666", TAG+="uaccess"
    
    # Sony DualSense (Bluetooth)  
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", KERNELS=="0005:054C:0CE6.*", MODE="0666", TAG+="uaccess"
    
    # Sony DualSense Edge (USB)
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0df2", MODE="0666", TAG+="uaccess"
    
    # Sony DualSense Edge (Bluetooth)
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", KERNELS=="0005:054C:0DF2.*", MODE="0666", TAG+="uaccess"
    
    # Disable problematic services for DualSense
    ACTION=="add", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ENV{ID_AUTOSEAT}="1"
    
    # Bluetooth dualshock4/dualsense fixes
    SUBSYSTEM=="input", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc|0ce6|0df2", ENV{ID_INPUT_JOYSTICK}="1", ENV{ID_INPUT_ACCELEROMETER}="1"
    
    # ds4drv udev rules for bypassing BlueZ
    KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
    SUBSYSTEM=="input", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666"
    
    
  '';

  systemd.tmpfiles.rules = [
    "d /var/lib/bluetooth 0755 root root -"
    "d /var/lib/bluetooth/* 0755 root root -"
    "d /var/lib/bluetooth/*/cache 0755 root root -"
  ];

  systemd.services.bluetooth-input-config = {
    description = "Create Bluetooth input.conf for DualSense";
    after = ["bluetooth.service"];
    wantedBy = ["bluetooth.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = let
        inputConf = pkgs.writeText "input.conf" ''
[General]
ClassicBondedOnly=false
LEAutoReconnect=true
ReconnectAttempts=10
ReconnectIntervals=1,2,4,8,16,32,64,128
UserspaceHID=true
'';
      in "${pkgs.coreutils}/bin/cp ${inputConf} /etc/bluetooth/input.conf";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ hyprland-packages.xdg-desktop-portal-hyprland ];
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  system.stateVersion = "25.11";
}
