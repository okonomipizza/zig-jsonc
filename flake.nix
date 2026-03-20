{
  description = "A zig library for parsing JSON with Comments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    zls = {
      url = "github:zigtools/zls/0.15.1";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        zig-overlay.follows = "zig";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    zig,
    zls,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: 
      let
        pkgs = nixpkgs.legacyPackages.${system};
        zig-pkg = zig.packages.${system}."0.15.2";
        zls-pkg = zls.packages.${system}.zls;
      in {
        devShells.default = pkgs.mkShell {
          packages = [zig-pkg zls-pkg];
          shellHook = ''
            echo "zig: $(zig version)"
          '';
        };

        formatter = pkgs.alejandra;
      }
    );
}
