module wall_renderer(
    input logic clk,
    input logic rst_n,
    input logic [8:0] show_y,

    // dist_buffer comm
    input logic [15:0] wall_dist,
    input logic [5:0] tex_x,
    input logic hit_side,
    output logic [11:0] vga_rgb
  );

  (* ram_style = "block" *)
  logic [7:0] height_rom [0:1023];

  initial
  begin
    $readmemh("height_lut.mem", height_rom);
  end

  localparam logic [15:0] TEX_SCALE = 16'd68; // 68 perfect for 64*64 -> 240 h

  logic [9:0] lut_index;
  logic [7:0] lut_height, wall_top, wall_bottom;
  logic [11:0] rgb_next, tex_rgb;
  logic ceil, floor, wall, lower_half;
  logic [7:0] dy;
  logic [31:0] tex_dy;
  logic [5:0] tex_y;
  logic [15:0] tex_y_step;
  logic [31:0] tex_y_step_temp;

  always_comb
  begin
    lut_height = height_rom[wall_dist[11:2]];
    wall_top = 8'd120 - (lut_height >> 1);
    wall_bottom = 8'd120 + (lut_height >> 1);

    ceil = (show_y < wall_top);
    floor = (show_y > wall_bottom);
    wall = ~(ceil|floor);
    lower_half = (show_y >= 9'd120);

    dy = (lower_half)? (show_y - 9'd120):(9'd120 - show_y);
    tex_y_step_temp = wall_dist * TEX_SCALE;
    tex_y_step = tex_y_step_temp[23:8];
    tex_dy = dy * tex_y_step;

    if (lower_half)
      tex_y = (tex_dy[13:8] > 6'd31)? (6'd63) : (6'd32 + tex_dy[13:8]);
    else
      tex_y = (tex_dy[13:8] > 6'd31)? (6'd0) : (6'd31 - tex_dy[13:8]);

    if (ceil)
      rgb_next = 12'h222; // ceil
    else if (floor)
      rgb_next = 12'h444; // floor
    else if (hit_side)
      rgb_next = {1'b0, tex_rgb[11:9], 1'b0, tex_rgb[7:5], 1'b0, tex_rgb[3:1]}; // crappy shading
    else
      rgb_next = tex_rgb;

  end

  wall_tex_rom wall_tex_mem(
    .clk(clk),
    .addr({tex_y,tex_x}),
    .color_out(tex_rgb)
  );

  always_ff @(posedge clk)  // sync color output
  begin
    if (~rst_n)
      vga_rgb <= 12'h000;
    else
      vga_rgb <= rgb_next;
  end

endmodule
