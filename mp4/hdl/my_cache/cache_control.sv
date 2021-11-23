/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input   logic clk,
    input   logic rst,
    /* signals between cacheline adaptor */
    input   logic ca_resp,
    output  logic ca_read,
    output  logic ca_write,
    /* signals between bus adaptor */
    input   logic cpu_read,
    input   logic cpu_write,
    output  logic cpu_resp,
    /* mux selection */
    output  addrmux::addrmux_sel_t addrmux_sel,
    output  datamux::datamux_sel_t datamux_sel,
    output  benmux::benmux_sel_t benmux_sel,
    output  waymux::waymux_sel_t waymux_sel,
    /* write signals */
    output  logic data_write,
    output  logic dirty_write,
    output  logic lru_write,
    output  logic tag_write,
    output  logic valid_write,
    /* signals from datapath */
    input   logic hit,
    input   logic dirty
);

enum int unsigned { 
    S_IDLE,
    S_HIT_CHECK,
    S_WRITE_BACK,
    S_READ_MEM,
    S_UPDATE_ATTR
} state, next_state;

/* set default values of control signals */
function void set_defaults();
    ca_read = 1'b0;
    ca_write = 1'b0;
    cpu_resp = 1'b0;
    addrmux_sel = addrmux::addr_from_cpu;
    datamux_sel = datamux::data_from_memory;
    waymux_sel = waymux::hit_id;
    benmux_sel = benmux::all_enable;
    data_write = 1'b0;
    dirty_write = 1'b0;
    lru_write = 1'b0;
    tag_write = 1'b0;
    valid_write = 1'b0;
endfunction

/* control signals */
always_comb begin : state_outputs
    set_defaults();

    case (state)
        S_IDLE:;

        S_HIT_CHECK: begin
            if (hit) begin
                if(cpu_write)begin
                    datamux_sel = datamux::data_from_cpu;
                    benmux_sel = benmux::spec_by_cpu;
                    data_write = 1'b1;
                end
                cpu_resp = 1'b1;
                waymux_sel = waymux::hit_id;
                lru_write = 1'b1;
            end else begin
                cpu_resp = 1'b0;
                waymux_sel = waymux::lru_id;
            end
            if (cpu_write) dirty_write = 1'b1; /* if it's a write, update dirty array */
        end

        S_WRITE_BACK: begin
            ca_write = 1'b1;
            addrmux_sel = addrmux::addr_from_array;
            waymux_sel = waymux::lru_id;
        end

        S_READ_MEM: begin
            ca_read = 1'b1;
            data_write = 1'b1;
            addrmux_sel = addrmux::addr_from_cpu;
            benmux_sel = benmux::all_enable;
            datamux_sel = datamux::data_from_memory;
            waymux_sel = waymux::lru_id;
            if (cpu_read) dirty_write = 1'b1;  /* only in this case do we reset dirty bit */
        end

        S_UPDATE_ATTR: begin
            tag_write = 1'b1;
            valid_write = 1'b1;
            lru_write = 1'b1;
            cpu_resp = 1'b1;
            waymux_sel = waymux::lru_id; /* buglog: in this state waymux_sel cannot be default */
            if (cpu_write) begin
                data_write = 1'b1;
                // dirty_write = 1'b1; /* buglog: duplicated dirty_write */
                waymux_sel = waymux::lru_id;
                datamux_sel = datamux::data_from_cpu;
                benmux_sel = benmux::spec_by_cpu;
            end
        end
        default: set_defaults();
    endcase
end

always_comb begin : state_transition
    /* default transition */
    next_state = state;

    unique case (state)
        S_IDLE: begin
            if (cpu_read | cpu_write) begin
                next_state = S_HIT_CHECK;
            end
        end

        S_HIT_CHECK: begin
            if (hit) begin
                next_state = S_IDLE;
            end else begin
                if (dirty) begin
                    next_state = S_WRITE_BACK;
                end else begin
                    next_state = S_READ_MEM;
                end
            end
        end

        S_WRITE_BACK: begin
            if (ca_resp) begin
                next_state = S_READ_MEM;
            end
        end

        S_READ_MEM: begin
            if (ca_resp) begin
                next_state = S_UPDATE_ATTR;
            end
        end

        S_UPDATE_ATTR: begin
            next_state = S_IDLE;
        end

        default: next_state = S_IDLE;
    endcase
end

always_ff @( posedge clk ) begin : state_assignment
    if (rst) begin
        state <= S_IDLE;
    end else begin
        state <= next_state;
    end
end

endmodule : cache_control
