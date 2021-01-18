
{
  description = "nixpkgs-wayland";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    unstableSmall = { url = "github:nixos/nixpkgs/nixos-unstable-small"; };
    cachix = { url = "github:nixos/nixpkgs/nixos-20.09"; };
  };

  outputs = inputs:
    let
      nameValuePair = name: value: { inherit name value; };
      genAttrs = names: f: builtins.listToAttrs (map (n: nameValuePair n (f n)) names);
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = genAttrs supportedSystems;
      pkgsFor = includeOverlay: pkgs: system:
        import pkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = if includeOverlay then [ inputs.self.overlay ] else [];
        };
      opkgs_ = genAttrs (builtins.attrNames inputs) (inp: genAttrs supportedSystems (sys: pkgsFor true  inputs."${inp}" sys));
      npkgs_ = genAttrs (builtins.attrNames inputs) (inp: genAttrs supportedSystems (sys: pkgsFor false inputs."${inp}" sys));
    in
    rec {
      overlay = final: prev:
        let
          waylandPkgs = rec {
            # wlroots-related
            cage             = prev.callPackage ./pkgs/cage { wlroots = prev.wlroots; };
            drm_info         = prev.callPackage ./pkgs/drm_info {};
            gebaar-libinput  = prev.callPackage ./pkgs/gebaar-libinput {};
            glpaper          = prev.callPackage ./pkgs/glpaper {};
            grim             = prev.callPackage ./pkgs/grim {};
            kanshi           = prev.callPackage ./pkgs/kanshi {};
            imv              = prev.callPackage ./pkgs/imv {
              imv = prev.imv;
            };
            lavalauncher     = prev.callPackage ./pkgs/lavalauncher {};
            mako             = prev.callPackage ./pkgs/mako {};
            nwg-launchers    = prev.callPackage ./pkgs/nwg-launchers {};
            oguri            = prev.callPackage ./pkgs/oguri {};
            rootbar          = prev.callPackage ./pkgs/rootbar {};
            slurp            = prev.callPackage ./pkgs/slurp {};
            sway-unwrapped   = prev.callPackage ./pkgs/sway {};
            swaybg           = prev.callPackage ./pkgs/swaybg {};
            swayidle         = prev.callPackage ./pkgs/swayidle {};
            swaylock         = prev.callPackage ./pkgs/swaylock {};
            waybar           = prev.callPackage ./pkgs/waybar {};
            waypipe          = prev.callPackage ./pkgs/waypipe {};
            wayvnc           = prev.callPackage ./pkgs/wayvnc {};
            wlvncc           = prev.callPackage ./pkgs/wlvncc {
              libvncserver = libvncserver_master;
            };
            wdisplays        = prev.callPackage ./pkgs/wdisplays {};
            wev              = prev.callPackage ./pkgs/wev {};
            wf-recorder      = prev.callPackage ./pkgs/wf-recorder {};
            wlay             = prev.callPackage ./pkgs/wlay {};
            obs-wlrobs       = prev.callPackage ./pkgs/obs-wlrobs {};
            wl-clipboard     = prev.callPackage ./pkgs/wl-clipboard {};
            wl-gammactl      = prev.callPackage ./pkgs/wl-gammactl {};
            wldash           = prev.callPackage ./pkgs/wldash {};
            wlogout          = prev.callPackage ./pkgs/wlogout {};
            wlroots          = prev.callPackage ./pkgs/wlroots {};
            wlr-randr        = prev.callPackage ./pkgs/wlr-randr {};
            wlsunset         = prev.callPackage ./pkgs/wlsunset {};
            wofi             = prev.callPackage ./pkgs/wofi {};
            wtype            = prev.callPackage ./pkgs/wtype {};
            xdg-desktop-portal-wlr = prev.callPackage ./pkgs/xdg-desktop-portal-wlr {};
            # misc
            aml = prev.callPackage ./pkgs/aml {};
            clipman = prev.callPackage ./pkgs/clipman {};
            dunst = prev.callPackage ./pkgs/dunst {
              dunst = prev.dunst;
            };
            gtk-layer-shell = prev.callPackage ./pkgs/gtk-layer-shell {};
            i3status-rust    = prev.callPackage ./pkgs/i3status-rust {};
            neatvnc = prev.callPackage ./pkgs/neatvnc {};
            obs-studio = prev.libsForQt5.callPackage ./pkgs/obs-studio {
              ffmpeg = prev.ffmpeg_4;
              vlc = prev.vlc;
            };
            obs-studio-dmabuf = prev.libsForQt5.callPackage ./pkgs/obs-studio-dmabuf {
              ffmpeg = prev.ffmpeg_4;
              vlc = prev.vlc;
            };
            obs-xdg-portal = prev.callPackage ./pkgs/obs-xdg-portal {
              obs-studio = obs-studio-dmabuf;
            };
            wlfreerdp = prev.callPackage ./pkgs/wlfreerdp {
              inherit (prev) libpulseaudio;
              inherit (prev.gst_all_1) gstreamer gst-plugins-base gst-plugins-good;
            };
            # wayfire stuff
            wayfire          = prev.callPackage ./pkgs/wayfire {};

            libvncserver_master = prev.callPackage ./pkgs/libvncserver_master {
              libvncserver = prev.libvncserver;
            };
          };
        in
          waylandPkgs // { inherit waylandPkgs; };

      packages = forAllSystems (system:
        opkgs_.nixpkgs.${system}.waylandPkgs
      );

      unstableSmallPkgs = forAllSystems (system: with opkgs_.unstableSmall.${system};
          linkFarmFromDrvs "wayland-packages-unstable-small"
            (builtins.attrValues waylandPkgs));

      unstablePkgs = forAllSystems (system: with opkgs_.nixpkgs.${system};
          linkFarmFromDrvs "wayland-packages-unstable"
            (builtins.attrValues waylandPkgs));

      defaultPackage = unstablePkgs;

      devShell = forAllSystems (system:
        opkgs_.nixpkgs.${system}.mkShell {
          nativeBuildInputs = []
            ++ (with opkgs_.cachix.${system}; [ cachix ])
            ++ (with opkgs_.nixpkgs.${system}; [
                nixUnstable nix-prefetch nix-build-uncached
                bash cacert curl git jq mercurial openssh ripgrep parallel
            ])
          ;
        }
      );
    };
}
