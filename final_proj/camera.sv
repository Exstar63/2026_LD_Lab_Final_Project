module camera (
    input  logic        clk,
    input  logic        rst_n,

    // temp input
    input  logic        btn_up,
    input  logic        btn_down,
    input  logic        btn_left,
    input  logic        btn_right,

    input  logic [8:0]  rendering_x, // 0~319 wires rendering_x >>1 (index/2)

    // Outputs to raycaseter
    output logic [15:0] player_x_out,
    output logic [15:0] player_y_out,
    output logic [7:0]  ray_angle_out
  );

  // state regs
  logic [15:0] p_x;
  logic [15:0] p_y;
  logic [7:0]  p_angle;

  // mov const
  localparam logic [15:0] MOVE_SPEED = 16'd26; // ~0.1 units in Q8.8
  localparam logic [7:0]  TURN_SPEED = 8'd2;   // 2 BAM steps

  // player mov
  always_comb
  begin
    player_x_out = p_x;
    player_y_out = p_y;
  end


  always_ff @(posedge clk) // sync read for map rom
    if (~rst_n)
    begin
      p_x     <= 16'h0180; // Spawn @ grid (1,1) facing 0 degrees
      p_y     <= 16'h0180;
      p_angle <= 8'd0;
    end
    else
    begin
      // ---------------------------------------------------------
      // TODO: Implement your movement logic here.
      //
      // Note: Do not update positions every 100MHz clock cycle!
      // You will want to create a `frame_tick` signal (e.g., from
      // your VGA v_sync) and only move the player when it pulses.
      // ---------------------------------------------------------
    end

  // FOV ray calculation -> renderer comm
  logic signed [9:0]  shift_x;
  logic signed [15:0] temp_x;
  logic [7:0]         del_angle;
  always_comb
  begin
    shift_x = $signed({1'b0, rendering_x}) - 10'sd160; // shift render coord (0~320) -> (-160~159)
    temp_x = shift_x * 16'sd51;
    del_angle = temp_x[15:8];   // *0.2=51/256=0.199
    ray_angle_out = p_angle + del_angle;
  end

endmodule
