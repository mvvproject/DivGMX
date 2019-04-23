// Modified for DivGMX rev.A By MVV (build 20161224)

// ====================================================================
//                Radio-86RK FPGA REPLICA
//
//            Copyright (C) 2011 Dmitry Tselikov
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Radio-86RK home computer
//
// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
// 
// Minor changes for adaptation to SDRAM: Ivan Gorodetsky, 2014
// 
// Port to Reverse-U16: Andy Karpov, 2016
// Port to DivGMX: Vlad Matlash, 2016
//
// Design File: rk86.v
//
// Top level design file.

module rk86(
	// Clock
	input		CLK_50MHZ,
	// SDRAM
	inout	[7:0] 	DRAM_DQ,
	output	[12:0] 	DRAM_A,
	output		DRAM_DQM,
	output		DRAM_NWE,
	output		DRAM_NCAS,
	output		DRAM_NRAS,
	output	[1:0]	DRAM_BA,
	output		DRAM_CLK,
	// ZXBUS
//	input		BUF_NINT,
	input		BUF_NNMI,
//	input		BUF_NRESET,
//	output	[1:0]	BUF_DIR,
//	inout		BUS_CLK,
//	inout	[7:0]	BUS_D,
//	inout	[15:0]	BUS_A,
//	inout		BUS_NMREQ,
//	inout		BUS_NIORQ,
//	inout		BUS_NBUSACK,
//	inout		BUS_NRD,
//	inout		BUS_NWR,
//	inout		BUS_NM1,
//	inout		BUS_NRFSH,
//	output		BUS_NINT,
//	output		BUS_NWAIT,
//	output		BUS_NBUSRQ,
//	output		BUS_NROMOE,
//	output		BUS_NIORQGE,
	// USB Host (VNC2-32)
	input		USB_TXD,
	input		USB_IO3,
	// I2C (HDMI/RTC)
//	inout		I2C_SCL,
//	inout		I2C_SDA,
	// SD
//	input		SD_NDET,
	output		SD_NCS,		// SD Card Data 3 		(CSn)
	// SPI (W25Q64/SD)
	input		DATA0,		// SD Card Data 		(MISO)
	output		ASDO,		// SD Card Command Signal 	(MOSI)
	output		DCLK,		// SD Card Clock 		(SCK)
	output		NCSO,
	// Audio
	output		OUT_L,
	output		OUT_R,
	// HDMI
	output	[7:0]	TMDS
);

// CLOCK
wire clk50mhz;
wire clk250mhz;
wire clock_locked;

clk clock(
	.inclk0		(CLK_50MHZ),
	.c0		(clk250mhz),
	.c1		(clk50mhz),
	.locked		(clock_locked));

wire VGA_HS;
wire VGA_VS;
wire VGA_R;
wire VGA_G;
wire VGA_B;
wire BEEP;

assign OUT_L = BEEP;
assign OUT_R = BEEP;

assign NCSO = 1'b1;



// RESET
wire reset = !clock_locked || !BUF_NNMI || k_reset;

// MEMORY
wire[7:0] rom_o;
wire[7:0] dramout;

