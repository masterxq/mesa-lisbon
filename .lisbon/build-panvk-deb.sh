#!/bin/sh
set -eu

usage() {
	cat <<EOF
Usage: $0 deps|build|package|all

  deps     install the build dependencies (Debian, as root)
  build    configure and build PanVK into \$BUILD
  package  assemble the panvk-lisbon .deb into \$OUT
  all      deps, build and package

Environment:
  BUILD        build directory (default: <source>/build-panvk)
  OUT          output directory for the .deb (default: <source>/deb)
  LISBON_REV   package revision n in <mesa-version>+lisbon<n> (default: 1)
  LLVM_VERSION LLVM/Clang version for the build dependencies (default: 22)
  LIB          package this libvulkan_panfrost.so instead of the one in \$BUILD
  STRIP        strip program (default: strip)
EOF
}

SRC=$(cd "$(dirname "$0")/.." && pwd)
BUILD=${BUILD:-$SRC/build-panvk}
OUT=${OUT:-$SRC/deb}
LISBON_REV=${LISBON_REV:-1}
LLVM_VERSION=${LLVM_VERSION:-22}
STRIP=${STRIP:-strip}
PKG=panvk-lisbon
MAINTAINER=${MAINTAINER:-masterxq <masterxq@users.noreply.github.com>}

if [ -n "${GITHUB_REPOSITORY:-}" ]; then
	FORK_URL=${GITHUB_SERVER_URL:-https://github.com}/$GITHUB_REPOSITORY
else
	FORK_URL=${FORK_URL:-https://github.com/masterxq/mesa-lisbon}
fi

deps() {
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get install -y --no-install-recommends \
		build-essential ca-certificates cmake dpkg-dev file git \
		meson ninja-build pkgconf \
		python3 python3-mako python3-packaging python3-ply python3-yaml \
		glslang-tools spirv-tools spirv-tools-dev \
		"clang-$LLVM_VERSION" "llvm-$LLVM_VERSION-dev" \
		"libclang-$LLVM_VERSION-dev" "libclang-cpp$LLVM_VERSION-dev" \
		"libclc-$LLVM_VERSION-dev" "libllvmspirvlib-$LLVM_VERSION-dev" \
		libdrm-dev libelf-dev libexpat1-dev libudev-dev libdisplay-info-dev \
		libwayland-dev wayland-protocols libzstd-dev zlib1g-dev
}

build() {
	multiarch=$(dpkg-architecture -qDEB_HOST_MULTIARCH)

	meson setup "$BUILD" "$SRC" \
		--prefix=/usr \
		--libdir="lib/$multiarch/$PKG" \
		--buildtype=release \
		-Doptimization=2 \
		-Db_lto=false \
		-Dgallium-drivers= \
		-Dvulkan-drivers=panfrost \
		-Dplatforms=wayland \
		-Dopengl=false \
		-Dllvm=enabled \
		-Dmesa-clc=enabled \
		-Dprecomp-compiler=enabled
	ninja -C "$BUILD"
}

api_version() {
	sed -n "s/.*'--api-version', '\([0-9.]*\)'.*/\1/p" \
		"$SRC/src/panfrost/vulkan/meson.build" | head -n 1
}

package() {
	lib=${LIB:-$BUILD/src/panfrost/vulkan/libvulkan_panfrost.so}
	version=$(cat "$SRC/VERSION")+lisbon$LISBON_REV
	arch=$(dpkg-architecture -qDEB_HOST_ARCH)
	multiarch=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
	libdir=/usr/lib/$multiarch/$PKG
	icd=/usr/share/vulkan/icd.d/panvk_lisbon_icd.json
	doc=/usr/share/doc/$PKG
	commit=${GITHUB_SHA:-$(git -C "$SRC" rev-parse HEAD 2>/dev/null || echo unknown)}

	[ -f "$lib" ] || { echo "missing $lib" >&2; exit 1; }

	work=$(mktemp -d)
	trap 'rm -rf "$work"' EXIT
	root=$work/root

	install -d "$root$libdir" "$root$(dirname "$icd")" "$root$doc" \
		"$root/DEBIAN"
	install -m 644 "$lib" "$root$libdir/libvulkan_panfrost.so"
	"$STRIP" --strip-unneeded "$root$libdir/libvulkan_panfrost.so"

	python3 "$SRC/src/vulkan/util/vk_icd_gen.py" \
		--api-version "$(api_version)" \
		--xml "$SRC/src/vulkan/registry/vk.xml" \
		--sizeof-pointer 8 \
		--icd-lib-path "$libdir" \
		--icd-filename libvulkan_panfrost.so \
		--out "$work/panvk_lisbon_icd.$arch.json"
	install -m 644 "$work/panvk_lisbon_icd.$arch.json" "$root$icd"

	cat > "$root$doc/copyright" <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: Mesa
Upstream-Contact: https://mesa3d.org/
Source: $FORK_URL
Comment: PanVK (Mesa's panfrost Vulkan driver) built from the Mesa $(cat "$SRC/VERSION")
 release with the lisbon patches.
 Fork: $FORK_URL
 Commit: $commit
 Most of Mesa is licensed under the MIT license; individual source files may
 carry other permissive licenses, see their SPDX identifiers and the licenses/
 directory of the source tree.

Files: *
Copyright: Mesa contributors
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice (including the next
 paragraph) shall be included in all copies or substantial portions of the
 Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
EOF

	mkdir -p "$work/debian"
	printf 'Source: %s\n\nPackage: %s\nArchitecture: any\n' "$PKG" "$PKG" \
		> "$work/debian/control"
	depends=$(cd "$work" && dpkg-shlibdeps -O \
		"root$libdir/libvulkan_panfrost.so" | sed -n 's/^shlibs:Depends=//p')

	cat > "$root/DEBIAN/control" <<EOF
Package: $PKG
Version: $version
Architecture: $arch
Maintainer: $MAINTAINER
Installed-Size: $(du -sk "$root" | cut -f 1)
Depends: $depends
Recommends: libvulkan1
Section: libs
Priority: optional
Homepage: $FORK_URL
Description: PanVK Vulkan driver with lisbon patches for Mali-G76 (Bifrost)
 Mesa's panfrost Vulkan driver (PanVK) from the Mesa $(cat "$SRC/VERSION") release with
 downstream patches for Mali-G76 (Bifrost, job manager) GPUs.
 .
 The driver is installed into its own directory with its own ICD file, so the
 package can be installed next to mesa-vulkan-drivers.
EOF

	(cd "$root" && find usr -type f -exec md5sum {} + | sort -k 2) \
		> "$root/DEBIAN/md5sums"

	mkdir -p "$OUT"
	dpkg-deb --root-owner-group -Zxz --build "$root" \
		"$OUT/${PKG}_${version}_${arch}.deb"
}

case "${1:-}" in
deps) deps ;;
build) build ;;
package) package ;;
all) deps; build; package ;;
*) usage; exit 1 ;;
esac
