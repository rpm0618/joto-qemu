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
                pkg-config
                flex
                bison
                ninja
                python3
            ];
            runtimePackages = with pkgs; [
                gperf
                glib
                pixman
                libgcrypt
                libslirp
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
                # installPhase = "mkdir -p $out/bin; cp build/qemu-system-xtensa $out/bin/";
                installPhase = ''
                    mkdir -p $out/bin
                    mkdir -p $out/share/qemu-firmware
                    cp build/qemu-system-xtensa $out/bin/
                    cp pc-bios/esp32-v3-rom.bin $out/share/qemu-firmware/
                    cp pc-bios/esp32-v3-rom-app.bin $out/share/qemu-firmware/
                '';
            };
        });
}
