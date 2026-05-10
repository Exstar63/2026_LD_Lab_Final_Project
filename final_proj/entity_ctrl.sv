module entity_ctrl(
    input  logic clk,
    input  logic rst_n,

    // projection comms
    output logic ent_enable,
    output logic [15:0] ent_x,
    output logic [15:0] ent_y,
    output logic [3:0]  ent_tex_id
  );

  // temp single entity
  always_comb
  begin
    ent_enable = 1'b1;
    ent_x = 16'h0580;
    ent_y = 16'h0580;
    ent_tex_id = 4'd1;
  end

endmodule
