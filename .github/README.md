# Mesa with lisbon patches for PanVK

This branch is a Mesa release with downstream patches for PanVK, Mesa's
Vulkan driver for Arm Mali GPUs, on the Mali-G76 (Bifrost v7, job manager)
of the Motorola Moto G60s. Each patch is a separate commit on top of the
release tag.

This is a downstream branch. Please do not report problems with it to the
Mesa project.

## Changes

| Area | Change | Why |
|---|---|---|
| Device detection | The Mali-G76 of the MT6785 is exposed without `PAN_I_WANT_A_BROKEN_VULKAN_DRIVER`. | Compatibility |
| Devices and queues | Every `VkDevice` opens its own DRM file and so gets its own GPU address space. Queue global priorities are mapped to kernel job contexts. | Bug fix, compatibility |
| Textures (shader compiler) | `textureQueryLod` returns the fractional LOD for trilinear samplers. Texel offsets are correct with `MIRRORED_REPEAT`. | Bug fix |
| Storage images | Accesses to cube storage images are checked against the image bounds. | Bug fix |
| Rasterization | Rectangular lines are shifted by 1/256 pixel, because lines that lie exactly on pixel centers could vanish. | Bug fix |
| Draws | Empty index ranges, draws without vertex buffers, input attachment map changes and the polygon heap across several batches work. A failed job submission is reported as device loss instead of being ignored. | Bug fix |
| Draws | Helper jobs for indexed and indirect draws run collected in a separate job chain before the draws. Occlusion queries no longer split the render pass. Large varying buffers are reused. | Performance |
| OpenGL (panfrost Gallium) | Exported buffers are not returned to the buffer cache while still in use. The MediaTek video format 16L32S is detiled correctly. Also on branch `lisbon/26.1`; not part of the package below. | Bug fix |

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

Note: created with AI assistance.
