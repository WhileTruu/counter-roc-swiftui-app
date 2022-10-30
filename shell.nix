with import <nixpkgs> { };
let
  roc = stdenv.mkDerivation {
    pname = "roc";
    version = "0.0.1";
    src = fetchurl {
      # nix-prefetch-url this URL to find the hash value
      url =
        "https://github.com/roc-lang/roc/releases/download/nightly/roc_nightly-macos_12_apple_silicon-2022-10-29-ae1a9e4.tar.gz";
      sha256 = "d31311c42f37ff5adc98faa821ddbdf818d2bc0445a263cec19363125171cc20";
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cd $out/bin && tar -zxf $src
    '';
  };

in mkShell {
  name = "env";
  buildInputs = [
    roc
  ];
}