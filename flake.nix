{
  description = "Hoyolab Genshin daily check in script";

  inputs = {
    nixpkgs.url = github:poscat0x04/nixpkgs/dev;
    flake-utils.url = github:poscat0x04/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlay = final: prev: {
      genshin-py = with final; with pkgs.python3Packages; buildPythonPackage rec {
        pname = "genshin";
        version = "1.2.2";

        src = fetchPypi {
          inherit pname version;
          sha256 = "sha256-PugJ1Y8757s7zRdTWy1PJqIX94y4meKqozefpVj+RY0=";
        };

        buildInputs = [
        ];

        propagatedBuildInputs = [
          aiohttp
          pydantic
          yarl
        ];

        doCheck = false;
      };
      genshin-checkin = prev.writers.writePython3 "genshin-checkin.py"
        {
          libraries = [ final.genshin-py ];
          flakeIgnore = [ "E501" ];
        }
        (builtins.readFile ./genshin-checkin.py);
    };
    nixosModules.genshin-checkin = { config, lib, pkgs, ... }:
      let
        cfg = config.services.genshin-checkin;
        configFile = pkgs.writeText "cookies.json" (builtins.toJSON { inherit (cfg) ltoken ltuid; });
      in
      {
        options.services.genshin-checkin = with lib; with types; {
          enable = lib.mkEnableOption "hoyolab genshin check-in service";

          ltoken = mkOption {
            type = str;
          };

          ltuid = mkOption {
            type = str;
          };
        };
        config = lib.mkIf cfg.enable {
          systemd = {
            services.genshin-checkin = {
              after = [ "network-online.target" ];
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.genshin-checkin} -c ${configFile}";
              };
            };
            timers.genshin-checkin = {
              wantedBy = [ "timers.target" ];
              timerConfig = {
                RandomizedDelaySec = "1h";
                OnCalendar = "*-*-* 8:00:00 CST";
                Persistent = true;
              };
            };
          };
        };
      };
  } // flake-utils.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
    in
    {
      packages = {
        inherit (pkgs) genshin-py genshin-checkin;
      };
      devShell = with pkgs; mkShell {
        buildInputs = [
          mypy
          pylint
          (python3.withPackages (p: [
            pkgs.genshin-py
            p.autopep8
          ]))
        ];
      };
    });
}
