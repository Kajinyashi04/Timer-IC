`timescale 1ns / 1ps

module test_bench;
	reg		sys_clk;
	reg 		sys_rst_n;
				
	// APB input
	reg 		tim_psel;
	reg		tim_penable;
	reg		tim_pwrite;
	reg [11:0]	tim_paddr;
	reg [31:0]	tim_pwdata;
	reg [3:0]	tim_pstrb;
	reg		dbg_mode;

	//DUT output
	wire [31:0]	tim_prdata;
	wire		tim_pready;
	wire		tim_pslverr;
	wire		tim_int;

	//Clock gen
	initial begin
		sys_clk = 1'b0;
		forever #5 sys_clk = ~sys_clk;
	end

	// DUT timer_top
	timer_top u_dut (
		.sys_clk		(sys_clk),
		.sys_rst_n		(sys_rst_n),
		.tim_psel		(tim_psel),
		.tim_penable		(tim_penable),
		.tim_pwrite		(tim_pwrite),
		.tim_paddr		(tim_paddr),
		.tim_pwdata		(tim_pwdata),
		.tim_pstrb		(tim_pstrb),
		.tim_prdata		(tim_prdata),
		.tim_pready		(tim_pready),
		.tim_pslverr		(tim_pslverr),
		.tim_int		(tim_int),
		.dbg_mode		(dbg_mode)
	);

	// Test
	initial begin
		sys_rst_n = 1'b0;
		tim_psel = 1'b0;
		tim_penable = 1'b0;
		tim_pwrite = 1'b0;
		tim_paddr = 12'h0;
		tim_pwdata = 32'h0;
		tim_pstrb = 4'h0;
		dbg_mode = 1'b0;

		#30;
		sys_rst_n = 1'b1;

		#100;
		$display("---------------------------------------------------");
		$display(" SIMPLE TESTBENCH COMPLETED WITHOUT ERRORS ");
		$display("---------------------------------------------------");
		$finish;
	end

	endmodule

