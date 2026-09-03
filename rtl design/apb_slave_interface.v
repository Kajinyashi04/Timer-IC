module apb_slave_interface (
	input wire 	sys_clk,
	input wire	sys_rst_n,

	// APB bus signal
	input wire	tim_psel,
	input wire 	tim_penable,
	input wire	tim_pwrite,
	output wire 	tim_pready,
	output wire 	tim_pslverr,

	// Control 
	input wire 	error_detected,
	output wire 	bus_wr_en,
	output wire 	bus_rd_en
);
	reg wen;
	reg ren;
always @(posedge sys_clk or negedge sys_rst_n) begin
	if(!sys_rst_n) begin
		wen <= 1'b0;
		ren <= 1'b0;
	end else begin
			wen <= tim_psel & tim_pwrite & tim_penable & ~wen;
			ren <= tim_psel & ~tim_pwrite & tim_penable & ~ren;
	end
end

assign bus_wr_en = wen & !error_detected;
assign bus_rd_en = ren;
assign tim_pready = wen | ren;
assign tim_pslverr = error_detected && (wen | ren);



endmodule

