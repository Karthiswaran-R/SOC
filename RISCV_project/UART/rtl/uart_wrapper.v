module uart_apb_wrapper (
		// Global signals
		input PCLK,
		input PRESETn,

		// Input signals from APB Bridge
		input PSEL,
		input PENABLE,
		input [31:0] PADDR,
		input PWRITE,
		input [31:0] PWDATA,

		
		// Output signals to APB bridge

		output [31:0] PRDATA,
		output PREADY,
		output PSLVERR,

		// Native design signals going to output
		input rx,
		output tx

	);

	// Local signals 
	wire wr_en;
	wire rd_en;

	assign wr_en = PSEL && PENABLE && PWRITE;
	assign rd_en = PSEL && PENABLE && !PWRITE;

	// these signals are intentionally tied to 0, as these are
	// simple peripharals, and they do not support the error
	
	assign PSLVERR = 1'b0;

	// These are simple slaves, and they are always ready and 
	// there are not wait state
	assign PREADY = 1'b1;





	// Lower module instantitation
	
	uart_top dut 	(
			// Global signals
			.clk		(PCLK		),
			.rst_n		(PRESETn	),
			// Signals from APB bridge
			.addr		(PADDR		),
			.wdata		(PWDATA		),
			.write_en	(wr_en		),
			.read_en	(~rd_en		),
			.rdata		(PRDATA		),
			.ready		(PREADY		),
                        .tx             (TX             ),
                        .rx             (RX             ),

		);


endmodule
