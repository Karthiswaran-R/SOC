module soc_integration(
		       input 	    clk_in,
		       input 	    rst_btn_n,
		       //GPIO 
		       input [7:0]  gpio_in,
		       output [7:0] gpio_out,
		       output [7:0] gpio_dir,

		       //UART
		       input 	    uart_rx,
		       output 	    uart_tx,

		       // SPI
		       input 	    spi_miso,
		       output 	    spi_mosi,
		       output 	    spi_sclk,
		       output 	    spi_cs_n
		       );
   // 1. CLOCK/RESET
   wire 			    clk_cpu;
   wire 			    clk_uart;
   wire 			    clk_gpio;
   wire 			    clk_i2c;
   wire 			    clk_spi;
   wire 			    clk_timer;
   wire 			    clk_wdog;
   wire 			    clk_ram;
   wire 			    clk_rom;
   wire 			    clk_debug;
   wire 			    clk_intc;
   wire 			    rst_cpu_n;
   wire 			    rst_uart_n;
   wire 			    rst_gpio_n;
   wire 			    rst_i2c_n;
   wire 			    rst_spi_n;
   wire 			    rst_timer_n;
   wire 			    rst_wdog_n;
   wire 			    rst_ram_n;
   wire 			    rst_rom_n;
   wire 			    rst_debug_n;
   wire 			    rst_intc_n;
   
	// 2. RISC_V CPU
   wire [31:0] 			    HADDR_M;
   wire 			    HWRITE_M;
   wire [1:0] 			    HTRANS_M;
   wire [2:0] 			    HSIZE_M;
   wire [2:0] 			    HBURST_M;       
   wire [31:0] 			    HWDATA_M;
   wire 			    HREADY_M;
   wire [31:0] 			    HRDATA_M;
   wire 			    HREADYOUT_M;
   wire 			    HRESP_M;
   wire 			    cpu_irq;

   // MATRIX2SLAVE SIGNALS
   // SRAM
   wire 			    HSEL_S0;
   wire [31:0] 			    HADDR_S0;
   wire 			    HWRITE_S0;
   wire [1:0] 			    HTRANS_S0;
   wire [2:0] 			    HSIZE_S0;
   wire [31:0] 			    HWDATA_S0;
   wire [31:0] 			    HRDATA_S0;
   wire 			    HREADYOUT_S0;
   wire 			    HRESP_S0;

   // APB Bridge
   wire 			    HSEL_S1;
   wire [31:0] 			    HADDR_S1;
   wire 			    HWRITE_S1;
   wire [1:0] 			    HTRANS_S1;
   wire [2:0] 			    HSIZE_S1;
   wire [31:0] 			    HWDATA_S1;
   wire [31:0] 			    HRDATA_S1;
   wire 			    HREADYOUT_S1;
   wire 			    HRESP_S1;
   // 3. AHB2APB BRIDGE
   wire [31:0] 			    PADDR, PWDATA;
   wire [31:0] PRDATA [11:0];
   wire [2:0] 			    HSIZE_S1;
   wire 			    PWRITE, PENABLE;
   wire [11:0] 			    PSEL, PREADY, PSLVERR;
   //APB PERIPHERALS 
   //4.GPIO
   wire [31:0] 			    gpio_rdata;
   wire [7:0] 			    gpio_in;
   wire [7:0] 			    gpio_out;
   wire [7:0] 			    gpio_dir;   

   //5.UART 
   wire [31:0] 			    uart_rdata;
   wire 			    uart_rx,uart_tx;
   
   //6.SPI 
   wire [31:0] 			    spi_rdata;
   wire 			    spi_pready;
   wire 			    spi_pslverr;
   wire 			    PSEL_SPI;
   //7.TIMER 
   wire [31:0] 			    timer_rdata;
   wire 			    timer_irq;
   //8.WATCHDOG 
   wire [31:0] 			    wdt_rdata;
   wire 			    wdt_pslverr;
   //9.INTERRUPT CONTROLLER
   wire [31:0] 			    intc_rdata;
   wire [7:0] 			    irq_in;
   wire 			    cpu_irq;
   wire [31:0]                      PRDATAS; 
   //10.DEBUG INTERFACE
   wire [31:0] 			    debug_rdata;
   wire 			    dbginf_pready;
   wire 			    dbginf_slverr;
   
   wire PSEL_GPIO  ;  
   wire PSEL_UART  ;
   wire PSEL_SPI   ;
   wire PSEL_TIMER ;
   wire PSEL_WDT   ;
   wire PSEL_INTC  ;
   wire PSEL_DEBUG ;
   

   assign irq_in[0] = timer_irq;
   assign HREADY_M = HREADYOUT_M;
   assign PSEL_GPIO = PSEL[0];
   assign PSEL_UART = PSEL[1];
   assign PSEL_SPI  = PSEL[2];
   assign PSEL_TIMER = PSEL[3];
   assign PSEL_WDT = PSEL[4];
   assign PSEL_INTC = PSEL[5];
   assign PSEL_DEBUG = PSEL[6];

   
   //PRDATA MUX 
