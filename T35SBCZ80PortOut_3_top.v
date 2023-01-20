/************************************************************************
*   FILE:  T35SBCZ80PortOut_3_top.v   TFOX      Dec. 15, 2022           *
*                                                                       *
*   This project adds a very simple ROM memory to the basic Z80 soft    *
*   CPU to John Monahan's FPGA SBC board via Jeff Wilson's T35 board.   *
*                                                                       *
*   Sometimes this project does not function properly, and is still     *
*       being debugged.  Try resetting the SBC board if it appears      *
*       to be malfunctioning.  I believe this is related to the FAKED   *
*       S100 signals not being timed correctly, and pulse widths        *
*       being incorrect.  The ROMs @0000 seem to work fine, while the   *
*       ROMs @F000 seem to be somewhat unreliable.  Sorry about that!   *
*   There are four ROM file variations associated with this project.    *
*   PropOut_00rom.inithex:  Runs at 0000, sends "3" to propeller board  *
*       (runs OK at the fastest and slowest speeds)                     *
*   PortFF_00rom.inithex:   Runs at 0000, increments value to SBC LEDs  *
*       (only drives SBC LEDs properly at slow speed Address lines      *
*         A8-A5 do increment properly during an OUTPUT at fast speed    *
*   PropOut_F0rom.inithex:  Runs at F000, sends "3" to Propeller board  *
*       (Not working well at the moment)                                *
*   PortFF_F0rom.inithex:   Runs at F000, increments value to SBC LEDs  *
*       (Typically all the SBC LEDs will light up with a fast clock.    *
*       Running with a slow clock takes a while to get to the ROM       *
*   For the F000 ROMs, it takes a short time incrementing through       *
*       addresses to get to the ROM)                                    *
*                                                                       *
*       To use one of these ROMs, uncomment the proper inithex file     *
*       within the ROM declaration below, and make sure the other ROM   *
*       inithex files are commented out.                                *
*       the default rom.inithex uses the ROM at 0000, and Propeller out *
*   In addition, the MemAdrDecoder.v file needs to be changed,          *
*       depending on which rom location is being used. DON'T FORGET!!!  *
*                                                                       *    
*   this project can run a LOT slower so the user can see the proper    *
*       LEDs blinking on the address and other LEDs while               *
*       the project is running.  A clock multiplexer has been added to  *
*       the project, such that the clock speed can changed using the    *
*       IOBYTE switches 7 & 6.  Speeds 2MHz, 1MHz, 31kHz, or 244Hz are  *
*       available.                                                      *
*   NOTE: THIS PROJECT "FAKES" SEVERAL S-100 TO ALLOW FRONT PANEL AND   *
*   OTHER TEST BOARDS TO ALLOW ADDRESS AND DATA LINES TO SHOW ON LEDS.  *
*   THIS PROJECT DOES NOT CREATE PROPER S-100 COMPATIBLE SIGNALS        *
*   ONLY RUN/STOP work, not relaiable SINGLE STEPPING FOR NOW           *
*   NOTE: The Mini Front Panel Outut Port FF LEDs do NOT work properly  *
*     It gets D0-D7 thru the 16-pin MFP "IMSAI" connector               *
*   While debugging, I found it nice to see the cpu DATA IN and OUT     *
*       buses, so I added a simple mux for the "BAR" LEDs on the SBC    *
*       board. SW 5 & 4 determine what is being diplayed:               *
*           SW 5 and 4 down (OFF)=11=Port FF out, UP,DN (01) = Port FF  *
*           SW 5 & 4 DN,UP=(10)=DIN bus (rom), UP,UP (00)=DOUT bus      *
*       Board Active LED is used to display ROM select signal           *
*   Address LEDs for A0-A6 also light up in an incrementing fashion,    *
*       which is related to the Z80 refresh signal, and can be ignored  *
*   TFOX, N4TLF Oct. 12, 20222   You are free to use it                 *
*       however you like.  No warranty expressed or implied             *
************************************************************************/
// As built, this project is currently running at 0000, 
//  sending "3" to Propeller board port 01 by default

