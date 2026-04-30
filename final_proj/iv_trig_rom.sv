module iv_trig_rom (
    input  logic clk,
    input  logic [7:0] angle,
    output logic [15:0] abs_sec_out, // deltaDistX
    output logic [15:0] abs_csc_out  // deltaDistY
  );

  // 16-bit words * 256 index LUT for csc/sec
  logic [15:0] csc_rom [0:255];

  // Load mem
  initial
  begin
    $readmemh("csc_lut.mem", csc_rom);
  end

  // Sync read (BRAM)
  always_ff @(posedge clk)
  begin
    abs_csc_out <= csc_rom[angle];
    abs_sec_out <= csc_rom[angle + 8'd64];
  end

endmodule
