/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */
import cache_types::*; 

module cache_datapath (
    input logic clk,
    input logic rst,
    /* signals to control */
    output logic hit,
    output logic dirty,
    /* signals from control */
    input addrmux::addrmux_sel_t addrmux_sel,
    input datamux::datamux_sel_t datamux_sel,
    input benmux::benmux_sel_t benmux_sel,
    input waymux::waymux_sel_t waymux_sel,
    input logic data_write,
    input logic dirty_write,
    input logic lru_write,
    input logic tag_write,
    input logic valid_write,
    /* singals between bus adaptor */
    input cacheline_t cpu_wdata,
    input byte_en_t cpu_byte_enable,
    input logic [31:0] cpu_address,
    input logic cpu_write,
    output cacheline_t cpu_rdata,
    /* signals between cacheline adaptor */
    input cacheline_t ca_rdata,
    output cacheline_t ca_wdata,
    output logic [31:0] ca_address
);

/* translation of cpu_address */
cache_types::tag_t   tag_in;
assign tag_in = cache_types::tag_t'(cpu_address[31-:cache_types::s_tag]);
index_t index_in;
assign index_in = index_t'(cpu_address[5+:cache_types::s_index]);

/* intermediate variables */
logic [31:0]    addrmux_out;
assign ca_address = addrmux_out;
cacheline_t     datamux_out;
logic           waymux_out;
byte_en_t       benmux_out;
logic           hit_wayid;
logic           lru_wayid;
cacheline_t     data_out;
assign ca_wdata = data_out;
assign cpu_rdata = data_out;
cache_types::tag_t tag_out [2];
cache_types::tag_t tag_evict;
logic [1:0]     valid_out;

data_storage_array data_storage_array_inst(
    .clk,
    .rst,
    .write(data_write),
    .wayid(waymux_out),
    .index(index_in),
    .byte_enable(benmux_out),
    .data_in(datamux_out),
    .data_out(data_out)
);

tag_array tag_array_inst(
    .clk,
    .rst,
    .write(tag_write),
    .wayid(lru_wayid),  /* used for write and evict */
    .index(index_in),
    .tag_in(tag_in),
    .tag_out(tag_out),
    .tag_evict(tag_evict)
);

valid_array valid_array_inst(
    .clk,
    .rst,
    .write(valid_write),
    .wayid(lru_wayid),  /* only for writing */
    .index(index_in),
    .valid_out(valid_out)
);

lru_array lru_array_inst(
    .clk,
    .rst,
    .write(lru_write),
    .index(index_in),
    .lru_in(~waymux_out),
    .lru_out(lru_wayid)
);

dirty_array dirty_array_inst(
    .clk,
    .rst,
    .write(dirty_write),
    .wayid(waymux_out),
    .index(index_in),
    .dirty_in(cpu_write),
    .dirty_out(dirty)
);

hit_check hit_check_inst(
    .valid_in(valid_out),
    .tag_in(tag_in),
    .tag_array_in(tag_out),
    .hit(hit),
    .hit_wayid(hit_wayid)
);

always_comb begin : MUXES   
    unique case (addrmux_sel)
        addrmux::addr_from_array:   addrmux_out = {tag_evict, index_in, 5'b0};
        addrmux::addr_from_cpu:     addrmux_out = {cpu_address[31:5], 5'b0};
        default: ;
    endcase

    unique case (datamux_sel)
        datamux::data_from_memory:  datamux_out = ca_rdata;
        datamux::data_from_cpu:     datamux_out = cpu_wdata;
        default: ;
    endcase

    unique case (waymux_sel)
        waymux::hit_id: waymux_out = hit_wayid;
        waymux::lru_id: waymux_out = lru_wayid;
        default: ;
    endcase

    unique case (benmux_sel)
        benmux::all_enable:     benmux_out = {32{1'b1}};
        benmux::spec_by_cpu:    benmux_out = cpu_byte_enable;
        default: ;
    endcase
end

endmodule : cache_datapath
