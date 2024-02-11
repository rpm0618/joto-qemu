{
    description = "ESP32 QEMU with patches to enable emulating the Joto whiteboard firmware";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-22.05";

        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { self, nixpkgs, flake-utils }:
        flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
            pkgs = import nixpkgs {
                inherit system;
            };
            buildOnlyPackages = with pkgs; [
                pkg-config flex bison ninja python3
            ];
            runtimePackages = with pkgs; [
                # git
                # wget
                # flex
                # bison
                gperf
                glib
                pixman
                libgcrypt
                libslirp
                # ninja
                # pkg-config
                # python3
            ];
        in {
            devShells.default = pkgs.mkShell {
                name = "joto-qemu";
                packages = buildOnlyPackages ++ runtimePackages;
            };
            packages.default = pkgs.stdenv.mkDerivation {
                name = "joto-qemu";
                src = self;
                nativeBuildInputs = buildOnlyPackages;
                buildInputs = runtimePackages;
                configureFlags = [
                    "--target-list=xtensa-softmmu"
                    "--enable-gcrypt"
                    "--enable-debug"
                    "--enable-sanitizers"
                    "--disable-strip"
                    "--disable-user"
                    "--disable-capstone"
                    "--disable-vnc"
                    "--disable-sdl"
                    "--disable-gtk"
                ];
                buildPhase = "ninja -C build";
                installPhase = "mkdir -p $out/bin; cp build/qemu-system-xtensa $out/bin/";
            };
        });
}
