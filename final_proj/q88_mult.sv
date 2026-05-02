module q88_mult(
    input  logic signed [15:0] a,
    input  logic signed [15:0] b,
    output logic signed [15:0] out
  );

  logic signed [31:0] temp;

  always_comb
  begin
    temp = a * b;
    out = temp[23:8]; // take middle 16'b
  end

endmodule
