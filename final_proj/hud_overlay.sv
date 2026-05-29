module hud_overlay (
    input  logic clk,
    input  logic rst_n,

    // vga comm
    input  logic [8:0] show_x,
    input  logic [8:0] show_y,
		output logic [11:0] pixel_out,

    // ent/wall pixel in
    input  logic [11:0] world_pixel,

    // game logic comm
    input  logic [5:0]  weapon_cd,
    input  logic [7:0]  player_health,
    input  logic [1:0]  game_state

    // input logic [11:0] gun_tex_rgb,
    
  );

  // crosshair
  logic is_crosshair;
  always_comb
  begin
    is_crosshair = 1'b0;
    if (show_x >= 159 & show_x <= 161 & show_y >= 115 & show_y <= 125)
      is_crosshair = 1'b1;
    if (show_y >= 121 & show_y <= 121 & show_x >= 155 & show_x <= 165)
      is_crosshair = 1'b1;
  end

  // gun
  logic is_gun;
  logic [7:0] gun_recoil_dy;
  always_comb
  begin
    is_gun = 1'b0;
    gun_recoil_dy = {2'b00, weapon_cd} << 1;
    // Gun Barrel
    if (show_x >= 170 && show_x <= 190 &&
        show_y >= (180 + gun_recoil_dy) && show_y <= 240)
    begin
      is_gun = 1'b1;
    end
  end

  // DMG
  logic is_dmg_eff;
  always_comb
  begin
    is_dmg_eff = 1'b0;
    if (player_health <= 8'd30)
    begin
      if (show_x < 10 || show_x > 310 || show_y < 10 || show_y > 230)
      begin
        is_dmg_eff = 1'b1;
      end
    end
  end

	// final mixer
  always_comb
  begin
    pixel_out = world_pixel;

    if (game_state == 2'd2)
    begin
      pixel_out = 12'hF00;
    end

    else if (is_crosshair)
    begin
      pixel_out = 12'h0F0; // light green
    end

    else if (is_gun)
    begin
      pixel_out = 12'h555; // dark gray
    end

    else if (is_dmg_eff)
    begin
      pixel_out = {4'hF, world_pixel[7:0]}; // red channel
    end
  end

endmodule