//   assign PRDATA =
//		  PSEL_GPIO  ? gpio_rdata  :
//		  PSEL_UART  ? uart_rdata  :
//		  PSEL_SPI   ? spi_rdata   :
//		  PSEL_TIMER ? timer_rdata :
//		  PSEL_WDT   ? wdt_rdata   :
//		  PSEL_INTC  ? intc_rdata  :
//		  PSEL_DEBUG ? debug_rdata :
//		  32'h00000000;

   soc_clk_rst_gen clk_rst (
    			    .clk_in		(clk_in		),
    			    .rst_btn_n	(rst_btn_n	),
    			    .clk_cpu	(clk_cpu	),
    			    .clk_uart	(clk_uart	),    
    			    .clk_gpio	(clk_gpio	),
    			    .clk_i2c	(clk_i2c	),
    			    .clk_spi	(clk_spi	),
    			    .clk_timer	(clk_timer	),
    			    .clk_wdog	(clk_wdog	),
    			    .clk_ram	(clk_ram	),
    			    .clk_rom	(clk_rom	),
    			    .clk_debug	(clk_debug	),
    			    .clk_intc	(clk_intc	),
    			    .rst_cpu_n	(rst_cpu_n	),
    			    .rst_uart_n	(rst_uart_n	),
    			    .rst_gpio_n	(rst_gpio_n	),
    			    .rst_i2c_n	(rst_i2c_n	),
    			    .rst_spi_n	(rst_spi_n	),
    			    .rst_timer_n	(rst_timer_n	),
    			    .rst_wdog_n	(rst_wdog_n	),
    			    .rst_ram_n	(rst_ram_n	),
    			    .rst_rom_n	(rst_rom_n	),
    			    .rst_debug_n	(rst_debug_n	),
    			    .rst_intc_n	(rst_intc_n	)
		            );
   
   
   riscv_top riscv_cpu (
        		.HCLK		(clk_cpu	),
        		.HRESETn	(rst_cpu	),
        		.irq		(cpu_irq	),
        		.HADDR		(HADDR_M	),
        		.HTRANS		(HTRANS_M	),
        		.HWRITE		(HWRITE_M	),
        		.HSIZE		(HSIZE_M	),
			.HBURST 	(HBURST_M	),
        		.HWDATA		(HWDATA_M	),
        		.HRDATA		(HRDATA_M	),
        		.HREADY		(HREADYOUT_M	),
			.HRESP		(HRESP_M	)
			);


   // 2. AHB  
   ahb_matrix_1m2s matrix (
			   .HCLK(clk),
			   .HRESETn(rst_n),
			   // Master
			   .HADDR_M(HADDR_M),
			   .HWRITE_M(HWRITE_M),
			   .HTRANS_M(HTRANS_M),
			   .HSIZE_M(HSIZE_M),
			   .HWDATA_M(HWDATA_M),
			   .HREADY_M(HREADY_M),
			   .HRDATA_M(HRDATA_M),
			   .HREADYOUT_M(HREADYOUT_M),
			   .HRESP_M(HRESP_M),
			   // SRAM
			   .HSEL_S0(HSEL_S0),
			   .HADDR_S0(HADDR_S0),
			   .HWRITE_S0(HWRITE_S0),
			   .HTRANS_S0(HTRANS_S0),
			   .HSIZE_S0(HSIZE_S0),
			   .HWDATA_S0(HWDATA_S0),
			   .HRDATA_S0(HRDATA_S0),
			   .HREADYOUT_S0(HREADYOUT_S0),
			   .HRESP_S0(HRESP_S0),
			   // APB Bridge
			   .HSEL_S1(HSEL_S1),
			   .HADDR_S1(HADDR_S1),
			   .HWRITE_S1(HWRITE_S1),
			   .HTRANS_S1(HTRANS_S1),
			   .HSIZE_S1(HSIZE_S1),
			   .HWDATA_S1(HWDATA_S1),
			   .HRDATA_S1(HRDATA_S1),
			   .HREADYOUT_S1(HREADYOUT_S1),
			   .HRESP_S1(HRESP_S1)
			   );


   ahb_to_apb_bridge_12 bridge (
       		 	  	.HCLK(clk),
       		 		.HRESETn(rst_n),
       		 		.HSEL(HSEL_S1),
       		 		.HADDR(HADDR_S1),
       		 		.HWRITE(HWRITE_S1),
       		 		.HTRANS(HTRANS_S1),
       		 		.HSIZE(HSIZE_S1),
       		 		.HWDATA(HWDATA_S1),
       		 		.HREADY(HREADY),
       		 		.HRDATA(HRDATA_S1),
       		 		.HREADYOUT(HREADYOUT_S1),
       		 		.HRESP(HRESP_S1),
       		 		// APB
       		 		.PCLK(clk),
       		 		.PRESETn(rst_n),
       		 		.PSEL(PSEL),
       		 		.PENABLE(PENABLE),
       		 		.PWRITE(PWRITE),
       		 		.PADDR(PADDR),
       		 		.PWDATA(PWDATA),
       		 		.PRDATA(PRDATA),
       		 		.PREADY(PREADY),
       		 		.PSLVERR(PSLVERR)
				);
   

   gpio_apb_wrapper gpio_w (
        		    .PCLK(clk_gpio),
        		    .PRESETn(rst_gpio),
        		    .PSEL(PSEL_GPIO),
        		    .PENABLE(PENABLE),
        		    .PADDR(PADDR),
        		    .PWRITE(PWRITE),
        		    .PWDATA(PWDATA),
        		    .PRDATA(gpio_rdata),
        		    .PREADY(PREADY),
        		    .gpio_in(gpio_in),
        		    .gpio_out(gpio_out),
        		    .gpio_dir(gpio_dir)
   			    );


   // UART Instance 
   uart_apb_wrapper u_uart (
			    .PCLK    	(clk_uart	),
			    .PRESETn 	(rst_uart	),
			    .PSEL    	(PSEL_UART	),
			    .PENABLE 	(PENABLE	),
			    .PADDR  	(PADDR		),
			    .PWRITE 	(PWRITE		),
			    .PWDATA 	(PWDATA		),
			    .PRDATA 	(uart_rdata	),
			    .PREADY 	(PREADY		),
			    .PSLVERR	(PSLVERR	),
			    .rx		(uart_rx	),
			    .tx		(uart_rx	)
			    );

   spi_apb_wrapper spi_w (
    			  .PCLK		(clk_spi	),
    			  .PRESETn	(rst_spi	),
    			  .PSEL		(PSEL_SPI	),
    			  .PENABLE	(PENABLE	),
    			  .PADDR		(PADDR		),
    			  .PWRITE		(PWRITE		),
    			  .PWDATA		(PWDATA		),
    			  .PRDATA		(spi_rdata	),
    			  .PREADY		(spi_pready	),
    			  .PSLVERR	(spi_pslverr	),
    			  .miso		(spi_miso	),
    			  .mosi		(spi_mosi	),
    			  .sclk		(spi_sclk	),
    			  .cs_n		(spi_cs_n	)
			  );

   timer_apb_wrapper timer_w (
        		      .PCLK		(clk_timer	),
       			      .PRESETn	(rst_timer	),
       			      .PSEL		(PSEL_TIMER	),
       			      .PENABLE	(PENABLE	),
       			      .PADDR		(PADDR		),
       			      .PWRITE		(PWRITE		),
       			      .PWDATA		(PWDATA		),
       			      .PRDATA		(timer_rdata	),
       			      .PREADY		(PREADY		),
       			      .timer_irq	(timer_irq	)
   			      );


   watchdog_timer_apb_wrapper wdt_w (
        			     .PCLK		(clk_wdt	),
        			     .PRESETn	(rst_wdt	),
        			     .PSEL		(PSEL_WDT	),
        			     .PADDR		(PADDR		),
        			     .PWDATA		(PWDATA		),
        			     .PRDATA		(wdt_rdata	),
        			     .PWRITE		(PWRITE		),
				     .PENABLE	(PENABLE	),
        			     .PREADY		(PREADY 	),
				     .PSLVERR	(wdt_pslverr	)
				     );


   interruptcontroller_apb_wrapper intc_w (
        				   .PCLK		(clk_intc 	),
					   .PRESETn	(rst_intc	),
					   .PSEL		(PSEL_INTC	),
					   .PENABLE	(PENABLE 	),
					   .PADDR		(PADDR		),
					   .PWRITE		(PWRITE		),
					   .PWDATA		(PWDATA    	),
					   .PRDATA		(PRDATAS	),	
					   .PREADY		(PREDAY		),
					   .PSLVERR	(PSLVERR	),
        				   .irq_in		(irq_in		),
        				   .cpu_irq	(cpu_irq	)
					   );


   debug_apb_wrapper debug_w (
        		      .PCLK		(clk_debug	),
        		      .PRESETn	(rst_debug	),
        		      .PSEL		(PSEL_DEBUG	),
        		      .PENABLE	(PENABLE	),
        		      .PADDR		(PADDR		),
        		      .PWRITE		(PWRITE		),
        		      .PWDATA		(PWDATA		),
        		      .PRDATA		(debug_rdata	),
        		      .PREADY		(dbginf_pready	),
			      .PSLVERR	(dbginf_slverr	)
    			      );

endmodule
