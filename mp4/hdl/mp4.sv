import rv32i_types::*;
module mp4(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

    logic       icache_resp;
    rv32i_word  icache_rdata;
    logic       icache_read;
    rv32i_word  icache_address;
    logic       dcache_resp;
    rv32i_word  dcache_rdata;
    logic       dcache_read;
    logic       dcache_write;
    logic [3:0] dcache_byte_enable;
    rv32i_word  dcache_address;
    rv32i_word  dcache_wdata;

    /* the out-of-order cpu */
    cpu ooo_cpu(
        .clk(clk),
        .rst(rst),
        /* port from instruction cache */
        .mem_resp_i(icache_resp),
        .mem_rdata_i(icache_rdata),
        /* port to instruction cache */
        .mem_read_i(icache_read),
        .mem_address_i(icache_address),
        /* port from data cache */
        .mem_resp_d(dcache_resp),
        .mem_rdata_d(dcache_rdata),
        /* port to data cache */
        .mem_read_d(dcache_read),
        .mem_write_d(dcache_write),
        .mem_byte_enable_d(dcache_byte_enable),
        .mem_address_d(dcache_address),
        .mem_wdata_d(dcache_wdata)
    );

    logic           icache_pmem_resp;
    logic           icache_pmem_read;
    logic [255:0]   icache_pmem_rdata;
    rv32i_word      icache_pmem_address;
    logic           dcache_pmem_resp;
    logic           dcache_pmem_read;
    logic           dcache_pmem_write;
    logic [255:0]   dcache_pmem_wdata;
    logic [255:0]   dcache_pmem_rdata;
    rv32i_word      dcache_pmem_address;

    /* instruction cache */
    given_cache #(5,5) icache(
        .clk,
        .rst,
        /* port between physical memory (arbiter) */
        .pmem_resp(icache_pmem_resp),
        .pmem_rdata(icache_pmem_rdata),
        .pmem_address(icache_pmem_address),
        .pmem_wdata(),
        .pmem_read(icache_pmem_read),
        .pmem_write(),
        /* port between CPU */
        .mem_read(icache_read),
        .mem_write(1'b0),
        .mem_byte_enable_cpu(4'b0000),
        .mem_address(icache_address),
        .mem_wdata_cpu(32'b0),
        .mem_resp(icache_resp),
        .mem_rdata_cpu(icache_rdata)
    );

    /* data cache */
    cache dcache(
        .clk,
        .rst,
        /* port from CPU */
        .mem_address(dcache_address),
        .mem_wdata(dcache_wdata),
        .mem_read(dcache_read),
        .mem_write(dcache_write),
        .mem_byte_enable(dcache_byte_enable),
        /* port to CPU */
        .mem_rdata(dcache_rdata),
        .mem_resp(dcache_resp),
        /* port from physical memory (arbiter) */
        .pmem_rdata(dcache_pmem_rdata),
        .pmem_resp(dcache_pmem_resp),
        /* port to physical memory (arbiter) */
        .pmem_wdata(dcache_pmem_wdata),
        .pmem_address(dcache_pmem_address),
        .pmem_read(dcache_pmem_read),
        .pmem_write(dcache_pmem_write)
    );

    logic           arbiter_resp;
    logic           arbiter_read;
    logic           arbiter_write;
    logic [255:0]   arbiter_wdata;
    logic [255:0]   arbiter_rdata;
    rv32i_word      arbiter_address;

    arbiter arbiter_inst(
        .clk,
        .rst,
        /* port between instruction cache */
        .icache_address(icache_pmem_address),
        .icache_read(icache_pmem_read),
        .icache_resp(icache_pmem_resp),
        .icache_rdata(icache_pmem_rdata),
        /* port between data cache */
        .dcache_address(dcache_pmem_address),
        .dcache_read(dcache_pmem_read),
        .dcache_write(dcache_pmem_write),
        .dcache_wdata(dcache_pmem_wdata),
        .dcache_resp(dcache_pmem_resp),
        .dcache_rdata(dcache_pmem_rdata),
        /* port between cacheline adaptor */
        .pmem_resp(arbiter_resp),
        .pmem_rdata(arbiter_rdata),
        .pmem_address(arbiter_address),
        .pmem_read(arbiter_read),
        .pmem_write(arbiter_write),
        .pmem_wdata(arbiter_wdata)
    );

    cacheline_adaptor cacheline_adaptor_inst(
        .clk,
        .reset_n(~rst),
        /* port between cache */
        .line_i(arbiter_wdata),
        .line_o(arbiter_rdata),
        .address_i(arbiter_address),
        .read_i(arbiter_read),
        .write_i(arbiter_write),
        .resp_o(arbiter_resp),
        /* port between physical memory */
        .burst_i(pmem_rdata),
        .burst_o(pmem_wdata),
        .address_o(pmem_address),
        .read_o(pmem_read),
        .write_o(pmem_write),
        .resp_i(pmem_resp)
    );

endmodule : mp4
