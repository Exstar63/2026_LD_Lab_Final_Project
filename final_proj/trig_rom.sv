module trig_rom (
    input  logic clk,
    input  logic [7:0] angle,
    output logic signed [15:0] sin_out,
    output logic signed [15:0] cos_out
  );

  // 16-bit words * 256 index LUT for sin/cos
  (* ram_style = "block" *)
  logic signed [15:0] rom [0:255];

  // Load mem
  initial
  begin
    $readmemh("sine_lut.mem", rom);
  end

  // Sync read (BRAM)
  always_ff @(posedge clk)
  begin
    sin_out <= rom[angle];
    cos_out <= rom[angle + 8'd64];
  end

endmodule
