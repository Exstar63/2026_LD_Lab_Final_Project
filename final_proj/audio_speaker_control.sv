module audio_speaker_control(
    output logic audio_mclk, // master clock
    output logic audio_lrck, // left-right clock
    output logic audio_sck,   // serial clock
    output logic audio_sdin, // serial audio data input
    input logic [15:0] audio_in_left, // left channel audio data input
    input logic [15:0] audio_in_right, // right channel audio data input
    input logic clk,  // clock from the crystal
    input logic rst_n  // active low reset
  );

  // Declare internal signal nodes
  logic [8:0] clk_cnt, clk_cnt_next;
  logic [15:0] audio_left, audio_right;

  // Counter for the clock divider
  assign clk_cnt_next = clk_cnt + 1'b1;

  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)
      clk_cnt <= 9'd0;
    else
      clk_cnt <= clk_cnt_next;

  // Assign divided clock output
  assign audio_mclk = clk_cnt[1];
  assign audio_lrck = clk_cnt[8];
  assign audio_sck = clk_cnt[3];

  // audio input data buffer
  always_ff @(posedge clk_cnt[4], negedge rst_n)
    if (~rst_n)
    begin
      audio_left <= 16'd0;
      audio_right <= 16'd0;
    end
    else
    begin
      audio_left <= audio_in_left;
      audio_right <= audio_in_right;
    end

  always_comb
  case (clk_cnt[8:4])
    5'b00000:
      audio_sdin = audio_right[0];
    5'b00001:
      audio_sdin = audio_left[15];
    5'b00010:
      audio_sdin = audio_left[14];
    5'b00011:
      audio_sdin = audio_left[13];
    5'b00100:
      audio_sdin = audio_left[12];
    5'b00101:
      audio_sdin = audio_left[11];
    5'b00110:
      audio_sdin = audio_left[10];
    5'b00111:
      audio_sdin = audio_left[9];
    5'b01000:
      audio_sdin = audio_left[8];
    5'b01001:
      audio_sdin = audio_left[7];
    5'b01010:
      audio_sdin = audio_left[6];
    5'b01011:
      audio_sdin = audio_left[5];
    5'b01100:
      audio_sdin = audio_left[4];
    5'b01101:
      audio_sdin = audio_left[3];
    5'b01110:
      audio_sdin = audio_left[2];
    5'b01111:
      audio_sdin = audio_left[1];
    5'b10000:
      audio_sdin = audio_left[0];
    5'b10001:
      audio_sdin = audio_right[15];
    5'b10010:
      audio_sdin = audio_right[14];
    5'b10011:
      audio_sdin = audio_right[13];
    5'b10100:
      audio_sdin = audio_right[12];
    5'b10101:
      audio_sdin = audio_right[11];
    5'b10110:
      audio_sdin = audio_right[10];
    5'b10111:
      audio_sdin = audio_right[9];
    5'b11000:
      audio_sdin = audio_right[8];
    5'b11001:
      audio_sdin = audio_right[7];
    5'b11010:
      audio_sdin = audio_right[6];
    5'b11011:
      audio_sdin = audio_right[5];
    5'b11100:
      audio_sdin = audio_right[4];
    5'b11101:
      audio_sdin = audio_right[3];
    5'b11110:
      audio_sdin = audio_right[2];
    5'b11111:
      audio_sdin = audio_right[1];
    default:
      audio_sdin = 1'b0;
  endcase

endmodule