sdram ramd(
	.I_CLK		(clk50mhz),
	.I_ADDR		(vid_rd ? {3'b000000,vid_addr[14:0]} : {3'b000000,addrbus[14:0]}),
	.I_DATA		(cpu_o),
	.O_DATA		(dramout),
	.I_WR		(vid_rd ? 1'b0 : !(cpu_wr_n | addrbus[15])),
	.I_RD		(vid_rd ? 1'b1 : cpu_rd & (!addrbus[15])),
	.I_RFSH		(1'b1),
	.O_CLK		(DRAM_CLK),
	.O_RAS		(DRAM_NRAS),
	.O_CAS		(DRAM_NCAS),
	.O_WE		(DRAM_NWE),
	.O_DQM		(DRAM_DQM),
	.O_BA		(DRAM_BA),
	.O_MA		(DRAM_A),
	.IO_DQ		(DRAM_DQ) );

wire[7:0] mem_o = dramout[7:0];

biossd rom(
	.address	({addrbus[11]|startup,addrbus[10:0]}),
	.clock		(clk50mhz),
	.q		(rom_o));

// CPU
wire[15:0] addrbus;
wire[7:0] cpu_o;
wire cpu_sync;
wire cpu_rd;
wire cpu_wr_n;
wire cpu_int;
wire cpu_inta_n;
wire inte;
reg[7:0] cpu_i;
reg startup;

always @(*)
	casex (addrbus[15:13])
	3'b0xx: cpu_i = startup ? rom_o : mem_o;
	3'b100: cpu_i = ppa1_o;
	3'b101: cpu_i = sd_o;
	3'b110: cpu_i = crt_o;
	3'b111: cpu_i = rom_o;
	endcase

wire ppa1_we_n = addrbus[15:13]!=3'b100|cpu_wr_n;
wire ppa2_we_n = addrbus[15:13]!=3'b101|cpu_wr_n;
wire crt_we_n  = addrbus[15:13]!=3'b110|cpu_wr_n;
wire crt_rd_n  = addrbus[15:13]!=3'b110|~cpu_rd;
wire dma_we_n  = addrbus[15:13]!=3'b111|cpu_wr_n;

reg[4:0] cpu_cnt;
reg cpu_ce2;
reg[10:0] hldareg;
wire cpu_ce = cpu_ce2;

always @(posedge clk50mhz) begin
	if(reset) begin cpu_cnt<=0; cpu_ce2<=0; hldareg=11'd0; end
	else
   if((hldareg[10:9] == 2'b01) && ((cpu_rd == 1) || (cpu_wr_n == 0))) begin cpu_cnt <= 0; cpu_ce2 <= 1; end
	else
	if(cpu_cnt < 27) begin cpu_cnt <= cpu_cnt + 5'd1; cpu_ce2 <= 0; end
	else begin cpu_cnt <= 0; cpu_ce2 <= ~hlda; end
	hldareg <= {hldareg[9:0],hlda};
	startup <= reset|(startup&~addrbus[15]);
end

k580wm80a CPU(
	.clk		(clk50mhz),
	.ce		(cpu_ce),
	.reset		(reset),
	.idata		(cpu_i),
	.addr		(addrbus),
	.sync		(cpu_sync),
	.rd		(cpu_rd),
	.wr_n		(cpu_wr_n),
	.intr		(cpu_int),
	.inta_n		(cpu_inta_n),
	.odata		(cpu_o),
	.inte_o		(inte));

// VIDEO
wire[7:0] crt_o;
wire[3:0] vid_line;
wire[6:0] vid_char;
wire[15:0] vid_addr;
wire[3:0] dma_dack;
wire[7:0] dma_o;
wire[1:0] vid_lattr;
wire[1:0] vid_gattr;
wire vid_cce,vid_drq,vid_irq,hlda;
wire vid_lten,vid_vsp,vid_rvv,vid_hilight;
wire dma_owe_n,dma_ord_n,dma_oiowe_n,dma_oiord_n;
wire vid_hr, vid_vr;
wire vid_rd = ~dma_oiord_n;
wire[10:0] vga_counter_x;
wire[10:0] vga_counter_y;
wire vga_blank;

k580wt57 dma(
	.clk		(clk50mhz),
	.ce		(vid_cce),
	.reset		(reset),
	.iaddr		(addrbus[3:0]),
	.idata		(cpu_o),
	.drq		({1'b0,vid_drq,2'b00}),
	.iwe_n		(dma_we_n),
	.ird_n		(1'b1),
	.hlda		(hlda),
	.hrq		(hlda),
	.dack		(dma_dack),
	.odata		(dma_o),
	.oaddr		(vid_addr),
	.owe_n		(dma_owe_n),
	.ord_n		(dma_ord_n),
	.oiowe_n	(dma_oiowe_n),
	.oiord_n	(dma_oiord_n));

k580wg75 crt(
	.clk		(clk50mhz),
	.ce		(vid_cce),
	.iaddr		(addrbus[0]),
	.idata		(cpu_o),
	.iwe_n		(crt_we_n),
	.ird_n		(crt_rd_n),
	.vrtc		(vid_vr), 
	.hrtc		(vid_hr),
	.dack		(dma_dack[2]),
	.ichar		(mem_o),
	.drq		(vid_drq),
	.irq		(vid_irq),
	.odata		(crt_o),
	.line		(vid_line),
	.ochar		(vid_char),
	.lten		(vid_lten),
	.vsp		(vid_vsp),
	.rvv		(vid_rvv),
	.hilight	(vid_hilight),
	.lattr		(vid_lattr),
	.gattr		(vid_gattr));
	
rk_video vid(
	.clk		(clk50mhz), 
	.hr		(VGA_HS),
	.vr		(VGA_VS), 
	.r		(VGA_R),
	.g		(VGA_G),
	.b		(VGA_B),
	.hr_wg75	(vid_hr),
	.vr_wg75	(vid_vr),
	.cce		(vid_cce),
	.line		(vid_line),
	.ichar		(vid_char),
	.vsp		(vid_vsp),
	.lten		(vid_lten),
	.rvv		(vid_rvv),
	.counter_x	(vga_counter_x),
	.counter_y	(vga_counter_y),
	.blank		(vga_blank));

// KBD
wire[7:0] kbd_o;
wire[2:0] kbd_shift;
wire k_reset;

deserializer kbd(
	.I_CLK		(clk50mhz),
	.I_RESET	(!BUF_NNMI),
	.I_RX		(USB_TXD),
	.I_NEWFRAME	(USB_IO3),
	.I_ADDR		(ppa1_a),
	.O_DATA		(kbd_o),
	.O_SHIFT	(kbd_shift),
	.O_K_RESET	(k_reset));

assign USB_NCS = 1'b0;
	
// SYS PPA
wire[7:0] ppa1_o;
wire[7:0] ppa1_a;
wire[7:0] ppa1_b;
wire[7:0] ppa1_c;

k580ww55 ppa1(
	.clk		(clk50mhz),
	.reset		(reset),
	.addr		(addrbus[1:0]),
	.we_n		(ppa1_we_n),
	.idata		(cpu_o),
	.odata		(ppa1_o),
	.ipa		(ppa1_a),
	.opa		(ppa1_a),
	.ipb		(kbd_o),
	.opb		(ppa1_b),
	.ipc		({kbd_shift,tapein,ppa1_c[3:0]}),
	.opc		(ppa1_c));

// SOUND
reg tapein;

soundcodec sound(
	.clk		(clk50mhz),
	.pulse		(ppa1_c[0]^inte),
	.o_pwm		(BEEP));

// SD CARD
reg sdcs;
reg sdclk;
reg sdcmd;
reg[6:0] sddata;
wire[7:0] sd_o = {sddata, DATA0};

assign SD_NCS = ~sdcs;
assign ASDO = sdcmd;
assign DCLK = sdclk;

always @(posedge clk50mhz or posedge reset) begin
	if (reset) begin
		sdcs <= 1'b0;
		sdclk <= 1'b0;
		sdcmd <= 1'h1;
	end else begin
		if (addrbus[0]==1'b0 && ~ppa2_we_n) sdcs <= cpu_o[0];
		if (addrbus[0]==1'b1 && ~ppa2_we_n) begin
			if (sdclk) sddata <= {sddata[5:0],DATA0};
			sdcmd <= cpu_o[7];
			sdclk <= 1'b0;
		end
		if (cpu_rd) sdclk <= 1'b1;
	end
end

// HDMI
hdmi #(
	.FREQ		(50000000),	// pixel clock frequency = 50.0MHz
	.FS		(48000),	// audio sample rate - should be 32000, 41000 or 48000 = 48KHz
	.CTS		(50000),	// CTS = Freq(pixclk) * N / (128 * Fs)
	.N		(6144))		// N = 128 * Fs /1000,  128 * Fs /1500 <= N <= 128 * Fs /300 (Check HDMI spec 7.2 for details)

hdmi (
	.I_CLK_VGA	(clk50mhz),
	.I_CLK_TMDS	(clk250mhz),
	.I_HSYNC	(VGA_HS),
	.I_VSYNC	(VGA_VS),
	.I_BLANK	(vga_blank),
	.I_RED		({VGA_R,VGA_R,VGA_R,VGA_R,VGA_R,VGA_R,VGA_R,VGA_R}),
	.I_GREEN	({VGA_G,VGA_G,VGA_G,VGA_G,VGA_G,VGA_G,VGA_G,VGA_G}),
	.I_BLUE		({VGA_B,VGA_B,VGA_B,VGA_B,VGA_B,VGA_B,VGA_B,VGA_B}),
	.I_AUDIO_PCM_L 	({ppa1_c[0]^inte,15'b0}),
	.I_AUDIO_PCM_R	({ppa1_c[0]^inte,15'b0}),
	.O_TMDS		(TMDS));

endmodule
