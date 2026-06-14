// Frequency divider
`define SSD_SCAN_CTL_BIT_WIDTH 2 // number of bits for ftsd scan control
`define FREQ_DIV_BIT 27

// SSD scan
`define SSD_DIGIT_NUM 4              // number of SSD digit
`define SSD_SCAN_CTL_DISP1 4'b0111   // set the value of SSD 1
`define SSD_SCAN_CTL_DISP2 4'b1011   // set the value of SSD 2
`define SSD_SCAN_CTL_DISP3 4'b1101   // set the value of SSD 3
`define SSD_SCAN_CTL_DISP4 4'b1110   // set the value of SSD 4
`define SSD_SCAN_CTL_DISPALL 4'b0000 // set the value of SSD to ALL

// 7-segment display
`define SSD_BIT_WIDTH 8     // 7-segment display control
`define SSD_NUM 4           //number of 7-segment display
`define SSD_ZERO   `SSD_BIT_WIDTH'b0000_0011 // 0
`define SSD_ONE    `SSD_BIT_WIDTH'b1001_1111 // 1
`define SSD_TWO    `SSD_BIT_WIDTH'b0010_0101 // 2
`define SSD_THREE  `SSD_BIT_WIDTH'b0000_1101 // 3
`define SSD_FOUR   `SSD_BIT_WIDTH'b1001_1001 // 4
`define SSD_FIVE   `SSD_BIT_WIDTH'b0100_1001 // 5
`define SSD_SIX    `SSD_BIT_WIDTH'b0100_0001 // 6
`define SSD_SEVEN  `SSD_BIT_WIDTH'b0001_1111 // 7
`define SSD_EIGHT  `SSD_BIT_WIDTH'b0000_0001 // 8
`define SSD_NINE   `SSD_BIT_WIDTH'b0000_1001 // 9

`define SSD_A   `SSD_BIT_WIDTH'b0001_0001 // A
`define SSD_b   `SSD_BIT_WIDTH'b1100_0001 // b
`define SSD_c   `SSD_BIT_WIDTH'b1110_0101 // c
`define SSD_d   `SSD_BIT_WIDTH'b1000_0101 // d
`define SSD_E   `SSD_BIT_WIDTH'b0110_0001 // E
`define SSD_F   `SSD_BIT_WIDTH'b0111_0001 // F

`define SSD_NULL `SSD_BIT_WIDTH'b1111_1111
`define SSD_DEF  `SSD_BIT_WIDTH'b0000_0000 // default, all LEDs being lighted

// BCD counter
`define BCD_BIT_WIDTH 4     // BCD bit width
`define ENABLED 1           // ENABLE indicator
`define DISABLED 0          // EIDABLE indicator
`define INCREMENT 1'b1      // increase by 1
`define BCD_ZERO 4'd0       // 0 for BCD
`define BCD_ONE 4'd1        // 1 for BCD
`define BCD_TWO 4'd2        // 2 for BCD
`define BCD_THREE 4'd3      // 4 for BCD
`define BCD_FOUR 4'd4       // 4 for BCD
`define BCD_FIVE 4'd5       // 5 for BCD
`define BCD_SIX 4'd6        // 6 for BCD
`define BCD_SEVEN 4'd7      // 7 for BCD
`define BCD_EIGHT 4'd8      // 8 for BCD
`define BCD_NINE 4'd9       // 9 for BCD
`define BCD_NULL 4'd15      // all 1
