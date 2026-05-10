module entity_tex_rom(
    input logic clk,
    input logic [11:0] addr,
    output logic [11:0] color_out
  );

  (* ram_style = "block" *)
  logic [11:0] rom [0:4095];

  initial
  begin
    $readmemh("entity_01_tex.mem", rom);
  end

  always_ff @(posedge clk)
  begin
    color_out <= rom[addr];
  end

endmodule
