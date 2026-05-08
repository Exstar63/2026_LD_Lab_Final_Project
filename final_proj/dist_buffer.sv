module dist_buffer(
    input  logic        clk,

    // dda_scanner comm
    input  logic        write_enable,
    input  logic [8:0]  write_addr,  // 0 to 319
    input  logic [22:0] write_data,  // final_distance from DDA

    // render comm
    input  logic [8:0]  read_addr,   // internal_x from VGA
    output logic [22:0] read_data    // Output to the Renderer
  );

  (* ram_style = "block" *)
  logic [22:0] ram [0:319]; // 320 * 16'b

  always_ff @(posedge clk)
  begin
    if (write_enable)
      ram[write_addr] <= write_data;
  end
  
  always_ff @(posedge clk)
  begin
    read_data <= ram[read_addr];
  end

endmodule
