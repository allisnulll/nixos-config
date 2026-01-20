{ pkgs, inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.neovim-nightly-overlay.overlays.default

    (final: prev: {
      nvimpager = prev.nvimpager.overrideAttrs (old: {
        patches = (old.patches or []) ++ [ ./nvimpager.patch ];
      });
    })

    (final: prev: {
      sekirofpsunlock = prev.stdenv.mkDerivation {
        pname = "sekirofpsunlock";
        version = "0.2.3";
        src = builtins.fetchTarball {
          url = "https://github.com/Lahvuun/sekirofpsunlock/archive/master.tar.gz";
          sha256 = "1vmx6fcv7wqxd5zgcciaqwdgrh5l6rspl61z32fc3jzkibccg28a";
        };
        nativeBuildInputs = with prev; [ meson ninja ];

        mesonBuildType = "release";
        dontUseMesonConfigure = true;

        buildPhase = ''
          meson build -Db_ndebug=if-release -Dbuildtype=release
          ninja -C build
        '';

        installPhase = ''
          install -Dm755 build/sekirofpsunlock -t $out/bin
        '';
      };
    })
  ];
}
