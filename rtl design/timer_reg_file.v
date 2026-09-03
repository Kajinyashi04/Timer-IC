module timer_reg_file (
	input wire 	sys_clk,
	input wire 	sys_rst_n,

	input wire	tim_pwrite,
	// APB interface
	input wire 	tim_psel,
	input wire 	tim_penable,
	input wire 	bus_wr_en,
	input wire	bus_rd_en,
	input wire [11:0] tim_paddr,
	input wire [31:0] tim_pwdata,
	input wire [3:0] tim_pstrb,
	output reg [31:0] tim_prdata,
	output wire 	error_detected,

	// Register ouput to core
	output reg [3:0] div_val,
	output reg 	div_en,
	output reg 	timer_en,
	output wire	timer_en_neg,
	output wire [63:0] tcmp,
	output reg 	int_en,
	output wire 	int_clr_pulse,
	output reg 	halt_req,

	// Status input from core
	input wire [63:0] count,
	input wire 	int_st,
	input wire	halt_ack,

	// Direct counter write to core (tdr0/1)
	output wire 	tdr0_wr_en,
	output wire 	tdr1_wr_en,
	output wire [31:0] 	tdr_wr_data,
	output wire [3:0]	tdr_wr_strb
);
	reg [31:0] tcmp0;
	reg [31:0] tcmp1;
	assign tcmp = {tcmp1, tcmp0};

//	wire is_tcr_sel = (tim_paddr == 12'h00);
//	wire is_tdr0_sel = (tim_paddr == 12'h04);
//	wire is_tdr1_sel = (tim_paddr == 12'h08);
//	wire is_tcmp0_sel = (tim_paddr == 12'h0C);
//	wire is_tcmp1_sel = (tim_paddr == 12'h10);
//	wire is_tier_sel = (tim_paddr == 12'h14);
//	wire is_tisr_sel = (tim_paddr == 12'h18);
//	wire is_thcsr_sel = (tim_paddr == 12'h1C);

	// Prohibited Access Checking
	wire is_tcr_sel = (tim_paddr == 12'h00);
	wire div_val_err = is_tcr_sel && (tim_pwdata[11:8] > 4'd8) && tim_pstrb[1];
	wire div_val_tim_en_err = is_tcr_sel && (tim_pwdata[11:8] != div_val) && tim_pstrb[1] && timer_en;
	wire div_en_tim_en_err = is_tcr_sel && (tim_pwdata[1] != div_en) && tim_pstrb[0] && timer_en;

	assign error_detected = tim_pwrite && (
				div_val_err || div_val_tim_en_err || div_en_tim_en_err
	);

	reg	timer_en_1d;
	always @(posedge sys_clk or negedge sys_rst_n) begin
		if (!sys_rst_n) begin
			timer_en_1d <= 1'b0;
		end else begin
			timer_en_1d <= timer_en;
		end
	end
	assign timer_en_neg = ~timer_en & timer_en_1d;

	// Register write logic with byte access
	always@(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			div_val <=4'b0001;
			div_en <= 1'b0;
			timer_en <= 1'b0;
			tcmp0 <= 32'hFFFF_FFFF;
			tcmp1 <= 32'hFFFF_FFFF;
			int_en <= 1'b0;
			halt_req <= 1'b0;
		end else if (bus_wr_en) begin
			// TCR
			if (tim_paddr == 12'h00) begin
				if (tim_pstrb[1]) div_val <= tim_pwdata [11:8];
				if (tim_pstrb[0]) begin
					div_en <= tim_pwdata[1];
					timer_en <= tim_pwdata[0];

				end
			end
			//TCMP0
			if (tim_paddr == 12'h0C) begin
				if(tim_pstrb[0]) tcmp0[7:0] <= tim_pwdata[7:0];
				if(tim_pstrb[1]) tcmp0[15:8] <= tim_pwdata[15:8];
				if(tim_pstrb[2]) tcmp0[23:16] <= tim_pwdata[23:16];
				if(tim_pstrb[3]) tcmp0[31:24] <= tim_pwdata[31:24];
			end

			//TCMP1
			if (tim_paddr == 12'h10) begin
				if(tim_pstrb[0]) tcmp1[7:0] <= tim_pwdata[7:0];
				if(tim_pstrb[1]) tcmp1[15:8] <= tim_pwdata[15:8];
				if(tim_pstrb[2]) tcmp1[23:16] <= tim_pwdata[23:16];
				if(tim_pstrb[3]) tcmp1[31:24] <= tim_pwdata[31:24];
			end

			//TIER
			if (tim_paddr == 12'h14) begin
				if (tim_pstrb[0]) int_en <= tim_pwdata[0];
			end
			//THCSR
			if (tim_paddr == 12'h1C) begin
				if(tim_pstrb[0]) halt_req <= tim_pwdata[0];
			end
		end
	end

//RW1C pulse to clearing interrupt TISR
	assign int_clr_pulse = bus_wr_en && (tim_paddr == 12'h18) && tim_pstrb[0] && tim_pwdata[0];

	//Interface signal forward write to TDR0/1 in core.v
	assign tdr0_wr_en = bus_wr_en && (tim_paddr == 12'h04);
	assign tdr1_wr_en = bus_wr_en && (tim_paddr == 12'h08);
	assign tdr_wr_data = tim_pwdata;
	assign tdr_wr_strb = tim_pstrb;


	// Register mapping
	always @(*) begin
		if (tim_psel && tim_penable && !tim_pwrite) begin
			case(tim_paddr)
				12'h00: tim_prdata = {20'h0, div_val, 6'h0, div_en, timer_en}; // TCR
				12'h04: tim_prdata = count[31:0]; // TDR0
				12'h08: tim_prdata = count[63:32]; //TDR1
				12'h0C: tim_prdata = tcmp0;
				12'h10: tim_prdata = tcmp1;
				12'h14: tim_prdata = {31'h0, int_en}; //TIER
				12'h18: tim_prdata = {31'h0, int_st}; //TISR
				12'h1C: tim_prdata = {30'h0, halt_ack, halt_req};//THCSR
				default: tim_prdata = 32'h0000_0000;
			endcase
		end else begin
			tim_prdata = 32'h0000_0000;
		end
	end	
endmodule