module  T35SBCZ80PortOut_3_top (
    pll0_LOCKED,        // PLL locked signal
    pll0_2MHz,          // 2MHz clock signal into project
    pll0_100MHz,        // FAST 100MHz clock to fix hanging
                        // Next comes all the S100 bus signals
    //    s100_boardReset_n,  // on SBC board reset button
    s100_xrdy,          // xrdy is S100 pin 3, on Mini Front Panel
                        // and Monahan Bus DIsplay Board (BDB)
    s100_rdy,           // second Ready signal, S100 pin
    //
    S100adr0_15,        // The regular 16 address bits
    S100adr16_19,       // Will increment for this test
    s100_DO,            // S100 SBC Data Out bus
   
    s100_pDBIN,         // NOTE:  This signal required for SMB or BDB
    s100_pSYNC,         // NOTE:  This signal required for SMB or BDB    
    s100_pSTVAL,        // NOTE:  This signal required for SMB or BDB
    s100_n_pWR,         // NOTE:  We don't need to write to anything
    s100_sMWRT,         // NOTE:  We don't need to write to anything
    s100_pHLDA,         // Only for the HLDA LED at this point
    s100_PHI,           // CPU Clock at whatever speed
    s100_sHLTA,         // S100 HALT Acknowledge OUT from Z80 CPU
    s100_sINTA,         // S100 Interrupt Acknowledge from Z80 CPU
    s100_n_sWO,         // S100 Status Write OUT (active LOW)
    s100_MEMR,          // S100 Memory READ signal (active high)
    s100_sINP,          // S100 INPUT signal (active high)
    s100_sOUT,          // S100 OUTPUT signal (active high)
    s100_sM1,           // S100 Status M1 signal from Z80 CPU
    s100_clock,         // 2MHz clock to S100 pin 49
    s100_PHANTOM,       // turn OFF Phantom LED on Front panels
    s100_ADSB,          // turn OFF these (ADSB & SDSB) LEDs on BDB
    s100_CDSB,          // turn OFF these LEDs on BDB
                    // Some of the SBC non-S100 output signals
    sw1_reset_n,        // L112 on V2 board reset to T35 board, active low
    SBC_LEDs,           // The SBC LEDs for testing
    sw_IOBYTE,          // I/O Byte Switches  NOT USED AS Z80 IOBYTE HERE!
    seg7,               // T35 seven segment display (active LOWs)
    seg7_dp,            // T35 seven segment decimal point (heartbeat)
    boardActive,        // Board Active LED (shows PLL Locked for now)
    F_add_oe,           // FPGA SBC board address buffers output enables
    F_bus_stat_oe,      // FPGA SBC board Status buffers output enables
    F_out_DO_oe,        // DON't FORGET THESE NEXT TIME!!!!!!
    F_out_DI_oe,        // DON'T FORGET THESE NEXT TIME!!!!!!
    F_bus_ctl_oe);      // FPGA SBC board Control buffers output enables
        
    input   sw1_reset_n;
    input   pll0_LOCKED;
    input   pll0_2MHz;
    input   pll0_100MHz;
    input   [7:0] sw_IOBYTE;
    input   s100_xrdy;
    input   s100_rdy;
    output  [15:0]S100adr0_15;
    output  [3:0] S100adr16_19;
    output  s100_pDBIN;
    output  s100_pSYNC; 
    output  s100_pSTVAL;
    output  s100_n_pWR;
    output  s100_sMWRT;
    output  s100_pHLDA;
    output  [7:0] s100_DO;
    output  s100_PHI;
    output  s100_sHLTA;
    output  s100_sINTA;
    output  s100_n_sWO;
    output  s100_MEMR;
    output  s100_sINP;
    output  s100_sOUT;
    output  s100_sM1;
    output  s100_clock;
    //
    output  [7:0] SBC_LEDs;
    output  [6:0] seg7;
    output  seg7_dp;
    output  s100_PHANTOM;       // turn OFF phantom light
    output  s100_ADSB;          // turn OFF these LEDs (ADSB & SDSB) on BDB
    output  s100_CDSB;          // turn OFF these LEDs on BDB
    output  boardActive;
    output  F_add_oe;
    output  F_bus_stat_oe;
    output  F_out_DO_oe;
    output  F_out_DI_oe;
    output  F_bus_ctl_oe;
    
