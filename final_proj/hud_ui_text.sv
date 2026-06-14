module hud_ui_text (
    input logic [8:0] show_x,
    input logic [8:0] show_y,
    input logic [7:0] ammo,
    input logic [15:0] score,
    input  logic [1:0] game_state,
    output logic is_text
  );

  logic [3:0] ammo_d, ammo_o;
  assign ammo_d = ammo / 10;
  assign ammo_o = ammo % 10;

  logic [3:0] score_k, score_h, score_d, score_o;
  assign score_k = (score / 1000) % 10;
  assign score_h = (score / 100)  % 10;
  assign score_d = (score / 10)   % 10;
  assign score_o = score % 10;

  logic [7:0] font_rom [0:136];
  initial
    $readmemh("numbers.mem", font_rom);

  // box
  logic [4:0] temp_dig;
  logic [4:0] temp_x, temp_y;
  logic [2:0] tex_x, tex_y;
  logic [7:0] tex_addr;
  logic [7:0] tex_data;
  logic big_en;

  always_comb
  begin
    is_text = 1'b0;
    temp_dig = 5'd0;
    temp_x = 5'd0;
    temp_y = 5'd0;
    big_en = 0;

    if (game_state == 2'd0 && show_y >= 104 && show_y <= 135 && show_x >= 80 && show_x <= 239) // start
    begin
      temp_y = (show_y - 10'd104);
      temp_x = (show_x - 10'd80) % 32;
      big_en = 1'b1;
      if (show_x < 112)
        temp_dig = 5'd10; // S
      else if (show_x < 144)
        temp_dig = 5'd11; // T
      else if (show_x < 176)
        temp_dig = 5'd12; // A
      else if (show_x < 208)
        temp_dig = 5'd13; // R
      else
        temp_dig = 5'd11; // T
    end

    else if (game_state == 2'd3 && show_y >= 104 && show_y <= 135 && show_x >= 112 && show_x <= 207)
    begin
      temp_y = (show_y - 10'd104);
      temp_x = (show_x - 10'd112) % 32;
      big_en = 1'b1;
      if (show_x < 144)
        temp_dig = 5'd14; // W
      else if (show_x < 176)
        temp_dig = 5'd15; // I
      else
        temp_dig = 5'd16; // N
    end

    else if (show_y >= 210 && show_y <= 225) // ammo
    begin
      temp_y = show_y - 10'd210;

      if (show_x >= 20 && show_x <= 35)
      begin
        temp_dig = ammo_d;
        temp_x = show_x - 10'd20;
      end
      else if (show_x >= 36 && show_x <= 51)
      begin
        temp_dig = ammo_o;
        temp_x = show_x - 10'd36;
      end
    end

    else if (show_y >= 10 && show_y <= 25) // score
    begin
      temp_y = show_y - 10'd10;

      if (show_x >= 10 && show_x <= 25)
      begin
        temp_dig = score_k;
        temp_x = show_x - 10'd10;
      end
      else if (show_x >= 26 && show_x <= 41)
      begin
        temp_dig = score_h;
        temp_x = show_x - 10'd26;
      end
      else if (show_x >= 42 && show_x <= 57)
      begin
        temp_dig = score_d;
        temp_x = show_x - 10'd42;
      end
      else if (show_x >= 58 && show_x <= 73)
      begin
        temp_dig = score_o;
        temp_x = show_x - 10'd58;
      end
    end

    if (big_en)
    begin
      tex_x = temp_y[4:2];
      tex_y = 3'd7 - temp_x[4:2];
    end
    else
    begin
      tex_x = temp_y[4:1];
      tex_y = 3'd7 - temp_x[4:1];
    end

    tex_addr = (temp_dig << 3) + tex_x;
    tex_data = font_rom[tex_addr];

    if (tex_data[tex_y] == 1'b1)
    begin
      is_text = 1'b1;
    end
  end

endmodule
