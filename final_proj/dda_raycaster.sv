module dda_raycaster (
    input  logic        clk,
    input  logic        rst,

    // Inputs from PlayerCam
    input  logic [15:0] player_x,
    input  logic [15:0] player_y,
    input  logic [7:0]  ray_angle,
    input  logic        start_ray, // Pulses high when rendering_x changes

    // Map comms
    output logic [3:0]  map_x_out,
    output logic [3:0]  map_y_out,
    input  logic        map_hit,   // 1 if wall, 0 if empty

    // Outputs to the Renderer
    output logic [15:0] finalDist,
    output logic        ray_done
  );

  // pipelined dda raycaster algo
  // FSM State Definition
  typedef enum logic [2:0] {
            IDLE      = 3'd0,
            INIT_1    = 3'd1,
            INIT_2    = 3'd2,
            STEP      = 3'd3,
            MEM_WAIT  = 3'd4,
            CHECK_HIT = 3'd5,
            CALC_DIST = 3'd6
          } state_t;

  state_t state, next_state;

  // DDA reg (q8.8)
  logic [15:0] sideDistX, sideDistY;
  logic [15:0] deltaDistX, deltaDistY;
  logic [3:0]  map_x, map_y;
  logic signed [1:0] step_x, step_y; // +1 or -1
  logic hit_side; // 0 for vertical wall (X), 1 for horizontal wall (Y)

  logic [15:0] sideDistX_next, sideDistY_next;
  logic [15:0] deltaDistX_next, deltaDistY_next;
  logic [3:0]  map_x_next, map_y_next;
  logic signed [1:0] step_x_next, step_y_next;
  logic hit_side_next;
  logic [15:0] finalDist_next;
  logic        ray_done_next;

  // DistX/Y inv trig rom
  logic [15:0] rom_deltaX, rom_deltaY;
  inv_trig_rom inv_trig_inst (
                 .clk(clk),
                 .angle(ray_angle),
                 .abs_sec_out(rom_deltaX),
                 .abs_csc_out(rom_deltaY)
               );

  // checking quadrant with math coords +y up +x right
  logic ray_right, ray_up;
  always_comb
  begin
    ray_right = (ray_angle < 8'd64) || (ray_angle >= 8'd192);
    ray_up = (ray_angle > 8'd0) && (ray_angle < 8'd128);
  end

  assign map_x_out = map_x;
  assign map_y_out = map_y;

  // State Machine Sequential Block
  always_ff @(posedge clk)
  begin
    if (rst)
    begin
      state <= IDLE;
      ray_done <= 1'b0;
      hit_side <= 1'b0;
    end
    else
    begin
      state <= next_state;
      sideDistX <= sideDistX_next;
      sideDistY <= sideDistY_next;
      deltaDistX <= deltaDistX_next;
      deltaDistY <= deltaDistY_next;
      finalDist <= finalDist_next;
      hit_side <= hit_side_next;
      map_x <= map_x_next;
      map_y <= map_y_next;
      step_x <= step_x_next;
      step_y <= step_y_next;
      ray_done <= ray_done_next;
    end
  end

  // FSM
  always_comb
  begin
    next_state = state;
    sideDistX_next = sideDistX;
    sideDistY_next = sideDistY;
    deltaDistX_next = deltaDistX;
    deltaDistY_next = deltaDistY;
    finalDist_next = finalDist;
    hit_side_next = hit_side;
    map_x_next = map_x;
    map_y_next = map_y;
    step_x_next = step_x;
    step_y_next = step_y;
    ray_done_next = ray_done;

    case (state)
      IDLE:
      begin
        ray_done_next = 1'b0;
        if (start_ray)
        begin
          // Grab the integer grid coordinates (top 8 bits)
          map_x_next = player_x[15:8];
          map_y_next = player_y[15:8];
          next_state = INIT_1;
        end
      end

      INIT_1: // wait inv_trig_rom -> output deltaDist
      begin
        deltaDistX_next = rom_deltaX;
        deltaDistY_next = rom_deltaY;
        next_state = INIT_2;
      end

      INIT_2:
      begin
        // Setup X direction and initial side distance
        if (ray_right)
        begin
          step_x_next = 2'sd1;
          // (1.0 - fraction) * deltaDistX
          sideDistX_next = ((9'd256 - player_x[7:0]) * deltaDistX) >> 8;
        end
        else
        begin
          step_x_next = -2'sd1;
          // fraction * deltaDistX
          sideDistX_next = (player_x[7:0] * deltaDistX) >> 8;
        end

        // Setup Y direction and initial side distance
        if (ray_up)
        begin
          step_y_next = 2'sd1;
          // (1.0 - fraction) * deltaDistY
          sideDistY_next = ((9'd256 - player_y[7:0]) * deltaDistY) >> 8;
        end
        else
        begin
          step_y_next = -2'sd1;
          // fraction * deltaDistY
          sideDistY_next = (player_y[7:0] * deltaDistY) >> 8;
        end
        next_state = STEP;
      end

      STEP:
      begin
        if (sideDistX < sideDistY)
        begin
          // Move along X axis
          sideDistX_next = sideDistX + deltaDistX;
          // Cast step_x to 4 bits to safely add to the 4-bit map_x
          map_x_next = map_x + 4'(step_x);
          hit_side_next = 1'b0; // 0 means an X-aligned (vertical) wall
        end
        else
        begin
          // Move along Y axis
          sideDistY_next = sideDistY + deltaDistY;
          map_y_next = map_y + 4'(step_y);
          hit_side_next = 1'b1; // 1 means a Y-aligned (horizontal) wall
        end
        next_state = MEM_WAIT;
      end

      MEM_WAIT:
        next_state = CHECK_HIT; // timeholder wait for ROM output

      CHECK_HIT:
      begin
        if (map_hit)
          next_state = CALC_DIST;
        else
          next_state = STEP;
      end

      CALC_DIST:
      begin
        if (hit_side)  // x-wall
        begin
          finalDist_next = sideDistY - deltaDistY;
        end
        else           // y-wall
        begin
          finalDist_next = sideDistX - deltaDistX;
        end
        ray_done_next = 1'b1; // col ready flag
        next_state = IDLE;
      end
    endcase
  end

endmodule
