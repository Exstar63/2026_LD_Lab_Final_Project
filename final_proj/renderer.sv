module renderer(
    input logic clk,
    input logic rst_n,
    input logic [8:0] show_y,   // internal_y (0-239)

    // dist_buffer comm
    input logic [15:0] wall_dist,    // From Distance Buffer
    
    // dda_raycaster comm
    input logic hit_side,            // From DDA (0=X-wall, 1=Y-wall)
    output logic [11:0] vga_rgb
  );

  logic [7:0] height_rom [0:255];

  initial
  begin
    $readmemh("height_lut.mem", height_rom);
  end

  logic [7:0] lut_height, lut_index;
  logic [7:0] next_wall_top, next_wall_bottom;
  logic [11:0] next_rgb;

  always_comb
  begin
    lut_index = (wall_dist[15:12] != 4'd0)? 8'hFF : wall_dist[11:4];
    lut_height = height_rom[lut_index];
    next_wall_top = 8'd120 - (lut_height >> 1);
    next_wall_bottom = 8'd120 + (lut_height >> 1);
    if (show_y < next_wall_top)
      next_rgb = 12'h222; // ceil
    else if (show_y > next_wall_bottom)
      next_rgb = 12'h444; // floor
    else
      if (hit_side)
        next_rgb = 12'h008; // wall Y
      else
        next_rgb = 12'h00F; // wall X
  end

  always_ff @(posedge clk)  // sync color output
  begin
    if (~rst_n)
      vga_rgb <= 12'h000;
    else
      vga_rgb <= next_rgb;
  end

endmodule
