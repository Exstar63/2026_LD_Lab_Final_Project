module renderer(
    input logic clk,
    input logic rst_n,
    input logic [8:0] show_y,   // show_y (0-239)

    // dist_buffer comm
    input logic [15:0] wall_dist,    // From Distance Buffer

    // dda_raycaster comm
    input logic hit_side,            // From DDA (0=X-wall, 1=Y-wall)
    output logic [11:0] vga_rgb
  );

  (* ram_style = "block" *)
  logic [7:0] height_rom [0:1023];

  initial
  begin
    $readmemh("height_lut.mem", height_rom);
  end

  logic [9:0] lut_index;
  logic [7:0] lut_height, wall_top_next, wall_bottom_next;
  logic [11:0] rgb_next;

  always_comb
  begin
    lut_height = height_rom[wall_dist[11:2]];
    wall_top_next = 8'd120 - (lut_height >> 1);
    wall_bottom_next = 8'd120 + (lut_height >> 1);
    if (show_y < wall_top_next)
      rgb_next = 12'h222; // ceil
    else if (show_y > wall_bottom_next)
      rgb_next = 12'h444; // floor
    else
      rgb_next = (hit_side)? 12'h008 : 12'h00F; // Y/X
  end

  always_ff @(posedge clk)  // sync color output
  begin
    if (~rst_n)
      vga_rgb <= 12'h000;
    else
      vga_rgb <= rgb_next;
  end

endmodule
