package addrmux;
    typedef enum bit {
        addr_from_cpu = 1'b1,
        addr_from_array = 1'b0
    } addrmux_sel_t;
endpackage

package datamux;
    typedef enum bit { 
        data_from_memory = 1'b0,
        data_from_cpu = 1'b1 
    } datamux_sel_t;
endpackage

package waymux;
    typedef enum bit { 
        hit_id = 1'b0,
        lru_id = 1'b1
    } waymux_sel_t;
endpackage

package benmux;
    typedef enum bit { 
        all_enable = 1'b0,
        spec_by_cpu = 1'b1
    } benmux_sel_t;
endpackage


