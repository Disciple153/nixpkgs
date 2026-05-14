# pkgs/by-name/li/libfprint-goodix-521d/package.nix
#
# Community libfprint fork adding driver support for the Goodix 521d and 538d
# fingerprint sensors (USB ID 27c6:521d / 27c6:538d).
#
# Found in: ASUS ROG Zephyrus G14 GA401I (and possibly other devices).
#
# IMPORTANT: The sensor requires a one-time firmware flash before this driver
# will function. See the upstream explanation at:
#   https://github.com/knauth/goodix-521d-explanation
#
# Upstream driver fork: https://github.com/infinytum/libfprint  (branch: unstable)
# Tracks nixpkgs issue: https://github.com/NixOS/nixpkgs/issues/424877

{ lib
, stdenv
, fetchgit
, pkg-config
, meson
, ninja
, cmake
, gobject-introspection
, gusb
, libgudev
, pixman
, nss
, openssl
, glib
, python3
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libfprint-goodix-521d";
  version = "unstable-2024-12-28";

  src = fetchgit {
    url  = "https://github.com/infinytum/libfprint.git";
    rev  = "refs/heads/unstable";
    # To update, run:
    #   nix-prefetch-git https://github.com/infinytum/libfprint --rev <commit-sha>
    # and paste the resulting sha256 here.
    hash = "sha256-MFhPsTF0oLUMJ9BIRZnSHj9VRwtHJxvWv0WT5zz7vDY=";
  };

  nativeBuildInputs = [
    pkg-config
    meson
    ninja
    cmake
    gobject-introspection
    python3
  ];

  buildInputs = [
    gusb
    libgudev
    pixman
    nss
    openssl
    glib
  ];

  mesonFlags = [
    # doc and gtk-examples are plain booleans in this fork's meson_options.txt
    "-Ddoc=false"
    "-Dgtk-examples=false"
    # udev_rules_dir and udev_hwdb_dir are plain strings; pass explicit paths
    # so meson does not fall back to querying systemd via pkg-config, which
    # would return systemd's read-only store path.
    "-Dudev_rules_dir=${builtins.placeholder "out"}/lib/udev/rules.d"
    "-Dudev_hwdb=disabled"
  ];

  postPatch = ''
    # -Wincompatible-pointer-types is a hard error in GCC 14+ (NixOS 24.11+).
    # This matches the workaround used in the upstream AUR PKGBUILD.
    sed -i "/common_cflags = cc.get_supported_arguments(\[/a \    '-Wno-incompatible-pointer-types'," \
      meson.build || true
  '';

  meta = {
    description = "libfprint fork with support for Goodix 521d and 538d fingerprint sensors";
    longDescription = ''
      A community-maintained fork of libfprint that adds driver support for the
      Goodix 521d (USB ID 27c6:521d) and 538d fingerprint sensors found in
      devices such as the ASUS ROG Zephyrus G14 GA401I.

      This sensor is not supported by the mainline libfprint package due to its
      small resolution and encrypted communication protocol. The sensor also
      requires a one-time firmware flash using goodix-fp-dump before the driver
      will function:

        https://github.com/mpi3d/goodix-fp-dump
        https://github.com/knauth/goodix-521d-explanation

      Usage with fprintd:
        services.fprintd = {
          enable = true;
          package = pkgs.fprintd.override {
            libfprint = pkgs.libfprint-goodix-521d;
          };
        };
    '';
    homepage    = "https://github.com/infinytum/libfprint";
    license     = lib.licenses.lgpl21Plus;
    platforms   = lib.platforms.linux;
    maintainers = [ lib.maintainers.your-handle ]; # replace with your handle
  };
})
