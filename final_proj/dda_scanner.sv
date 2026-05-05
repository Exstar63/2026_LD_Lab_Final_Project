module dda_scanner(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        v_blank,      // High when VGA is in V-Blank (inactive area)

    // dda_raycatser / render comm
    input  logic        ray_done,
    output logic        start_ray,
    output logic [8:0]  rendering_x,  // 0-319, goes to player_camera and buffer_addr

    // dist_buffer comm
    output logic        write_enable
  );

  typedef enum logic [2:0] {
            WAIT_FRAME = 3'd0,
            PREP_DDA   = 3'd1,
            START_DDA  = 3'd2,
            WAIT_DDA   = 3'd3,
            NEXT_RAY   = 3'd4
          } state_t;

  state_t state, state_next;
  logic [8:0] ray_count, ray_count_next;

  always_comb
  begin
    state_next     = state;
    ray_count_next = ray_count;
    rendering_x = ray_count;
    start_ray      = 1'b0;
    write_enable   = 1'b0;  // dist_buffer

    case (state)
      WAIT_FRAME:
      begin
        ray_count_next = 9'd0;
        if (v_blank)
          state_next = START_DDA;
      end

      PREP_DDA:
        state_next = START_DDA;  // wait for corr_coef rom

      START_DDA:
      begin
        start_ray = 1'b1;
        state_next = WAIT_DDA;
      end

      WAIT_DDA:
      begin
        if (ray_done)
        begin
          write_enable = 1'b1;   // dist_buffer
          state_next = NEXT_RAY;
        end
      end

      NEXT_RAY:
      begin
        if (ray_count == 9'd319)
        begin
          ray_count_next = 9'd0;
          state_next = WAIT_FRAME;
        end
        else
        begin
          ray_count_next = ray_count + 1'b1;
          state_next = PREP_DDA;
        end
      end

      default:
        state_next = WAIT_FRAME;
    endcase
  end

  always_ff @(posedge clk) // sync read for buffer
    if (~rst_n)
    begin
      state     <= WAIT_FRAME;
      ray_count <= 9'd0;
    end
    else
    begin
      state     <= state_next;
      ray_count <= ray_count_next;
    end

endmodule
