module timer_top (
	input wire 		sys_clk,
	input wire		sys_rst_n,

	//APB slave interface
	input wire		tim_psel,
	input wire		tim_penable,
	input wire 		tim_pwrite,
	input wire [11:0]	tim_paddr,
	input wire [31:0]	tim_pwdata,
	input wire [3:0] 	tim_pstrb,
	output wire [31:0]	tim_prdata,
	output wire 		tim_pready,
	output wire 		tim_pslverr,

	//External
	output wire 		tim_int,
	input wire 		dbg_mode
);

	// Internal interconnect
	wire		error_detected;
	wire		bus_wr_en;
	wire 		bus_rd_en;

	wire [3:0]	div_val;
	wire		div_en;
	wire		timer_en;
	wire 		timer_en_neg;
	wire [63:0] 	tcmp;
	wire 		int_en;
	wire		int_clr_pulse;
	wire		halt_req;
	
	wire [63:0]	count;
	wire 		int_st;
	wire		halt_ack;

	wire 		tdr0_wr_en;
	wire		tdr1_wr_en;
	wire [31:0]	tdr_wr_data;
	wire [3:0]	tdr_wr_strb;


	// APB protocol
	apb_slave_interface u_apb_slave (
		.sys_clk		(sys_clk),
		.sys_rst_n		(sys_rst_n),
		.tim_psel		(tim_psel),
		.tim_penable		(tim_penable),
		.tim_pwrite		(tim_pwrite),
		.tim_pready		(tim_pready),
		.tim_pslverr		(tim_pslverr),
		.error_detected 	(error_detected),
		.bus_wr_en		(bus_wr_en),
		.bus_rd_en		(bus_rd_en)
	);

	timer_reg_file u_reg_file (
		.sys_clk 		(sys_clk),
		.sys_rst_n		(sys_rst_n),
		.bus_wr_en		(bus_wr_en),
		.bus_rd_en		(bus_rd_en),
		.tim_psel		(tim_psel),
		.tim_penable		(tim_penable),
		.tim_pwrite		(tim_pwrite),
		.tim_paddr 		(tim_paddr),
		.tim_pwdata		(tim_pwdata),
		.tim_pstrb		(tim_pstrb),
		.tim_prdata		(tim_prdata),
		.error_detected		(error_detected),
		.div_val		(div_val),
		.div_en			(div_en),
		.timer_en		(timer_en),
		.timer_en_neg		(timer_en_neg),
		.tcmp			(tcmp),
		.int_en			(int_en),
		.int_clr_pulse		(int_clr_pulse),
		.halt_req		(halt_req),
		.count			(count),
		.int_st			(int_st),
		.halt_ack		(halt_ack),
		.tdr0_wr_en		(tdr0_wr_en),
		.tdr1_wr_en		(tdr1_wr_en),
		.tdr_wr_data		(tdr_wr_data),
		.tdr_wr_strb		(tdr_wr_strb)
	);
	timer_core u_core (
		.sys_clk		(sys_clk),
		.sys_rst_n		(sys_rst_n),
		.div_val		(div_val),
		.div_en			(div_en),
		.timer_en		(timer_en),
		.timer_en_neg		(timer_en_neg),
		.tcmp			(tcmp),
		.int_en			(int_en),
		.int_clr_pulse		(int_clr_pulse),
		.halt_req		(halt_req),
		.dbg_mode		(dbg_mode),
		.tim_int		(tim_int),
		.count			(count),
		.int_st			(int_st),
		.halt_ack		(halt_ack),
		.tdr0_wr_en		(tdr0_wr_en),
		.tdr1_wr_en		(tdr1_wr_en),
		.tdr_wr_data		(tdr_wr_data),
		.tdr_wr_strb		(tdr_wr_strb)
	);

	endmodule

