package cache_types;

import addrmux::*;
import datamux::*;
import waymux::*;
import benmux::*;

parameter s_offset = 5;
parameter s_index  = 3;
parameter s_tag    = 32 - s_offset - s_index;
parameter s_mask   = 2**s_offset;
parameter s_line   = 8*s_mask;
parameter num_sets = 2**s_index;

typedef logic [s_index-1:0] index_t;
typedef logic [255:0]       cacheline_t;
typedef logic [s_tag-1:0]   tag_t;
typedef logic [31:0]        byte_en_t;

    
endpackage