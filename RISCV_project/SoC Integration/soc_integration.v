module soc_integration(
    input        clk_in,
    input        rst_btn_n,
    //GPIO 
    input  [7:0] gpio_in,
    output [7:0] gpio_out,
    output [7:0] gpio_dir,

    //UART
    input        uart_rx,
    output       uart_tx,

    // SPI
    input        spi_miso,
    output       spi_mosi,
    output       spi_sclk,
    output       spi_cs_n
);
    // 1. CLOCK/RESET
    wire clk, rst_n;
    soc_clk_rst_gen clk_rst (
    .clk_in(clk_in),
    .rst_btn_n(rst_btn_n),
    .clk_cpu(clk),
    .clk_uart(),    
    .clk_gpio(),
    .clk_i2c(),
    .clk_spi(),
    .clk_timer(),
    .clk_wdog(),
    .clk_ram(),
    .clk_rom(),
    .clk_debug(),
    .clk_intc(),
    .rst_cpu_n(rst_n),
    .rst_uart_n(),
    .rst_gpio_n(),
    .rst_i2c_n(),
    .rst_spi_n(),
    .rst_timer_n(),
    .rst_wdog_n(),
    .rst_ram_n(),
    .rst_rom_n(),
    .rst_debug_n(),
    .rst_intc_n()
);
    // 2. RISC_V CPU
    wire [31:0] HADDR_M;
    wire        HWRITE_M;
    wire [1:0]  HTRANS_M;
    wire [2:0]  HSIZE_M;
    wire [31:0] HWDATA_M;
    wire        HREADY_M;
    wire [31:0] HRDATA_M;
    wire        HREADYOUT_M;
    wire        HRESP_M;
    wire        cpu_irq;
    riscv_top riscv_cpu (
        .clk(clk),
        .rst(rst_n),

        .HADDR(HADDR_M),
        .HWRITE(HWRITE_M),
        .HTRANS(HTRANS_M),
        .HSIZE(HSIZE_M),
        .HWDATA(HWDATA_M),
        .HREADY(HREADYOUT_M),

        .HRDATA(HRDATA_M),

        .irq(cpu_irq)
    );

    assign HREADY_M = HREADYOUT_M;

    // MATRIX2SLAVE SIGNALS
    // SRAM
    wire HSEL_S0;
    wire [31:0] HADDR_S0;
    wire HWRITE_S0;
    wire [1:0] HTRANS_S0;
    wire [2:0] HSIZE_S0;
    wire [31:0] HWDATA_S0;
    wire [31:0] HRDATA_S0;
    wire HREADYOUT_S0;
    wire HRESP_S0;

    // APB Bridge
    wire HSEL_S1;
    wire [31:0] HADDR_S1;
    wire HWRITE_S1;
    wire [1:0] HTRANS_S1;
    wire [2:0] HSIZE_S1;
    wire [31:0] HWDATA_S1;
    wire [31:0] HRDATA_S1;
    wire HREADYOUT_S1;
    wire HRESP_S1;

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

    // 3. AHB2APB BRIDGE
    wire [31:0] PADDR, PWDATA, PRDATA;
    wire [2:0] HSIZE_S1;
    wire PWRITE, PENABLE;
    wire [11:0] PSEL, PREADY, PSLVERR;

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
	.PCLK(),
	.PRESETn(),
	.PSEL(),
	.PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
	.PRDATA(),
	.PSLVERR()
);
 
    //APB PERIPHERALS 
    //4.GPIO
    wire [31:0] gpio_rdata;

    gpio_apb_wrapper gpio_w (
        .PCLK(clk),
        .PRESETn(global_rst_n),
        .PSEL(PSEL_GPIO),
        .PENABLE(PENABLE),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(gpio_rdata),
        .PREADY(),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_dir(gpio_dir)
    );

    //UART 
    wire [31:0] uart_rdata;

    uart_apb_wrapper uart_w (
        .PCLK(clk),
        .PRESETn(global_rst_n),
        .PSEL(PSEL_UART),
        .PENABLE(PENABLE),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(uart_rdata),
        .PREADY(),
        .rx(uart_rx),
        .tx(uart_tx)
    );
    //5.SPI 
    wire [31:0] spi_rdata;
    wire spi_pready;
    wire spi_pslverr;
    wire PSEL_SPI;

    spi_apb_wrapper spi_w (
    .PCLK(clk),
    .PRESETn(global_rst_n),

    .PSEL(PSEL_SPI),
    .PENABLE(PENABLE),
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PWDATA(PWDATA),

    .PRDATA(spi_rdata),
    .PREADY(spi_pready),
    .PSLVERR(spi_pslverr),

    .miso(spi_miso),
    .mosi(spi_mosi),
    .sclk(spi_sclk),
    .cs_n(spi_cs_n)
);
    //6.TIMER 
    wire [31:0] timer_rdata;
    wire timer_irq;

    timer_apb_wrapper timer_w (
        .PCLK(clk),
        .PRESETn(global_rst_n),
        .PSEL(PSEL_TIMER),
        .PENABLE(PENABLE),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(timer_rdata),
        .PREADY(),
        .timer_irq(timer_irq)
    );

    //7.WATCHDOG 
    wire [31:0] wdt_rdata;
    wire wdt_pslverr;
    wire wdt_pready;

    watchdog_timer_apb_wrapper wdt_w (
        .PCLK(clk),
        .PRESETn(global_rst_n),
        .PSEL(PSEL_WDT),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(wdt_rdata),
        .PWRITE(PWRITE),
	.PENABLE(PENABLE),
        .PREADY(wdt_pready),
	.PSLVERR(wdt_pslverr)
    );

    //8.INTERRUPT CONTROLLER
    wire [31:0] intc_rdata;
    wire [7:0] irq_in;
    assign irq_in[0] = timer_irq;

    interruptcontroller int_con (
        .clk(clk ),
	.rst_n(global_rst_n),
	.irq_in(irq_in),
	.addr(),
	.wdata(),
	.write_en(),
	.read_en(),
	.rdata(),
	.cpu_irq),
	.ready(),
    );

    //9.DEBUG INTERFACE
    wire [31:0] debug_rdata;
    wire dbginf_pready;
    wire dbginf_slverr;

    debug_apb_wrapper debug_w (
        .PCLK(clk),
        .PRESETn(global_rst_n),
        .PSEL(PSEL_DEBUG),
        .PENABLE(PENABLE),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(debug_rdata),
        .PREADY(dbginf_pready),
	.PSLVERR(dbginf_slverr)
    );
    
    // 5. PRDATA MUX 
    assign PRDATA =
        PSEL_GPIO  ? gpio_rdata  :
        PSEL_UART  ? uart_rdata  :
        PSEL_SPI   ? spi_rdata   :
        PSEL_TIMER ? timer_rdata :
        PSEL_WDT   ? wdt_rdata   :
        PSEL_INTC  ? intc_rdata  :
        PSEL_DEBUG ? debug_rdata :
        32'h00000000;

endmodule
