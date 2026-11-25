# Mesa with lisbon patches for PanVK

This branch is a Mesa release with downstream patches for PanVK, Mesa's
Vulkan driver for Arm Mali GPUs, on the Mali-G76 (Bifrost v7, job manager)
of the Motorola Moto G60s. Each patch is a separate commit on top of the
release tag. The first two commits are OpenGL (panfrost Gallium) fixes,
which are also on branch `lisbon/26.1`; they are not part of the package
below.

The patches were generated with an LLM (marked with `Generated-by: LLM` in
each commit). They are not intended for submission to Mesa upstream; please
do not report problems with this branch to the Mesa project.

## Package

`.github/workflows/panvk-deb.yml` builds the Debian package `panvk-lisbon`
(arm64) in a `debian:forky` container and uploads it as a workflow artifact.
To build it yourself on Debian arm64:

    sudo sh .lisbon/build-panvk-deb.sh deps
    sh .lisbon/build-panvk-deb.sh build
    sh .lisbon/build-panvk-deb.sh package

The package contains only the PanVK driver:

- `/usr/lib/aarch64-linux-gnu/panvk-lisbon/libvulkan_panfrost.so`
- `/usr/share/vulkan/icd.d/panvk_lisbon_icd.json`

It can be installed next to Debian's `mesa-vulkan-drivers`:

    sudo apt install ./panvk-lisbon_*_arm64.deb

To select one driver explicitly, set
`VK_DRIVER_FILES=/usr/share/vulkan/icd.d/panvk_lisbon_icd.json`.

## Testing status

- `lisbon/26.3` (Mesa 26.3.1): subsets of the Vulkan CTS pass on the
  Moto G60s; a full mustpass run is still pending.
