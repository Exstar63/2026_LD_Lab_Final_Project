module map_rom (
    input  logic clk,
    input  logic [3:0] map_x,
    input  logic [3:0] map_y,
    output logic hit // 1 if wall, 0 if empty
  );

  // 256 addresses (16x16), each holding 1 bit of data
  (* ram_style = "block" *)
  logic world_map [0:255];

  initial
  begin
    // test map (16*16)
    world_map = {
                1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1,
                1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1,
                1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1,
                1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1,

                1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1,
                1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1,
                1,0,0,0, 0,0,1,1, 1,1,0,0, 0,0,0,1,
                1,0,0,0, 0,0,1,0, 0,1,0,0, 0,0,0,1,

                1,0,0,0, 0,0,1,0, 0,1,0,0, 0,0,0,1,
                1,0,0,0, 0,0,1,1, 1,1,0,0, 0,0,0,1,
                1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1,
                1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1,

                1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1,
                1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1,
                1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1,
                1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1,
              };
    // A '1' is a wall, a '0' is empty space
    // $readmemb("map_data.mem", world_map);
  end

  always_ff @(posedge clk)
  begin
    // Concatenate Y and X to form the 8-bit address
    // Assuming Y is the row and X is the column
    hit <= world_map[{map_y, map_x}];
  end

endmodule
