module soc_integraton(
    input clk_in,
    input rst_btn_n,

    // GPIO
    input  [7:0] gpio_in,
    output [7:0] gpio_out,
    output [7:0] gpio_dir,

    // UART
    input  uart_rx,
    output uart_tx,

    // SPI
    input  spi_miso,
    output spi_mosi,
    output spi_sclk,
    output spi_cs_n
);

    //========================================================
    // 1. CLOCK + RESET
    //========================================================
    wire clk, rst_n, slow_clk;

    clock_reset_gen clk_rst (
        .clk_in(clk_in),
        .rst_btn_n(rst_btn_n),
        .clk_out(clk),
        .rst_n_sync(rst_n),
        .slow_clk(slow_clk)
    );

    wire wdt_reset_req;
    wire global_rst_n = rst_n & ~wdt_reset_req;

    //========================================================
    // 2. CPU → AHB MASTER
    //========================================================
    wire [31:0] HADDR, HWDATA, HRDATA;
    wire        HWRITE;
    wire [1:0]  HTRANS;
    wire        HREADY;

    wire        cpu_irq;

    riscv_cpu_ahb cpu (
        .clk(clk),
        .resetn(global_rst_n),

        .HADDR(HADDR),
        .HWDATA(HWDATA),
        .HRDATA(HRDATA),
        .HWRITE(HWRITE),
        .HTRANS(HTRANS),
        .HREADY(HREADY),

        .irq(cpu_irq)
    );

    //========================================================
    // 3. INSTRUCTION MEMORY (AHB SLAVE or separate)
    //========================================================
    wire [31:0] instr_rdata;

    instruction_memory irom (
        .clk(clk),
        .addr(HADDR),
        .rdata(instr_rdata)
    );

    //========================================================
    // 4. DATA RAM (AHB SLAVE)
    //========================================================
    wire [31:0] ram_rdata;

    data_ram ram (
        .clk(clk),
        .addr(HADDR),
        .wdata(HWDATA),
        .rdata(ram_rdata),
        .we(HWRITE)
    );

    //========================================================
    // 5. AHB → APB BRIDGE
    //========================================================
    wire [31:0] PADDR, PWDATA, PRDATA;
    wire        PWRITE, PENABLE;
    wire        PSEL_GPIO, PSEL_UART, PSEL_TIMER;
    wire        PSEL_WDT, PSEL_SPI, PSEL_INTC, PSEL_DEBUG;

    ahb_to_apb_bridge bridge (
        .HCLK(clk),
        .HRESETn(global_rst_n),

        .HADDR(HADDR),
        .HWDATA(HWDATA),
        .HRDATA(PRDATA),   // from APB side
        .HWRITE(HWRITE),
        .HTRANS(HTRANS),
        .HREADY(HREADY),

        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),

        .PSEL_GPIO(PSEL_GPIO),
        .PSEL_UART(PSEL_UART),
        .PSEL_TIMER(PSEL_TIMER),
        .PSEL_WDT(PSEL_WDT),
        .PSEL_SPI(PSEL_SPI),
        .PSEL_INTC(PSEL_INTC),
        .PSEL_DEBUG(PSEL_DEBUG)
    );

    //========================================================
    // 6. APB PERIPHERALS
    //========================================================

    // GPIO
    gpio_controller gpio (
        .clk(clk),
        .rst_n(global_rst_n),
        .addr(PADDR[7:0]),
        .wdata(PWDATA),
        .rdata(),
        .write_en(PWRITE & PSEL_GPIO),
        .read_en(~PWRITE & PSEL_GPIO),
        .ready(),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_dir(gpio_dir)
    );

    // UART
    uart_top uart (
        .clk(clk),
        .rst_n(global_rst_n),
        .addr(PADDR[7:0]),
        .wdata(PWDATA),
        .rdata(),
        .write_en(PWRITE & PSEL_UART),
        .read_en(~PWRITE & PSEL_UART),
        .ready(),
        .tx(uart_tx),
        .rx(uart_rx)
    );

    // TIMER
    wire timer_irq;

    timer_counter timer (
        .clk(clk),
        .rst_n(global_rst_n),
        .addr(PADDR[7:0]),
        .wdata(PWDATA),
        .rdata(),
        .write_en(PWRITE & PSEL_TIMER),
        .read_en(~PWRITE & PSEL_TIMER),
        .ready(),
        .timer_irq(timer_irq)
    );

    // WDT
    watchdog_timer wdt (
        .clk(clk),
        .rst_n(global_rst_n),
        .addr(PADDR[7:0]),
        .wdata(PWDATA),
        .rdata(),
        .write_en(PWRITE & PSEL_WDT),
        .read_en(~PWRITE & PSEL_WDT),
        .ready(),
        .wdt_reset_req(wdt_reset_req)
    );

    // SPI
    spi_master spi (
        .clk(clk),
        .rst_n(global_rst_n),
        .addr(PADDR[7:0]),
        .wdata(PWDATA),
        .rdata(),
        .write_en(PWRITE & PSEL_SPI),
        .read_en(~PWRITE & PSEL_SPI),
        .ready(),
        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .cs_n(spi_cs_n)
    );

    // INTERRUPT CONTROLLER
    wire [7:0] irq_lines;
    assign irq_lines[0] = timer_irq;

    interrupt_controller intc (
        .clk(clk),
        .rst_n(global_rst_n),
        .irq_in(irq_lines),
        .cpu_irq(cpu_irq),
        .addr(PADDR[7:0]),
        .wdata(PWDATA),
        .rdata(),
        .write_en(PWRITE & PSEL_INTC),
        .read_en(~PWRITE & PSEL_INTC),
        .ready()
    );

endmodule
