module timer_core (
	input wire 	sys_clk,
	input wire 	sys_rst_n,

	// COntrols from Register
	input wire [3:0]	div_val,
	input wire		div_en,
	input wire 		timer_en,
	input wire 		timer_en_neg,
	input wire [63:0]	tcmp,
	input wire 		int_en,
	input wire 		int_clr_pulse,
	input wire		halt_req,

	//External Sidebands
	input wire		dbg_mode,
	output wire 		tim_int,

	//Status to Register
	output wire [63:0] 	count,
	output reg		int_st,
	output wire		halt_ack,

	//Direct bus writes from register
	input wire		tdr0_wr_en,
	input wire		tdr1_wr_en,
	input wire [31:0] 	tdr_wr_data,
	input wire [3:0]	tdr_wr_strb
);
// Hardware reset on disable
//	
	
	assign halt_ack = halt_req & dbg_mode;
	// Clock Divider
	//
	reg [7:0] limit;
	always@(*) begin
		case(div_val[3:0])
			4'b0001: limit = 8'd1;
			4'b0010: limit = 8'd3;
			4'b0011: limit = 8'd7;
			4'b0100: limit = 8'd15;
			4'b0101: limit = 8'd31;
			4'b0110: limit = 8'd63;
			4'b0111: limit = 8'd127;
			4'b1000: limit = 8'd255;
			default: limit = 8'd0;
		endcase
	end

	reg [7:0] cnt;
	wire cnt_rst = (cnt == limit) | (!timer_en) | (!div_en);
	wire [7:0] cnt_pre = halt_ack ? cnt	:
		cnt_rst ?  8'h00 :
		(cnt + 1'b1);

	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			cnt <=8'h0;
		end else begin
			cnt <= cnt_pre;
			end 
	end

	wire def_mode 		= timer_en & !div_en;
	wire ctrl_mode_0	= timer_en & div_en & (div_val == 4'h0);
	wire ctrl_mode_other	= timer_en & div_en & (div_val != 4'h0) & (cnt == limit);
	wire count_en		= (def_mode | ctrl_mode_0 | ctrl_mode_other) & !halt_ack;


	// 64 bit counter up
	//
	reg [31:0] tdr0;
	reg [31:0] tdr1;

	assign count = {tdr1, tdr0};
	wire [63:0] cnt_plus1 = count + 1'b1;
	
	wire [31:0] tdr0_pre;
	assign tdr0_pre[7:0] = (tdr0_wr_en & tdr_wr_strb[0]) 	? tdr_wr_data [7:0] :
				timer_en_neg			? 8'h0 	:
				count_en			? cnt_plus1[7:0] :
				tdr0 [7:0];


	assign tdr0_pre[15:8] = (tdr0_wr_en & tdr_wr_strb[1]) 	? tdr_wr_data [15:8] :
				timer_en_neg			? 8'h0 	:
				count_en			? cnt_plus1[15:8] :
				tdr0 [15:8];
	assign tdr0_pre[23:16] = (tdr0_wr_en & tdr_wr_strb[2]) 	? tdr_wr_data [23:16] :
				timer_en_neg			? 8'h0 	:
				count_en			? cnt_plus1[23:16] :
				tdr0 [23:16];
	assign tdr0_pre[31:24] = (tdr0_wr_en & tdr_wr_strb[3]) 	? tdr_wr_data [31:24] :
				timer_en_neg			? 8'h0 	:
				count_en			? cnt_plus1[31:24] :
				tdr0 [31:24];
	wire [31:0] tdr1_pre;
	assign tdr1_pre[7:0] = (tdr1_wr_en & tdr_wr_strb[0]) 	? tdr_wr_data [7:0] :
				timer_en_neg			? 8'h0 	:
				count_en			? cnt_plus1[39:32] :
				tdr1 [7:0];


	assign tdr1_pre[15:8] = (tdr1_wr_en & tdr_wr_strb[1]) 	? tdr_wr_data [15:8] :
				timer_en_neg			? 8'h0 	:
				count_en			? cnt_plus1[47:40] :
				tdr1 [15:8];
	assign tdr1_pre[23:16] = (tdr1_wr_en & tdr_wr_strb[2]) 	? tdr_wr_data [23:16] :
				timer_en_neg			? 8'h0 	:
				count_en			? cnt_plus1[55:48] :
				tdr1 [23:16];
	assign tdr1_pre[31:24] = (tdr1_wr_en & tdr_wr_strb[3]) 	? tdr_wr_data [31:24] :
				timer_en_neg			? 8'h0 	:
				count_en			? cnt_plus1[63:56] :
				tdr1 [31:24];

	always @(posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			tdr0 <= 32'h0000_0000;
			tdr1 <= 32'h0000_0000;
		end else begin
			tdr0 <= tdr0_pre;
			tdr1 <= tdr1_pre;
		end
	end

// Interrupt
	always@(posedge sys_clk or negedge sys_rst_n) begin
		if (!sys_rst_n) begin
			int_st <= 1'b0;
		end else begin
			if (int_clr_pulse) begin
				int_st <= 1'b0; // RW1C clear
			end else if (count == tcmp) begin
				int_st <= 1'b1;
			end
		end
	end

	assign tim_int = int_st && int_en;
endmodule

