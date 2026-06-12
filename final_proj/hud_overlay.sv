module hud_overlay (
    input logic clk,
    input logic rst_n,

    // vga comm
    input logic [8:0] show_x,
    input logic [8:0] show_y,
    output logic [11:0] pixel_out,

    // ent/wall pixel in
    input logic [11:0] world_pixel,

    // game logic comm
    input logic [5:0] weapon_cd,
    input logic [7:0] health,
    input logic [1:0] game_state,
    input logic [7:0] ammo,
    input logic [15:0] score
  );

  localparam logic [11:0] TP_COLOR = 12'hF0F; // Magic Pink

  // crosshair
  logic is_crosshair;
  always_comb
  begin
    is_crosshair = 1'b0;
    if (show_x >= 159 & show_x <= 161 & show_y >= 115 & show_y <= 125)
      is_crosshair = 1'b1;
    if (show_y >= 119 & show_y <= 121 & show_x >= 155 & show_x <= 165)
      is_crosshair = 1'b1;
  end

  // gun rom
  (* ram_style = "block" *)
  logic [11:0] gun_rom [0:21599]; // Updated Size!
  initial
  begin
    $readmemh("gun_01_tex.mem", gun_rom);
  end

  // gun box
  logic is_gun;
  logic [7:0] gun_recoil_dy;
  logic [9:0] temp_gun_x, temp_gun_y;
  logic [14:0] rom_addr;
  always_comb
  begin
    is_gun = 1'b0;
    rom_addr = 15'd0;
    gun_recoil_dy = {2'b00, weapon_cd} << 1;
    if (show_x >= 160 && show_x < 320 && show_y >= (120 + gun_recoil_dy) && show_y < 240)
    begin
      is_gun = 1'b1;
      temp_gun_x = show_x - 10'd160;
      temp_gun_y = show_y - (10'd120 + gun_recoil_dy);
      rom_addr = (temp_gun_y << 7) + (temp_gun_y << 5) + {5'b0, temp_gun_x};
    end
  end

  // DMG
  logic is_dmg;
  always_comb
  begin
    is_dmg = 1'b0;
    if (health <= 8'd30)
    begin
      if (show_x < 10 | show_x > 310 | show_y < 10 | show_y > 230)
      begin
        is_dmg = 1'b1;
      end
    end
  end

  logic is_text;
  hud_ui_text U_LUT_text (
            .show_x(show_x),
            .show_y(show_y),
            .ammo(ammo),
            .score(score),
            .is_text(is_text)
          );

  // reg output signal
  logic is_gun_r;
  logic is_crosshair_r;
  logic is_dmg_r;
  logic is_text_r;
  logic [1:0] game_state_r;
  logic [11:0] world_pixel_r;
  logic [11:0] gun_tex_rgb;
  always_ff @(posedge clk)
  begin
    if (~rst_n)
    begin
      is_gun_r <= 1'b0;
      is_crosshair_r <= 1'b0;
      is_dmg_r <= 1'b0;
      is_text_r <= 1'b0;
      game_state_r <= 2'd0;
      world_pixel_r <= 12'h000;
      gun_tex_rgb <= 12'h000;
    end
    else
    begin
      is_gun_r <= is_gun;
      is_crosshair_r <= is_crosshair;
      is_dmg_r <= is_dmg;
      is_text_r <= is_text;
      game_state_r <= game_state;
      world_pixel_r <= world_pixel;
      gun_tex_rgb <= gun_rom[rom_addr];
    end
  end

  // final mixer
  always_comb
  begin
    pixel_out = world_pixel_r;

    if (game_state_r == 2'd2)
    begin
      pixel_out = 12'hF00; // DEAD
    end

    else if (is_text_r)
    begin
      pixel_out = 12'hFF0;
    end

    else if (is_crosshair_r)
    begin
      pixel_out = 12'h0F0; // light green
    end

    else if (is_gun_r && (gun_tex_rgb != TP_COLOR))
    begin
      pixel_out = gun_tex_rgb;
    end

    else if (is_dmg_r)
    begin
      pixel_out = {4'hF, world_pixel_r[7:0]}; // red channel
    end
  end

endmodule
