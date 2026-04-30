module q88_mult (
    input  logic signed [15:0] a,
    input  logic signed [15:0] b,
    output logic signed [15:0] ab_mult
  );

  logic signed [31:0] temp;

  always_comb
  begin
    temp = a * b;
    ab_mult = temp[23:8]; // take middle 16'b
  end

endmodule
