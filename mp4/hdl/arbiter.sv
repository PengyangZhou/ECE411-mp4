module arbiter (
    input logic clk,
    input logic rst,
    /* port between instruction cache */
    input rv32i_word    icache_address,
    input logic         icache_read,
    output logic        icache_resp,
    output logic[255:0] icache_rdata,
    /* port between data cache */
    input rv32i_word    dcache_address,
    input logic         dcache_read,
    input logic         dcache_write,
    input logic [255:0] dcache_wdata,
    output logic        dcache_resp,
    output logic[255:0] dcache_rdata,
    /* port between physical memory */
    input logic         pmem_resp,
    input logic [255:0] pmem_rdata,
    output rv32i_word   pmem_address,
    output logic        pmem_read,
    output logic        pmem_write,
    output logic[255:0] pmem_wdata
);

enum bit { ICACHE, DCACHE } state;

/* we introduced a state machine because the arbiter has to remember
   the stage of a memory operation  */
always_ff @( posedge clk ) begin : state_machine
    if(rst)begin
        state <= ICACHE;
    end else begin
        case (state)
            ICACHE: begin
                if(~icache_read & (dcache_read | dcache_write))begin
                    state <= DCACHE;
                end
            end

            DCACHE: begin
                if(~(dcache_read | dcache_write) & icache_read)begin
                    state <= ICACHE;
                end
            end
            default: ;
        endcase
    end
end

always_comb begin : wiring
    icache_resp = 1'b0;
    icache_rdata = 256'b0;
    dcache_resp = 1'b0;
    dcache_rdata = 256'b0;
    case (state)
        ICACHE: begin
            icache_resp = pmem_resp;
            icache_rdata = pmem_rdata;
            pmem_address = icache_address;
            pmem_read = icache_read;
            pmem_write = 1'b0;
            pmem_wdata = 256'b0;
        end

        DCACHE: begin
            dcache_resp = pmem_resp;
            dcache_rdata = pmem_rdata;
            pmem_address = dcache_address;
            pmem_read = dcache_read;
            pmem_write = dcache_write;
            pmem_wdata = dcache_wdata;
        end

        default: ;
    endcase
end
    
endmodule