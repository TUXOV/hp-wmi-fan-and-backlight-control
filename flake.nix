{
  description = "Install the hp-wmi-fan-and-backlight-control kernel module on NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      systems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs systems;
      dkmsLines = lib.splitString "\n" (builtins.readFile ./dkms.conf);
      versionMatch = lib.findFirst (m: m != null) null (
        map (builtins.match ''PACKAGE_VERSION="([^"]+)".*'') dkmsLines
      );
      baseVersion = if versionMatch == null then "unknown" else lib.head versionMatch;

      mkModule =
        {
          stdenv,
          lib,
          kernel,
          kernelModuleMakeFlags,
        }:
        stdenv.mkDerivation {
          pname = "hp-wmi-fan-and-backlight-control";
          version = "${baseVersion}-${kernel.version}";

          src = lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.unions [
              ./Makefile
              ./hp-wmi.c
            ];
          };

          enableParallelBuilding = true;

          nativeBuildInputs = kernel.moduleBuildDependencies;

          makeFlags = kernelModuleMakeFlags ++ [
            "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
            "INSTALL_MOD_PATH=${placeholder "out"}"
            "INSTALL_MOD_DIR=extra"
            "DEPMOD=true"
          ];

          installTargets = [ "modules_install" ];
          installFlags = [
            "-C"
            "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
            "M=$(PWD)"
          ];

          meta = {
            description = "Linux kernel module for HP Laptops";
            homepage = "https://github.com/Vilez0/hp-wmi-fan-and-backlight-control";
            license = lib.licenses.gpl2Plus;
            maintainers = with lib.maintainers; [ ern775 ];
            platforms = lib.platforms.linux;
          };
        };

      hpWmiControlModule =
        {
          config,
          lib,
          ...
        }:
        let
          inherit (lib)
            mkEnableOption
            mkIf
            mkOption
            types
            literalExpression
            ;
          cfg = config.hardware.hp-wmi-control;
        in
        {
          imports = [
            (lib.mkRemovedOptionModule [
              "hardware"
              "hp-wmi-control"
              "victus-15-support"
              "enable"
            ] "Supported boards are now detected by DMI name, this option is no longer available.")
          ];

          options.hardware.hp-wmi-control = {
            enable = mkEnableOption "the hp-wmi-fan-and-backlight-control kernel module";

            package = mkOption {
              type = types.package;
              default = config.boot.kernelPackages.callPackage mkModule { };
              defaultText = literalExpression "config.boot.kernelPackages.callPackage mkModule { }";
              description = "The kernel module package to use.";
            };
          };

          config = mkIf cfg.enable {
            boot.extraModulePackages = [ cfg.package ];
          };
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          hp-wmi-control = pkgs.linuxPackages.callPackage mkModule { };
          default = hp-wmi-control;
        }
      );

      nixosModules = {
        default = hpWmiControlModule;
        hp-wmi-control = hpWmiControlModule;
      };
    };
}
