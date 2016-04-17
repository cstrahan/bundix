with (import <nixpkgs> {});
let
  env = bundlerEnv {
    name = "PROJECT-bundler-env";
    inherit RUBY;
    gemfile  = ./Gemfile;
    lockfile = LOCKFILE;
    gemset   = GEMSET;
  };
in stdenv.mkDerivation {
  name = "PROJECT";
  buildInputs = [ env ];
}
