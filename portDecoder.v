/************************************************************************
*   File:  portDecoder.v    TFOX    Ver 0.1     Oct.12, 2022            *
*           Z80 CPU IN/OUT port Decoder.  This version only uses A0-A7  *
************************************************************************/

module portDecoder
    (
//    input     clock,        // Clock input not needed so far
    input [7:0] address,         // Only use A0-A7 with the Z80
    input       n_iowrite,      // In/Out WRITE signal
    output      outPortFF_cs   // Only OUT Port 255 (FF hex) in Proj 3
    );

    assign outPortFF_cs = (address[7:0] == 8'b11111111) && !n_iowrite;

    endmodule
