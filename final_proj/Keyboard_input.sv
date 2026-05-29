module Keyboard_input(
    input logic clk,
    input logic rst_n,
    inout logic PS2_DATA,
    inout logic PS2_CLK,
    output logic btn_W,
    output logic btn_A,
    output logic btn_S,
    output logic btn_D,
    output logic btn_SP,
    output logic btn_La,
    output logic btn_Ra,
    output logic btn_Ua,
    output logic btn_Da
  );

  logic [511:0] key_down;
  logic [8:0] last_change;

  always_comb
  begin
    btn_W = key_down[9'h1D];
    btn_A = key_down[9'h1C];
    btn_S = key_down[9'h1B];
    btn_D = key_down[9'h23];
    btn_SP = key_down[9'h29];
    btn_La = key_down[9'h6B];
    btn_Ra = key_down[9'h74];
    btn_Ua = key_down[9'h75];
    btn_Da = key_down[9'h72];
  end

  KeyboardDecoder Ukd(
                    .key_down(key_down),
                    .last_change(last_change),
                    .key_valid(),
                    .PS2_DATA(PS2_DATA),
                    .PS2_CLK(PS2_CLK),
                    .rst(~rst_n),
                    .clk(clk)
                  );
endmodule
