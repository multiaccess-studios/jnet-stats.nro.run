{
  description = "Development and deployment environment for jnet-stats.nro.run";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = function:
        nixpkgs.lib.genAttrs systems (system: function nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.actionlint
            pkgs.awscli2
            pkgs.bun
            pkgs.shellcheck
          ];
        };
      });

      apps = forAllSystems (
        pkgs:
        let
          scriptApp =
            name: runtimeInputs: script:
            let
              package = pkgs.writeShellApplication {
                inherit name runtimeInputs;
                text = ''
                  exec "''${PWD}/scripts/${script}" "$@"
                '';
              };
            in
            {
              type = "app";
              program = "${package}/bin/${name}";
            };
        in
        {
          build = scriptApp "jnet-stats-build" [ pkgs.bun ] "build.sh";
          check = scriptApp "jnet-stats-check" [ pkgs.bun ] "check.sh";
          deploy = scriptApp "jnet-stats-deploy" [
            pkgs.awscli2
            pkgs.bun
          ] "deploy.sh";
        }
      );

      checks = forAllSystems (pkgs: {
        repository-contract = pkgs.runCommand "jnet-stats-repository-contract" {
          nativeBuildInputs = [
            pkgs.actionlint
            pkgs.shellcheck
          ];
        } ''
          shellcheck ${self}/scripts/*.sh
          actionlint \
            -config-file ${self}/.github/actionlint.yaml \
            ${self}/.github/workflows/*.yml
          touch "$out"
        '';
      });
    };
}
