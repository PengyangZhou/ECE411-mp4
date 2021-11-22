/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache
(
    input logic clk,
    input logic rst,
    /* cpu to cache */
    input logic [31:0] mem_address,
    input logic [31:0] mem_wdata,
    input logic mem_read,
    input logic mem_write,
    input logic [3:0] mem_byte_enable,
    /* cacheline adaptor to cache */
    input logic [255:0] pmem_rdata,
    input logic pmem_resp,
    /* cache to cpu */
    output logic [31:0] mem_rdata,
    output logic mem_resp,
    /* cache to cacheline adaptor */
    output logic [255:0] pmem_wdata,
    output logic [31:0] pmem_address,
    output logic pmem_read,
    output logic pmem_write
);

    /* signals between control and cacheline adaptor */
    logic ca_resp;
    logic ca_read;
    logic ca_write;
    assign ca_resp = pmem_resp;
    assign pmem_read = ca_read;
    assign pmem_write = ca_write;
    /* signals between control and cpu */
    logic cpu_read;
    logic cpu_write;
    logic cpu_resp;
    assign cpu_read = mem_read;
    assign cpu_write = mem_write;
    assign mem_resp = cpu_resp;
    /* signals between datapath and bus adaptor (and directly from outside) */
    cacheline_t cpu_wdata;
    byte_en_t cpu_byte_enable;
    logic [31:0] cpu_address;
    // logic cpu_write;
    cacheline_t cpu_rdata;
    assign cpu_address = mem_address;
    /* signals between datapath and cacheline adaptor */
    cacheline_t ca_rdata;
    cacheline_t ca_wdata;
    logic [31:0] ca_address;
    assign ca_rdata = pmem_rdata;
    assign pmem_wdata = ca_wdata;
    assign pmem_address = ca_address;
    /* mux selection */
    addrmux::addrmux_sel_t addrmux_sel;
    datamux::datamux_sel_t datamux_sel;
    benmux::benmux_sel_t benmux_sel;
    waymux::waymux_sel_t waymux_sel;
    /* write signals */
    logic data_write;
    logic dirty_write;
    logic lru_write;
    logic tag_write;
    logic valid_write;
    /* signals from datapath to control */
    logic hit;
    logic dirty;

cache_control control
(.*);

cache_datapath datapath
(.*);

bus_adapter bus_adapter
(
    .mem_wdata256(cpu_wdata),
    .mem_rdata256(cpu_rdata),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(cpu_byte_enable),
    .address(mem_address)
);

endmodule : cache
