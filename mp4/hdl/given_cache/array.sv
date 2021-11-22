
module given_array #(
  parameter width = 1,
  parameter index = 3
)
(
  input clk,
  input rst,
  input logic load,
  input logic [index-1:0] rindex,
  input logic [index-1:0] windex,
  input logic [width-1:0] datain,
  output logic [width-1:0] dataout
);

localparam num_sets = 2**index;

//logic [width-1:0] data [2:0] = '{default: '0};
logic [width-1:0] data [num_sets];

always_comb begin
  dataout = (load  & (rindex == windex)) ? datain : data[rindex];
end

always_ff @(posedge clk)
begin
    if(rst)begin
      for (int i = 0; i < num_sets; ++i) begin
        data[i] <= 0;
      end
    end else begin
      if(load)
        data[windex] <= datain;
    end
end

endmodule : given_array
