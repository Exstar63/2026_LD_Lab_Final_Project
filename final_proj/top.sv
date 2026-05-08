module top(
    input logic clk,
    input logic rst_n,
    input logic btnU,btnD,btnL,btnR,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue,
    output logic hsync,
    output logic vsync
  );

  // vga control flags
  logic clk_25MHz;
  logic [11:0] pixel;
  logic valid;
  logic v_blank;

  assign {vgaRed, vgaGreen, vgaBlue} = (valid==1'b1) ? pixel : 12'h0;

  // pixel hit control
  logic [9:0] h_cnt, v_cnt;
  logic [8:0] show_x, show_y;
  logic [8:0] which_x, rendering_x;

  always_comb // rescale for render @ 320*240
  begin
    show_x = h_cnt>>1;
    show_y = v_cnt>>1;
    which_x = (v_blank) ? rendering_x : show_x ;
  end

  // ray/player location map_hit chk/probe
  logic [15:0] player_x, player_y;
  logic [7:0] rendering_angle;
  logic [15:0] rayDirX, rayDirY;
  logic [3:0] hit_chk_x, hit_chk_y;
  logic [3:0] probe_x, probe_y;
  logic [15:0] corr_coef; 

  // comm flag
  logic map_hit, start_ray, ray_done, write_enable;

  // buffer packet
  logic [16:0] buff_in_packet, buff_out_packet;
  logic [15:0] finalDist, renderDist;
  logic [5:0] tex_x, tex_x_buff;
  logic hit_side, hit_side_buff;
  assign buff_in_packet = {hit_side, tex_x, finalDist};
  assign buff_out_packet = {hit_side_buff, tex_x_buff, renderDist};

  clock_divisor clk_wiz_0_inst(
                  .clk(clk),
                  .clk1(clk_25MHz),
                  .clk22()
                );

  camera cam_inst(
           .player_x_out(player_x),         // raycaster
           .player_y_out(player_y),
           .ray_angle_out(rendering_angle),
           .rayDirX_out(rayDirX),
           .rayDirY_out(rayDirY),
           .corr_coef(corr_coef),
           .rendering_x(which_x),           // scanner in
           .probe_x(probe_x),               // map_hit probe
           .probe_y(probe_y),
           .map_hit(map_hit),
           .btn_up(btnU),                   // camera controls
           .btn_down(btnD),
           .btn_left(btnL),
           .btn_right(btnR),
           .v_blank(v_blank),
           .clk(clk),
           .rst_n(rst_n)
         );

  map_rom map_inst(
            .map_x((v_blank)? hit_chk_x : probe_x),
            .map_y((v_blank)? hit_chk_y : probe_y),
            .map_hit(map_hit),
            .clk(clk)
          );

  dda_raycaster dda_raycaseter_inst(
                  .player_x(player_x),  // camera
                  .player_y(player_y),
                  .ray_angle(rendering_angle),
                  .rayDirX(rayDirX),
                  .rayDirY(rayDirY),
                  .corr_coef(corr_coef),
                  .map_x_out(hit_chk_x), // map
                  .map_y_out(hit_chk_y),
                  .map_hit(map_hit),
                  .start_ray(start_ray), // scanner
                  .ray_done(ray_done),
                  .finalDist(finalDist), // buffer
                  .tex_x_out(tex_x),
                  .hit_side(hit_side),
                  .clk(clk),
                  .rst_n(rst_n)
                );

  dist_buffer dist_buffer_mem(
                .write_enable(write_enable),    // scanner in
                .write_addr(rendering_x),
                .write_data(buff_in_packet),  // dda_raycaster in
                .read_addr(show_x),             // vga_ctrl in
                .read_data(buff_out_packet),  // renderer out
                .clk(clk)
              );

  dda_scanner dda_scanner_inst(
                .rendering_x(rendering_x),   // -> camera/buffer -> raycaster
                .ray_done(ray_done),
                .start_ray(start_ray),
                .write_enable(write_enable),  // buffer
                .v_blank(v_blank),
                .clk(clk),
                .rst_n(rst_n)
              );

  renderer render_inst(
             .vga_rgb(pixel),
             .show_y(show_y),
             .wall_dist(renderDist),
             .tex_x(tex_x_buff),
             .hit_side(hit_side_buff),
             .clk(clk),
             .rst_n(rst_n)
           );

  // Render the picture by VGA controller
  vga_controller vga_inst(
                   .pclk(clk_25MHz),
                   .reset(~rst_n),
                   .hsync(hsync),
                   .vsync(vsync),
                   .valid(valid),
                   .v_blank(v_blank),
                   .h_cnt(h_cnt),
                   .v_cnt(v_cnt)
                 );

endmodule