///////////////////////////////////////////////////////////////////

    wire    twoMHzClock;
    wire    cpuClock;       // CPU clock wire (from counter[x])
    wire    n_m1;           // Z80 CPU M1 signal (active low)
    wire    n_mreq;         // Z80 CPU memory request (active low)
    wire    n_iorq;         // Z80 CPU IO request (active low)
    wire    n_rd;           // Z80 CPU READ signal (active low)
    wire    n_wr;           // Z80 CPU WRITE signal (active low)
    wire    n_rfsh;         // Z80 CPU REFRESH signal (active low)
    wire    n_halt;         // Z80 CPU HALT signal (active low) 
    wire    n_busak;        // Z80 CPU Bus Ack (HLDA) signal (active low)
    wire    z80_wait;       // Z80 CPU WAIT signal (active low)
    
    wire    [15:0]  cpuAddress; // Z80 CPU Address bus (A0-A15)
    wire    [7:0]   cpuDataOut; // Z80 CPU Data Output BUS (DO0-DO7)
    wire    [7:0]   cpuDataIn;  // Z80 CPU Data Input Bus (DI0-DI7)
    wire    [7:0]   romOut;     // ROM Data OUTPUT Bus
    wire    [7:0]   out255;     // Port 255 (FF hex) Output Bus
    wire    [7:0]   sw_IOBYTE;  // IOBYTE Switch data
    wire    n_reset;            // active low reset signal
    wire    z80rdy;             // Z80 ready signal
    wire    n_ioWR;             // I/O port WRITE signal
    wire    n_memWR;            // Memory WRITE signal
    wire    n_ioRD;             // I/O READ signal 
    wire    n_memRD;            // Memory READ signal
    wire    outFF;              // IO Port FF latch enable signal
    wire    rom_cs;             // ROM Chip Select signal

reg [26:0]  counter;            // 26-bit counter

assign twoMHzClock = pll0_2MHz;
assign  n_ioWR = n_wr | n_iorq;         // create I/O WRITE signal
assign  n_memWR = n_wr | n_mreq;        // create memory WRITE signal
assign  n_ioRD = n_rd | n_iorq;         // create I/O READ signal
assign  n_memRD = n_rd | n_mreq;        // create memory READ signal

assign n_reset = sw1_reset_n;
assign z80_wait = s100_xrdy & s100_rdy; // Z80 Wait = low to wait
assign S100adr0_15 = cpuAddress;        // connect S100 address lines
assign F_add_oe = 0;                    // enable SBC board address buffers
assign F_bus_stat_oe = 0;               // enable SBC board Status buffers
assign F_out_DO_oe = 0;                 // DON'T FORGET TO ENABLE THESE NEXT TIME!!!!
assign F_out_DI_oe = 0;                 // DON'T FORGET TO ENABLE THESE NEXT TIME!!!!
assign F_bus_ctl_oe = 0;                // enable SBC board Control buffers
assign S100adr16_19 = 4'b0;             // Z80 FPGA SBC only supports A16-A19

assign s100_sINTA = 0;                  // turn OFF Interrupt Ack
assign s100_n_sWO = 1;                  // turn OFF Status Write Out(active low)
assign s100_MEMR = !n_memRD;            // Set up S100 MEMR signal       
assign s100_PHANTOM = 0;                // turn OFF PHANTOM LED
assign s100_ADSB = 1;                   // turn OFF LED (active LOW)
assign s100_CDSB = 1;                   // turn OFF LED (active LOW)
assign s100_pHLDA = 0;                  // turn OFF LED (active HIGH)
assign s100_sHLTA = !n_halt;
assign s100_pDBIN = !n_rd;              // FAKED SIGNAL! Gets BDB to show Data IN bus
assign s100_pSYNC = cpuClock;           // FAKED SIGNAL! Gets BDB and MFP to Run/Stop
assign s100_pSTVAL = !cpuClock;         // FAKED SIGNAL! Gets BDB to show Addresses
assign s100_PHI = !cpuClock;            // only needed for Mini Front Panel
assign s100_clock = pll0_2MHz;          // Set the async clock to 2MHz
assign s100_sM1 = !n_m1;                 // connect the Z80 M1 (opcode fetch) line
assign s100_n_pWR = n_wr;               // connect the Z80 proc. WRITE line
assign s100_sMWRT = 1'b0;               // disable Status Memory Write signal
assign s100_sOUT = !n_ioWR;             // enable Status OUTPUT S100 signal
assign s100_sINP = !n_ioRD;             // enable Status INPUT S100 signal
assign s100_DO = cpuDataOut;            // connect S100 Data OUT bus signals

