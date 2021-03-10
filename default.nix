{ pkgs ? import (import ./nix/sources.nix).nixpkgs {} }:
let
  nodeEnv = import ./node-env.nix {
    inherit pkgs;
    inherit (pkgs) stdenv lib python2 runCommand writeTextFile;
    nodejs = pkgs.nodejs-14_x;
    libtool = if pkgs.stdenv.isDarwin then pkgs.darwin.cctools else null;
  };
  relayPackages = import ./node-packages.nix {
    inherit nodeEnv;
    inherit (pkgs) fetchurl fetchgit nix-gitignore stdenv lib;
  };
in rec {
  relay = pkgs.stdenv.mkDerivation {
    pname = "relay";
    version = "1.1.0";
    src = pkgs.nix-gitignore.gitignoreSource [ "ops" ] ./.;
    buildInputs = [ pkgs.nodejs-14_x ];
    buildPhase = ''
      export HOME=$TMP
      ln -s ${relayPackages.nodeDependencies}/lib/node_modules ./node_modules
    '';
    installPhase = ''
      mkdir -p $out
      ${pkgs.nodejs-14_x}/bin/npm run --prefix compile
      cp -r . $out/
      export PATH=${pkgs.nodejs-14_x}/bin:$out:$PATH
    '';
  };
  docker = pkgs.dockerTools.buildLayeredImage {
    name = relay.pname;
    config = {
      Cmd = [ "${pkgs.nodejs-14_x}/bin/node" "${relay}/relay/dist" ];
    };
  };
}
