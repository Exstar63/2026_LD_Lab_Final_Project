module game_logic(
    input logic clk,
    input logic rst_n,
    input logic frame_tick,

    // p control input
    input logic btn_start,
    input logic btn_shoot,

    // ent manager comm
    input oam_entry_t oam_data [0:7],
    output logic kill_en,
    output logic [4:0] kill_id,

    // global comm
    input logic player_hit,
    input logic enemy_killed,
    output logic [1:0] game_state,
    output logic [7:0] health,
    output logic [7:0] ammo,
    output logic [5:0] weapon_cd,
    output logic [15:0] score
  );

  typedef enum logic [1:0] {
            STATE_MENU = 2'd0,
            STATE_PLAY = 2'd1,
            STATE_DEAD = 2'd2,
            STATE_WIN  = 2'd3
          } state_t;

  localparam logic [7:0] MAX_HEALTH = 8'd100;
  localparam logic [7:0] MAX_AMMO = 8'd30;
  localparam logic [7:0] DMG = 8'd20;

  // shoot boxing
  logic [4:0] target_id;
  logic [15:0] dist_min;
  logic boxed;
  always_comb
  begin
    target_id = 5'd0;
    dist_min = 16'hFFFF;
    boxed = 1'b0;
    for (int i = 0; i < 8; i++)
    begin
      if (oam_data[i].valid)
      begin
        if ((oam_data[i].screen_x > 16'sd140) && (oam_data[i].screen_x < 16'sd180))
        begin
          if (oam_data[i].Dist < dist_min)
          begin
            dist_min = oam_data[i].Dist;
            target_id = oam_data[i].id;
            boxed = 1'b1;
          end
        end
      end
    end
  end

  // main game logic
  logic [7:0] health_next, ammo_next;
  logic [15:0] score_next;
  logic kill_en_next;
  logic [4:0] kill_id_next;
  logic [5:0] weapon_cd_next;
  state_t state, state_next;
  always_comb
  begin
    game_state = state;
    state_next = state;
    health_next = health;
    ammo_next = ammo;
    score_next = score;
    weapon_cd_next = weapon_cd;
    kill_en_next = 1'b0;
    kill_id_next = target_id;

    if (frame_tick)
    begin
      if (weapon_cd > 0)
      begin
        weapon_cd_next = weapon_cd - 1;
      end

      case (state)
        STATE_MENU:
        begin
          health_next = MAX_HEALTH;
          ammo_next   = MAX_AMMO;
          score_next  = 16'd0;
          weapon_cd_next = 6'd0;
          if (btn_start)
          begin
            state_next = STATE_PLAY;
          end
        end

        STATE_PLAY:
        begin
          if (btn_shoot & (weapon_cd == 0) & (ammo > 0))
          begin
            // ammo_next = ammo - 1;
            weapon_cd_next = 6'd15; // 15f
            if (boxed)
            begin
              kill_en_next = 1'b1;
              kill_id_next = target_id;
              score_next = score + 100;
            end
          end

          if (player_hit)
          begin
            if (health > DMG)
            begin
              health_next = health - DMG;
            end
            else
            begin
              health_next = 8'd0;
              state_next = STATE_DEAD; // Player died!
            end
          end

          if (enemy_killed)
          begin
            score_next = score + 100;
            if (score_next >= 16'd1600)
            begin // 16 enemies * 100
              state_next = STATE_WIN;
            end
          end
        end

        STATE_DEAD:
        begin
          if (btn_start)
            state_next = STATE_MENU;
        end

        STATE_WIN:
        begin
          if (btn_start)
            state_next = STATE_MENU;
        end
      endcase
    end
  end

  always_ff @(posedge clk)
  begin
    if (~rst_n)
    begin
      state <= STATE_MENU;
      health <= MAX_HEALTH;
      ammo <= MAX_AMMO;
      score <= 16'd0;
      weapon_cd <= 6'd0;
      kill_en <= 1'b0;
      kill_id <= 5'd0;
    end
    else
    begin
      state <= state_next;
      health <= health_next;
      ammo <= ammo_next;
      score <= score_next;
      weapon_cd <= weapon_cd_next;
      kill_en <= kill_en_next;
      kill_id <= kill_id_next;
    end
  end

endmodule
