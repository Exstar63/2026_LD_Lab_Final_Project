module camera(
    input logic clk,
    input logic rst_n,

    // frame tick control
    input logic frame_tick,

    // player controls
    input logic btn_up,
    input logic btn_down,
    input logic btn_left,
    input logic btn_right,

    // map_rom probe (edge detection)
    output logic [3:0] probe_x,
    output logic [3:0] probe_y,
    input logic map_hit,

    // scanner comm (angle stepping)
    input logic [8:0] rendering_x, // 0~319

    // raycaseter comm
    output logic [15:0] player_x_out,
    output logic [15:0] player_y_out,
    output logic [15:0] sin_p,
    output logic [15:0] cos_p,
    output logic [7:0] ray_angle_out,
    output logic [15:0] rayDirX_out,
    output logic [15:0] rayDirY_out,
    output logic [15:0] corr_coef
  );

  // FOV ray calculation -> renderer comm
  logic signed [9:0]  shift_x;
  logic signed [15:0] temp_x;
  logic [7:0] p_angle, del_angle;
  always_comb
  begin
    shift_x = $signed({1'b0, rendering_x}) - 10'sd160; // shift render coord (0~320) -> (-160~159)
    temp_x = shift_x * 16'sd51; // *0.2=51/256=0.199
  end

  always_ff @(posedge clk)
    if (~rst_n)
    begin
      del_angle <= 8'd0;
      ray_angle_out <= 8'd0;
    end
    else
    begin
      del_angle <= temp_x[15:8];
      ray_angle_out <= p_angle + temp_x[15:8];
    end

  // fisheye corr. / raydir_X,Y -> raycaster
  trig_rom corr_coef_mem(.angle(del_angle),
                         .clk(clk),
                         .cos_out(corr_coef),
                         .sin_out()
                        );

  trig_rom ray_dir_mem(.angle(ray_angle_out),
                       .clk(clk),
                       .cos_out(rayDirX_out),
                       .sin_out(rayDirY_out)
                      );

  // mov const
  localparam logic [15:0] MOVE_SPEED = 16'h0008;  // ~0.1 units in Q8.8
  localparam logic [7:0] TURN_SPEED = 8'd2;       // 2 BAM steps

  // mov state regs
  logic [15:0] p_x, p_y, d_x, d_y;
  logic [15:0] p_x_next, p_y_next;
  logic [7:0] p_angle_next;
  trig_rom trig_mem(.sin_out(sin_p),.cos_out(cos_p),.angle(p_angle),.clk(clk));
  q88_mult cos_mult_inst(.a(cos_p),.b(MOVE_SPEED),.out(d_x));
  q88_mult sin_mult_inst(.a(sin_p),.b(MOVE_SPEED),.out(d_y));

  // player mov (SOCD)
  always_comb
  begin
    player_x_out = p_x;
    player_y_out = p_y;
    probe_x = p_x_next[11:8];
    probe_y = p_y_next[11:8];
    p_x_next = p_x + ((btn_up)? d_x : 16'd0) - ((btn_down)? d_x : 16'd0);
    p_y_next = p_y + ((btn_up)? d_y : 16'd0) - ((btn_down)? d_y : 16'd0);
    p_angle_next = p_angle - ((btn_left)? TURN_SPEED : 8'd0) + ((btn_right)? TURN_SPEED : 8'd0);
  end

  always_ff @(posedge clk) // sync read for map rom
  begin
    if (~rst_n)
    begin
      p_x <= 16'h0180;     // init @ center of grid (1,1)
      p_y <= 16'h0180;
      p_angle <= 8'd0;     // init facing 0 deg
    end
    else if (frame_tick)
    begin
      p_angle <= p_angle_next;
      if (!map_hit)
      begin
        p_x <= p_x_next;
        p_y <= p_y_next;
      end
    end
  end

endmodule
