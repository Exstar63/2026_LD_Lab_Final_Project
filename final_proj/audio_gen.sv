module audio_gen (
    input logic clk,
    input logic rst_n,

    // game comms
    input logic trigger,
    input logic death,

    // speaker comm
    output logic [15:0] audio_out_left,
    output logic [15:0] audio_out_right
  );

  (* ram_style = "block" *)
  logic signed [15:0] gunshot_rom [0:4410];
  initial
    $readmemh("audio_gunshot.mem", gunshot_rom);

  (* ram_style = "block" *)
  logic signed [15:0] death_rom [0:4410];
  initial
    $readmemh("audio_death.mem", death_rom);

  logic [13:0] sample_clk_cnt;
  logic sample_p;
  always_ff @(posedge clk)
  begin
    if (~rst_n)
    begin
      sample_clk_cnt <= 14'd0;
      sample_p <= 1'b0;
    end
    else
    begin
      if (sample_clk_cnt == 14'd9069)
      begin
        sample_clk_cnt <= 14'd0;
        sample_p <= 1'b1;
      end
      else
      begin
        sample_clk_cnt <= sample_clk_cnt + 1'b1;
        sample_p    <= 1'b0;
      end
    end
  end


  localparam int unsigned SAMPLE_LAST = 13'd4409;

  logic [12:0] gun_addr, gun_addr_next;
  logic [12:0] death_addr, death_addr_next;
  logic gun_en, gun_en_next;
  logic death_en, death_en_next;

  logic signed [15:0] gun_audio;
  logic signed [15:0] death_audio;
  logic signed [16:0] mixed_temp;
  logic signed [15:0] mixed_out;

  always_comb
  begin
    gun_audio = gun_en ? gunshot_rom[gun_addr]>>>3 : 16'sd0;
    death_audio = death_en ? death_rom[death_addr]>>>3 : 16'sd0;
    mixed_temp = $signed({gun_audio[15], gun_audio}) + $signed({death_audio[15], death_audio});
    if (mixed_temp > 17'sd32767)
      mixed_out = 16'sd32767;
    else if (mixed_temp < -17'sd32768)
      mixed_out = -16'sd32768;
    else
      mixed_out = mixed_temp[15:0];
  end

  always_comb
  begin
    gun_addr_next = gun_addr;
    death_addr_next = death_addr;
    gun_en_next = gun_en;
    death_en_next = death_en;

    if (trigger)
    begin
      gun_en_next = 1'b1;
      gun_addr_next = 13'd0;
    end

    if (death)
    begin
      death_en_next = 1'b1;
      death_addr_next = 13'd0;
    end

    if (sample_p)
    begin
      if (gun_en)
      begin
        if (gun_addr == SAMPLE_LAST)
        begin
          gun_en_next = 1'b0;
          gun_addr_next = 13'd0;
        end
        else
        begin
          gun_addr_next = gun_addr + 1'b1;
        end
      end

      if (death_en)
      begin
        if (death_addr == SAMPLE_LAST)
        begin
          death_en_next = 1'b0;
          death_addr_next = 13'd0;
        end
        else
        begin
          death_addr_next = death_addr + 1'b1;
        end
      end
    end
  end

  always_ff @(posedge clk)
  begin
    if (~rst_n)
    begin
      gun_addr <= 13'd0;
      death_addr <= 13'd0;
      gun_en <= 1'b0;
      death_en <= 1'b0;
      audio_out_left <= 16'h0000;
      audio_out_right <= 16'h0000;
    end
    else
    begin
      gun_addr <= gun_addr_next;
      death_addr <= death_addr_next;
      gun_en <= gun_en_next;
      death_en <= death_en_next;
      audio_out_left <= mixed_out;
      audio_out_right <= mixed_out;
    end
  end

endmodule
