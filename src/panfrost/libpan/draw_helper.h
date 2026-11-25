/*
 * Copyright 2025 Collabora Ltd.
 * SPDX-License-Identifier: MIT
 */

#include <stdatomic.h>
#include <stdint.h>
#include "compiler/libcl/libcl.h"
#include "genxml/gen_macros.h"

#pragma once

#if (PAN_ARCH == 6 || PAN_ARCH == 7)
/* Keep in sync with panvk_varying_buf_id */
enum panlib_varying_buf_id {
   PANLIB_VARY_BUF_GENERAL,
   PANLIB_VARY_BUF_POSITION,
   PANLIB_VARY_BUF_PSIZ,

   /* Keep last */
   PANLIB_VARY_BUF_MAX,
};

struct libpan_draw_helper_index_min_max_result {
    uint32_t min;
    uint32_t max;
};

struct libpan_draw_helper_attrib_buf_info {
    uint32_t divisor;
    uint32_t stride;
    bool per_instance;
};

struct libpan_draw_helper_attrib_info {
    uint32_t base_offset;

    /* When the attribute is per instance, the stride otherwise 0 */
    uint32_t stride;
};

struct libpan_draw_helper_entry {
    uint64_t cmd;
    uint64_t index_buffer_ptr;
    uint64_t index_min_max_res;
    uint64_t varying_bufs_descs;
    uint64_t attrib_bufs_descs;
    uint64_t attrib_bufs_infos;
    uint64_t attribs_descs;
    uint64_t attribs_infos;
    uint64_t first_vertex_sysval;
    uint64_t first_instance_sysval;
    uint64_t raw_vertex_offset_sysval;
    uint64_t idvs_job;
    uint64_t vertex_job;
    uint64_t tiler_job;
    uint32_t index_size;
    uint32_t primitive_restart;
    uint32_t primitive_vertex_count;
    uint32_t attrib_bufs_valid;
    uint32_t attribs_valid;
    uint32_t pad;
};
#endif
