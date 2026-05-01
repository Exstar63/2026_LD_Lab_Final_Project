module dist_buffer (
    input  logic        clk,

    // Write Port (dda scanner)
    input  logic        we,          // Write Enable
    input  logic [8:0]  write_addr,  // 0 to 319
    input  logic [15:0] write_data,  // final_distance from DDA

    // Read Port (render)
    input  logic [8:0]  read_addr,   // internal_x from VGA
    output logic [15:0] read_data    // Output to the Renderer
  );

  // 320 memory slots, each 16 bits wide
  (* ram_style = "block" *)
  logic [15:0] ram [0:319];

  // Write operation
  always_ff @(posedge clk)
  begin
    if (we)
    begin
      ram[write_addr] <= write_data;
    end
  end

  // Read operation
  always_ff @(posedge clk)
  begin
    read_data <= ram[read_addr];
  end

endmodule
