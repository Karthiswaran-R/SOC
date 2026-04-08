module watchdog_timer_apb_wrapper (
    input         PCLK,
    input         PRESETn,
    input PSEL,
    input  [31:0]  PADDR,
    input  [31:0] PWDATA,
    output reg [31:0] PRDATA,

    input         PWRITE,
    input         PENABLE,
    output        PREADY,

    output reg    PSLVERR
);
wire wr_en;
wire rd_en;

assign wr_en = PSEL && PENABLE && PWRITE ;
assign rd_en = PSEL && PENABLE && !PWRITE ;

assign PSLVRR =1'b0;
assign PREADY =1'b1;
watchdog_timer uut(
	.clk(PCLK),
	.rst_n (PRESTn),
	.addr(PADDR),
	.wdata(PWDATA),
	.rdata(PRDATA),
	.write_en(wr_en),
	.read_en(~rd_en),
	.ready(ready),
	.wdt_reset_req(wdt_reset_req)
);
endmodule



