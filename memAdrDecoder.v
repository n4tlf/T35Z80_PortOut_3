/****************************************************************************
*   File:   memAdrDecoder.V     TFOX    Ver 0.1     Oct. 12, 2022           *
*   Memory Address Decoder  For Monanahan S100 Z80 FPGA SBC                 *                                    
*       This is for a VERY BASIC ROM, It only verifies OUTPUT instruction   *
*       works.  Only a total of 16 bytes can be used with this decoder      *
*                                                                           *
*   There are two sets of test ROMs, one set runs at 0x0000, the other set  *
*       at 0xF000.  Uncomment the one you want, and comment out the         *
*       assign statement that you don't want to use                         *
*   TFOX, N4TLF S Oct. 12, 2022   You are free to use it                    *
*       however you like.  No warranty expressed or implied                 *
****************************************************************************/

module memAdrDecoder
    (
    input [15:4]    address,        // use only Z80 address A0-A15 for now
    input           n_memread,      // memory READ signal, active LOW
    output          rom_cs          // Active high ROM Chip Select signal
     );

//  This TEST ROM is in memory location, 0000 
    assign rom_cs = (address[15:4] == 12'b0) && !n_memread;  
                                            // rom_cs is high to select ROM
//  For TEST ROM located at F000, normal location for John Monahan's ROMs
//    assign rom_cs = (address[15:4] == 12'b111100000000) && !n_memread;  
 
                                            // rom_cs is high to select ROM

endmodule
