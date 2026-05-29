typedef struct packed
        {
          logic [4:0] id;
          logic signed [15:0] screen_x;
          logic signed [15:0] screen_y;
          logic [15:0] Dist;
          logic [15:0] step;
          logic valid;
        } oam_entry_t;

module entity_manager(
    input logic clk,
    input logic rst_n,
    input logic frame_tick,

    // projection input comm
    input logic signed [15:0] proj_screen_x,
    input logic signed [15:0] proj_screen_y,
    input logic [15:0] proj_dist,
    input logic [15:0] proj_step,
    input logic proj_show,
    input logic proj_calc_done,

    // projectino output comm
    output logic signed [15:0] target_x,
    output logic signed [15:0] target_y,
    output logic signed [15:0] target_z,
    output logic [15:0] target_scale,
    output logic target_enable,

    // entity renderer/game_logic comm
    input logic kill_en,
    input logic [4:0] kill_id,
    output oam_entry_t oam_data [0:7] // max 8 entity
  );

  // local (temp) entity arr.
  logic signed [15:0] ent_world_x [0:31];
  logic signed [15:0] ent_world_y [0:31];
  logic signed [15:0] ent_world_z [0:31];
  logic [15:0] ent_scale [0:31];
  logic [31:0] ent_enable;
  always_comb
  begin
    for (int i=4; i<32; i++)
    begin
      ent_world_x[i] = 16'sd0;
      ent_world_y[i] = 16'sd0;
      ent_world_z[i] = 16'sd0;
      ent_scale[i] = 16'd0;
    end

    // ent_0
    ent_world_x[0] = 16'h0580;
    ent_world_y[0] = 16'h0580;
    ent_world_z[0] = -16'sd80;
    ent_scale[0] = 16'd80;

    // ent_1
    ent_world_x[1] = 16'h0680;
    ent_world_y[1] = 16'h0580;
    ent_world_z[1] = -16'sd80;
    ent_scale[1] = 16'd80;

    // ent_2
    ent_world_x[2] = 16'h0780;
    ent_world_y[2] = 16'h0580;
    ent_world_z[2] = -16'sd80;
    ent_scale[2] = 16'd80;

    // ent_3
    ent_world_x[3] = 16'h0880;
    ent_world_y[3] = 16'h0580;
    ent_world_z[3] = -16'sd80;
    ent_scale[3] = 16'd80;
  end

  typedef enum logic [1:0] {
            IDLE,
            LOAD,
            WAIT,
            SAVE
          } state_t;

  // reg
  state_t state, state_next;
  logic [4:0] ent_idx, ent_idx_next;
  logic [3:0] oam_idx, oam_idx_next;
  logic signed [15:0] target_x_next;
  logic signed [15:0] target_y_next;
  logic signed [15:0] target_z_next;
  logic [15:0] target_scale_next;
  logic target_enable_next;
  oam_entry_t oam_data_next [0:7];

  // FSM
  always_comb
  begin
    state_next = state;
    ent_idx_next = ent_idx;
    oam_idx_next = oam_idx;
    target_x_next = target_x;
    target_y_next = target_y;
    target_z_next = target_z;
    target_scale_next = target_scale;
    target_enable_next = 1'b0;

    for (int i=0; i<8; i++)
      oam_data_next[i] = oam_data[i];

    case (state)
      IDLE:
      begin
        if (frame_tick)
        begin
          ent_idx_next = 5'd0;
          oam_idx_next = 3'd0;
          for (int i=0; i<8; i++)
            oam_data_next[i].valid = 1'b0;
          state_next = LOAD;
        end
      end

      LOAD:
      begin
        target_x_next = ent_world_x[ent_idx];
        target_y_next = ent_world_y[ent_idx];
        target_z_next = ent_world_z[ent_idx];
        target_scale_next = ent_scale[ent_idx];
        target_enable_next = ent_enable[ent_idx];

        if (ent_enable[ent_idx])
          state_next = WAIT;
        else
        begin
          if (ent_idx == 5'd31)
            state_next = IDLE;
          else
          begin
            ent_idx_next = ent_idx + 1;
            state_next = LOAD;
          end
        end
      end


      WAIT: // wait for LUT
      begin
        target_enable_next = 1'b0;
        if (proj_calc_done)
        begin
          state_next = SAVE;
        end
      end

      SAVE:
      begin
        if ((proj_show) & (proj_screen_x > -16'sd100) & (proj_screen_x <  16'sd420) & (oam_idx < 8)) // overflow fix
        begin
          oam_data_next[oam_idx].id = ent_idx;
          oam_data_next[oam_idx].screen_x = proj_screen_x;
          oam_data_next[oam_idx].screen_y = proj_screen_y;
          oam_data_next[oam_idx].Dist = proj_dist;
          oam_data_next[oam_idx].step = proj_step;
          oam_data_next[oam_idx].valid = 1'b1;
          oam_idx_next = oam_idx + 1;
        end

        if (ent_idx == 5'd31 || (proj_show && oam_idx == 3'd7))
          state_next = IDLE;
        else
        begin
          ent_idx_next = ent_idx + 1;
          state_next = LOAD;
        end
      end
    endcase
  end

  always_ff @(posedge clk)
  begin
    if (~rst_n)
    begin
      state <= IDLE;
      ent_idx <= 5'd0;
      oam_idx <= 3'd0;
      target_x <= 16'sd0;
      target_y <= 16'sd0;
      target_z <= 16'sd0;
      target_scale <= 16'd0;
      target_enable <= 1'b0;
      ent_enable[3:0] <= 4'b1111;
      for (int i=4; i<32; i++)
        ent_enable[i] <= 1'b0;
      for (int i=0; i<8; i++)
        oam_data[i].valid <= 1'b0;
    end
    else
    begin
      state <= state_next;
      ent_idx <= ent_idx_next;
      oam_idx <= oam_idx_next;
      target_x <= target_x_next;
      target_y <= target_y_next;
      target_z <= target_z_next;
      target_scale <= target_scale_next;
      target_enable <= target_enable_next;
      for (int i=0; i<8; i++)
      begin
        oam_data[i].id <= oam_data_next[i].id;
        oam_data[i].screen_x <= oam_data_next[i].screen_x;
        oam_data[i].screen_y <= oam_data_next[i].screen_y;
        oam_data[i].Dist <= oam_data_next[i].Dist;
        oam_data[i].step <= oam_data_next[i].step;
        oam_data[i].valid <= oam_data_next[i].valid;
      end
      if (kill_en)
        ent_enable[kill_id] <= 1'b0;
    end
  end
endmodule
