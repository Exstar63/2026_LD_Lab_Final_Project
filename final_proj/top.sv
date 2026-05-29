module top(
    input logic clk,
    input logic rst_n,
    input logic btnU, btnD, btnL, btnR,
    inout logic PS2_DATA,
    inout logic PS2_CLK,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue,
    output logic hsync,
    output logic vsync
  );

  // vga control flags
  logic clk_25MHz;
  logic [11:0] pixel, wall_pixel, entity_pixel;
  logic draw_sprite_en;
  logic valid;
  logic v_blank;

  // frame tick
  logic frame_tick, v_blank_prev;
  always_ff @(posedge clk)
    v_blank_prev <= v_blank;
  assign frame_tick = (v_blank && !v_blank_prev);

  // pixel hit control
  logic [9:0] h_cnt, v_cnt;
  logic [8:0] show_x, show_y;
  logic [8:0] which_x, rendering_x;

  always_comb // rescale for render @ 320*240
  begin
    show_x = h_cnt>>1;
    show_y = v_cnt>>1;
    which_x = (v_blank) ? rendering_x : show_x ;
    {vgaRed, vgaGreen, vgaBlue} = (valid==1'b1) ? pixel : 12'h0;
    pixel = (draw_sprite_en) ? entity_pixel : wall_pixel;
  end

  // ray/player location map_hit chk/probe
  logic [15:0] player_x, player_y;
  logic [15:0] cos_p, sin_p;
  logic [7:0] rendering_angle;
  logic [15:0] rayDirX, rayDirY;
  logic [3:0] hit_chk_x, hit_chk_y;
  logic [3:0] probe_x, probe_y;
  logic [15:0] corr_coef;

  // keyboard control
  logic kbd_btn_W, kbd_btn_A, kbd_btn_S, kbd_btn_D, kbd_btn_SP;
  logic kbd_btn_La, kbd_btn_Ra, kbd_btn_Ua, kbd_btn_Da;

  // comm flag
  logic map_hit, start_ray, ray_done, write_enable;

  // buffer packet
  logic [22:0] buff_in_packet, buff_out_packet;
  logic [15:0] finalDist, renderDist;
  logic [5:0] tex_x, tex_x_buff;
  logic hit_side, hit_side_buff;
  assign buff_in_packet = {hit_side, tex_x, finalDist};
  assign buff_out_packet = {hit_side_buff, tex_x_buff, renderDist};

  // entity pipeline
  logic signed [15:0] proj_screen_x, proj_screen_y;
  logic [15:0] proj_dist, proj_step;
  logic proj_show, proj_calc_done;
  logic signed [15:0] target_x, target_y, target_z;
  logic [15:0] target_scale;
  logic target_enable;
  oam_entry_t oam_data [0:7];
  logic [11:0] tex_addr;
  logic [11:0] tex_rgb;

  clock_divisor clk_wiz_0_inst(
                  .clk(clk),
                  .clk1(clk_25MHz),
                  .clk22()
                );

  camera cam_inst(
           .player_x_out(player_x),         // raycaster
           .player_y_out(player_y),
           .cos_p(cos_p),
           .sin_p(sin_p),
           .ray_angle_out(rendering_angle),
           .rayDirX_out(rayDirX),
           .rayDirY_out(rayDirY),
           .corr_coef(corr_coef),
           .rendering_x(which_x),           // scanner in
           .probe_x(probe_x),               // map_hit probe
           .probe_y(probe_y),
           .map_hit(map_hit),
           .mov_up(btnU | kbd_btn_W), // kb/btn input
           .mov_down(btnD | kbd_btn_S),
           .mov_left(kbd_btn_A),
           .mov_right(kbd_btn_D),
           .rot_left(btnL | kbd_btn_La),
           .rot_right(btnR | kbd_btn_Ra),
           .frame_tick(frame_tick),
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

  wall_renderer wall_render_inst(
                  .vga_rgb(wall_pixel),
                  .show_y(show_y),
                  .wall_dist(renderDist),
                  .tex_x(tex_x_buff),
                  .hit_side(hit_side_buff),
                  .clk(clk),
                  .rst_n(rst_n)
                );

  entity_manager entity_manager_inst(
                   .clk(clk),
                   .rst_n(rst_n),
                   .frame_tick(frame_tick),
                   .proj_screen_x(proj_screen_x),
                   .proj_screen_y(proj_screen_y),
                   .proj_dist(proj_dist),
                   .proj_step(proj_step),
                   .proj_show(proj_show),
                   .proj_calc_done(proj_calc_done),
                   .target_x(target_x),
                   .target_y(target_y),
                   .target_z(target_z),
                   .target_scale(target_scale),
                   .target_enable(target_enable),
                   .oam_data(oam_data)
                 );

  entity_projection entity_projection_inst(
                      .clk(clk),
                      .rst_n(rst_n),
                      .p_x($signed(player_x)),
                      .p_y($signed(player_y)),
                      .cos_p(cos_p),
                      .sin_p(sin_p),
                      .ent_x(target_x),
                      .ent_y(target_y),
                      .ent_z(target_z),
                      .ent_scale(target_scale),
                      .ent_enable(target_enable),
                      .screen_x(proj_screen_x),
                      .screen_y(proj_screen_y),
                      .ent_dist(proj_dist),
                      .tex_step(proj_step),
                      .show(proj_show),
                      .calc_done(proj_calc_done)
                    );

  entity_renderer entity_render_inst(
                    .clk(clk),
                    .rst_n(rst_n),
                    .show_x(show_x),
                    .show_y(show_y),
                    .wall_dist(renderDist),
                    .oam_data(oam_data),
                    .tex_rgb(tex_rgb),
                    .tex_addr(tex_addr),
                    .entity_rgb_out(entity_pixel),
                    .entity_draw_en(draw_sprite_en)
                  );

  entity_tex_rom entity_tex_inst(
                   .clk(clk),
                   .addr(tex_addr),
                   .color_out(tex_rgb)
                 );

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

  Keyboard_input keyboard_inst(
                   .clk(clk),
                   .rst_n(rst_n),
                   .PS2_DATA(PS2_DATA),
                   .PS2_CLK(PS2_CLK),
                   .btn_W(kbd_btn_W),
                   .btn_A(kbd_btn_A),
                   .btn_S(kbd_btn_S),
                   .btn_D(kbd_btn_D),
                   .btn_SP(kbd_btn_SP),
                   .btn_La(kbd_btn_La),
                   .btn_Ra(kbd_btn_Ra),
                   .btn_Ua(kbd_btn_Ua),
                   .btn_Da(kbd_btn_Da)
                 );

endmodule
