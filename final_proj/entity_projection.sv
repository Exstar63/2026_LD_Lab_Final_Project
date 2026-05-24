module entity_projection(
    input logic clk,
    input logic rst_n,

    // camera comss
    input logic signed [15:0] p_x, p_y,
    input logic signed [15:0] cos_p, sin_p,

    // manager input comms
    input logic signed [15:0] ent_x, ent_y, ent_z,
    input logic [15:0] ent_scale,
    input logic ent_enable,

    // manager output comms
    output logic signed [15:0] screen_x, screen_y,
    output logic [15:0] ent_dist,
    output logic [15:0] tex_step,
    output logic show,
    output logic calc_done
  );

  typedef enum logic [1:0] {
            IDLE     = 2'd0,
            WAIT_ROM = 2'd1,
            CALC     = 2'd2
          } state_t;

  // stable input
  logic signed [15:0] p_x_r, p_y_r;
  logic signed [31:0] cos_p_r, sin_p_r, ent_z_r;
  logic signed [15:0] ent_x_r, ent_y_r;
  logic [15:0] ent_scale_r;
  always_ff @(posedge clk)
  begin
    if (~rst_n)
    begin
      p_x_r <= 16'sd0;
      p_y_r <= 16'sd0;
      cos_p_r <= 32'sd0;
      sin_p_r <= 32'sd0;
      ent_x_r <= 16'sd0;
      ent_y_r <= 16'sd0;
      ent_z_r <= 32'sd0;
      ent_scale_r <= 16'sd0;
    end
    else if (ent_enable & (state == IDLE))
    begin
      p_x_r <= p_x;
      p_y_r <= p_y;
      cos_p_r <= cos_p;
      sin_p_r <= sin_p;
      ent_x_r <= ent_x;
      ent_y_r <= ent_y;
      ent_z_r <= ent_z;
      ent_scale_r <= ent_scale;
    end
  end

  // regs
  state_t state, state_next;
  logic signed [15:0] screen_x_next, screen_y_next;
  logic [15:0] ent_depth_next, tex_step_next;
  logic show_next, calc_done_next;

  // calc
  logic [15:0] lut_height;
  logic [31:0] tex_step_temp;
  logic signed [31:0] dx, dy;
  logic signed [31:0] hor_pos_temp, depth_temp;
  logic signed [31:0] hor_pos, depth;
  logic signed [31:0] d_screen_x, d_screen_y;
  always_comb
  begin
    dx = ent_x_r - p_x_r;
    dy = ent_y_r - p_y_r;
    hor_pos_temp = -(dx * sin_p_r) + (dy * cos_p_r);
    depth_temp = (dx * cos_p_r) + (dy * sin_p_r);
    hor_pos = hor_pos_temp >>> 8;
    depth = depth_temp >>> 8;
    d_screen_x = (hor_pos * $signed({1'b0, lut_height})) >>> 8;
    d_screen_y = (ent_z_r * $signed({1'b0, lut_height})) >>> 8;
    tex_step_temp = depth * ent_scale_r;
  end


  // division LUT (240/dist)
  (* ram_style = "block" *)
  logic [7:0] height_rom [0:1023];
  initial
  begin
    $readmemh("height_lut.mem", height_rom);
  end
  always_ff @(posedge clk)
  begin
    lut_height <= height_rom[depth[11:2]]; //depth[11:2]
  end

  // FSM
  always_comb
  begin
    state_next = state;
    show_next = show;
    ent_depth_next = ent_dist;
    screen_x_next = screen_x;
    screen_y_next = screen_y;
    tex_step_next = tex_step;
    calc_done_next   = 1'b0;
    case (state)
      IDLE:
        if (ent_enable)
          state_next = WAIT_ROM;

      WAIT_ROM:
      begin
        if (dx > 32'sd2560 || dx < -32'sd2560 || dy > 32'sd2560 || dy < -32'sd2560)
        begin
          show_next = 1'b0;
          calc_done_next = 1'b1;
          state_next = IDLE;
        end
        else
        begin
          if (depth > 32'sd10)
            state_next = CALC;
          else
          begin
            show_next = 1'b0;
            calc_done_next = 1'b1;
            state_next = IDLE;
          end
        end
      end

      CALC:
      begin
        if ((32'sd160 + d_screen_x) < -32'sd200 || (32'sd160 + d_screen_x) > 32'sd520)
        begin
          show_next = 1'b0;
          calc_done_next = 1'b1;
          state_next = IDLE;
        end
        else
        begin
          show_next = 1'b1;
          ent_depth_next = depth[15:0];
          tex_step_next = tex_step_temp[23:8];
          screen_x_next = 16'sd160 + d_screen_x[15:0];
          screen_y_next = 16'sd120 - d_screen_y[15:0];
          calc_done_next = 1'b1;
          state_next = IDLE;
        end
      end
    endcase
  end

  always_ff @(posedge clk)
  begin
    if (~rst_n)
    begin
      state <= IDLE;
      show <= 1'b0;
      ent_dist <= 16'sd0;
      screen_x <= 16'sd160;
      screen_y <= 16'sd120;
      tex_step <= 16'sd0;
      calc_done <= 1'b0;
    end
    else
    begin
      state <= state_next;
      show <= show_next;
      ent_dist <= ent_depth_next;
      screen_x <= screen_x_next;
      screen_y <= screen_y_next;
      tex_step <= tex_step_next;
      calc_done <= calc_done_next;
    end
  end
endmodule