assign seg7 = 7'b0110000;           // The number "3", Top segment is LSB
assign seg7_dp = counter[20];       // seven segment decimal point is "heartbeat" 

assign boardActive = rom_cs;           // LED is LOW to turn ON

//////////////////////////////////////////////////////////////////////////
always @(posedge pll0_2MHz)             // set counter input to 2MHz from PLL0
    begin
        if(n_reset == 0) begin          // if reset set low...
            counter <= 27'b0;               // reset counter to 0
        end                             // end of resetting everything
        else
            counter <= counter + 1;     // increment counter
    end
    

////////////////////////////////////////////////////////////////////////////////
///////////     Z80 microcomputer module       (Z80 top module)             ////
///////////     NOTE that the internal CPU clock divider has been disabled  ////
////////////////////////////////////////////////////////////////////////////////
microcomputer(
		.n_reset    (n_reset),      // INPUT  LOW to reset
		.clk        (cpuClock),     // Z80 CPU clock input
		
		.n_wr       (n_wr),         // Z80 CPU WRITE signal out (active low)
		.n_rd       (n_rd),         // Z80 CPU READ signal out (active low)
		.n_mreq     (n_mreq),       // Z80 CPU MEMORY request out (active low)
		.n_iorq     (n_iorq),       // Z80 CPU IN/OUT request out (active low)
		.n_wait		(z80_wait),     // Z80 CPU WAIT (not ready) input signal (low)
        .n_int      (1'b1),         // Z80 CPU Interrupt IN (disabled here)
		.n_nmi      (1'b1),         // Z80 Non-Mask Interrupt IN (disabled here)
        .n_busrq    (1'b1),         // Z80 CPU Bus Rqst (HOLD) IN (disabled here)
        .n_m1       (n_m1),         // Z80 CPU M1 (instruction Fetch) OUT signal
        .n_rfsh     (n_rfsh),       // Z80 MEMORY REFRESH OUT signal (active low)
        .n_halt     (n_halt),       // Z80 CPU HALT (stopped) Ack OUT signal
		.n_busak    (n_busak),      // Z80 CPU HOLD OUT (bus disabled) (active low)
    
		.address    (cpuAddress),   // Z80 CPU 16-bit Address bus OUT
		.dataOut    (cpuDataOut),   // Z80 CPU 8-bit Data OUTPUT bus OUT
		.dataIn     (cpuDataIn)     // Z80 CPU 8-bit Data INPUT bus INPUT	
		);
        
/************************************************************************************
*   Memory decoder      Only enables ROM in Project 3                               *
************************************************************************************/     
memAdrDecoder  mem_cs(
    .address        (cpuAddress[15:4]),     // use only Z80 A3-A15 for now
    .n_memread     (n_memRD),               // Memory READ for ROM
    .rom_cs         (rom_cs)                // ROM chip select (enable) out
     );

/************************************************************************************
*   Boot ROM for Z80 CPU.  This is a VERY simple boot ROM, needing only 4 address   *
*                           lines.  ROM files MUST follow Efinity rules for it's    *
*                           modified HEX images.  Also, there is not a default      *
*                           enable/disable for output in the Efinity ROM, so its    *
*                           output is always enabled here.  The CPU DATA INPUT      *
*                           multiplexer is used to isolate ROM data out from the CPU*
************************************************************************************/     
rom   #(.ADDR_WIDTH(4),
	.RAM_INIT_FILE  ("PropOut_00rom.inithex"))  // default ROM at 0000, out Propeller
                            //("PortFF_00rom.inithex"))  //ROM @0000, Out port FF
                            //("PropOut_00rom.inithex"))  //ROM @ 0000, Out Prop
                            //("PortFF_F0rom.inithex")) // ROM @ F000, out port FF
                            //("PropOut_F0rom.inithex")) // ROM @ F000, out Prop        
    R1 (
    .address    (cpuAddress[3:0]),  // This ROM only needs addresses A0-A2
	.clock      (cpuClock),         //  Clock not really needed, but connected anyway
	.data       (romOut[7:0])       //  ROM DATA OUT to CPU DATA IN mux
    );

/************************************************************************************
*   CPU Data INPUT Multiplexer      Note: we cannot use tristate within the Efinity *
*                                       FPGAs, so a MUX is used instead.  Project 3 *
*                                       actually only has ONE Data to send to the   *
*                                       Z80, so this is here for future projects    *
************************************************************************************/
cpUDIMux    cpuInMux (
    .romData        (romOut[7:0]),      // ROM DATA OUT is the only data so far...
    .rom_cs         (rom_cs),           // if rom_cs is high, pass ROM data to CPU IN
    .pll0_100MHz    (pll0_100MHz),      // faster clock for always triggering
     .outData       (cpuDataIn[7:0])    // connect mux data output to CPU data IN bus
    );
 
/************************************************************************************
*    IO Ports Decoder.     The IO Ports decoder is only needed for Input/Output     *
*                           ports either in the T35 module, or on the Z80 FPGA SBC  *
*                           board.  Boards on the S100 bus do not need to be        *
*                           addressed here.  For Project 3, only the Output port    *
*                           255 (hex FF) SBC LEDs require to be addressed           * 
************************************************************************************/
portDecoder ports_cs(
    .address        (cpuAddress[7:0]),  // Only lower half CPU address for IO decoding
    .n_iowrite      (n_ioWR),           // Port I/O write signal    
    .outPortFF_cs   (outFF)             // 
    );

/************************************************************************************
*   S100 output Port 255 (0xFF) to Front Panel LEDs.    Output Port 255 latch       *
************************************************************************************/
n_bitReg    outPortFF(
     .load      (outFF),    // Output port 255 (FF hex) active high from port decoder
     .clock     (cpuClock),     // CPU clock for timing
     .clr       (!n_reset),     // Active high reset signal to clear LED latch 
     .inData    (cpuDataOut),   // Z80 CPU Data Output bus
     .regOut    (out255)        // register output to drive SBC LEDs
    );
   
/************************************************************************************
*   onboard LEDs INPUT Multiplexer.  This allows quick troubleshooting              *
*       Switches 5 & 4 select what the SBC LEDs display.  (these LEDs are also a    *
*           good place to scope internal FPGA signals if necessary.                 *
*       SW 5 & 4 = 00 (up up) displays the CPU Data OUT bus                         *
*       SW 5 & 4 = 01 (Up DN) displays the CPU Data IN bus                          *
*       SW 5 & 4 = 10 (DN UP) or 11 (DN DN) diplays Output Port 255 (FF hex)        *        
************************************************************************************/
LedBarMux       lmux(
    .cpuDO          (cpuDataOut [7:0]), // CPU Data OUT to SBC LEDs if selected
    .cpuDI          (cpuDataIn [7:0]),  // CPU Data IN to SBC LEDs if selected
    .portFFDO       (out255[7:0]),      // Output Port 255 Data In to LEDs if selected
    .sw             (sw_IOBYTE[5:4]),   // Switches 5 & 4 select what is sent to SBC LEDs
    .pll0_100MHz    (pll0_100MHz),      // faster clock for always triggering
    .LEDoutData     (SBC_LEDs)          // send Selected data to SBC LEDs
    );

/********************************************************************************
*   CPU Clock input Mux.  Selects one of four clock frequencies                 *
*       Switches 7 & 6 select which clock frequency the Z80 CPU uses.           *
*       SW 7 & 6 = 00 (UP UP) selects 244Hz clock to Z80 CPU                    *
*       SW 7 & 6 = 10 (DN UP) selects 31 kHz clock to Z80 CPU                   *
*       SW 7 & 6 = 01 (UP DN) selects 1 MHz clock to Z80 CPU                    *
*       SW 7 & 6 = 11 (DN DN) selects 2 MHz clock to Z80 CPU                    *
********************************************************************************/
ClockMux    ClkMux(
    .MHz2           (pll0_2MHz),        // 2 MHz clock input
    .MHz1           (counter[0]),       // 1 MHz clock input
    .KHz31          (counter[5]),       // 31 kHz clock input
    .Hz250          (counter[12]),      // 244 Hz clock input
    .pll0_100MHz    (pll0_100MHz),      // faster clock for always triggering
    .sw             (sw_IOBYTE[7:6]),   // switches that select clock speed 
    .cpuclk         (cpuClock)          // Clock MUX output to CPU Clock
    );

endmodule   
    
