module entity_renderer (
    input logic clk,
    input logic rst_n,

    // vga ctrl
    input logic [9:0]  show_x, show_y,

    // dist buffer comm
    input logic [15:0] wall_dist,

    // manager comm
    input oam_entry_t oam_data [0:7],

    // tex rom comm
    input logic [11:0] tex_rgb,
    output logic [11:0] tex_addr,

    // vga out
    output logic [11:0] entity_rgb_out,
    output logic entity_draw_en
  );

  localparam logic [11:0] TP_COLOR = 12'hF0F; // Magic Pink

  logic signed [15:0] show_x_temp, show_y_temp;

  // Parallel calculation arrays
  logic signed [15:0] show_dx [0:7];
  logic signed [15:0] show_dy [0:7];
  logic signed [31:0] tex_dx [0:7];
  logic signed [31:0] tex_dy [0:7];
  logic signed [15:0] tex_x [0:7];
  logic signed [15:0] tex_y [0:7];
  logic [7:0] boxed;

  // boxed chk
  always_comb
  begin
    show_x_temp = signed'({6'b0, show_x});
    show_y_temp = signed'({6'b0, show_y});
    for (int i = 0; i < 8; i++)
    begin
      if (oam_data[i].valid)
      begin
        show_dx[i] = show_x_temp - oam_data[i].screen_x;
        show_dy[i] = show_y_temp - oam_data[i].screen_y;
        tex_dx[i] = show_dx[i] * $signed({17'b0, oam_data[i].step});
        tex_dy[i] = show_dy[i] * $signed({17'b0, oam_data[i].step});
        tex_x[i] = 16'sd32 + tex_dx[i][23:8];
        tex_y[i] = 16'sd32 + tex_dy[i][23:8];
        boxed[i] = (tex_x[i] >= 0) && (tex_x[i] < 64) && (tex_y[i] >= 0) && (tex_y[i] < 64);
      end
      else
      begin
        show_dx[i] = 16'sd0;
        show_dy[i] = 16'sd0;
        tex_dx[i] = 32'sd0;
        tex_dy[i] = 32'sd0;
        tex_x[i] = 16'sd0;
        tex_y[i] = 16'sd0;
        boxed[i] = 1'b0;
      end
    end
  end

  // depth sort (find top layer entity)
  logic [2:0] id_min;
  logic [15:0] dist_min;
  logic entity_hit;
  always_comb
  begin
    dist_min = 16'hFFFF;
    id_min  = 3'd0;
    entity_hit = 1'b0;
    for (int i = 0; i < 8; i++)
    begin
      if (boxed[i] && (oam_data[i].dist < dist_min))
      begin
        dist_min = oam_data[i].dist;
        id_min  = i[2:0];
        entity_hit = 1'b1;
      end
    end
  end

  // addr req
  logic layer_buff_next;
  always_comb
  begin
    tex_addr = 12'h000;
    layer_buff_next = 1'b0;
    if (entity_hit)
    begin
      if (dist_min < wall_dist)
      begin
        layer_buff_next = 1'b1;
        tex_addr = {tex_y[id_min][5:0], tex_x[id_min][5:0]};
      end
    end
  end

  // delay for rom read
  logic layer_buff;
  always_ff @(posedge clk)
  begin
    if (~rst_n)
      layer_buff <= 1'b0;
    else
      layer_buff <= layer_buff_next;
  end

  always_comb
  begin
    entity_draw_en = 1'b0;
    entity_rgb_out = 12'h000;
    if (layer_buff)
    begin
      if (tex_rgb != TP_COLOR)
      begin
        entity_draw_en = 1'b1;
        entity_rgb_out = tex_rgb;
      end
    end
  end

endmodule
