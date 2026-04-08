`timescale 1ns/1ps

module tb_soc_clk_rst_gen;

    //====================================================
    // INPUTS
    //====================================================
    reg clk_in;
    reg rst_btn_n;

    //====================================================
    // OUTPUTS
    //====================================================
    wire clk_cpu, clk_uart, clk_gpio, clk_i2c, clk_spi;
    wire clk_timer, clk_wdog, clk_ram, clk_rom, clk_debug, clk_intc;

    wire rst_cpu_n, rst_uart_n, rst_gpio_n;
    wire rst_i2c_n, rst_spi_n, rst_timer_n, rst_wdog_n;
    wire rst_ram_n, rst_rom_n, rst_debug_n, rst_intc_n;

    //====================================================
    // DUT INSTANTIATION
    //====================================================
    soc_clk_rst_gen dut (
        .clk_in(clk_in),
        .rst_btn_n(rst_btn_n),

        .clk_cpu(clk_cpu),
        .clk_uart(clk_uart),
        .clk_gpio(clk_gpio),
        .clk_i2c(clk_i2c),
        .clk_spi(clk_spi),
        .clk_timer(clk_timer),
        .clk_wdog(clk_wdog),
        .clk_ram(clk_ram),
        .clk_rom(clk_rom),
        .clk_debug(clk_debug),
        .clk_intc(clk_intc),

        .rst_cpu_n(rst_cpu_n),
        .rst_uart_n(rst_uart_n),
        .rst_gpio_n(rst_gpio_n),
        .rst_i2c_n(rst_i2c_n),
        .rst_spi_n(rst_spi_n),
        .rst_timer_n(rst_timer_n),
        .rst_wdog_n(rst_wdog_n),
        .rst_ram_n(rst_ram_n),
        .rst_rom_n(rst_rom_n),
        .rst_debug_n(rst_debug_n),
        .rst_intc_n(rst_intc_n)
    );

    //====================================================
    // CLOCK GENERATION (100 MHz → 10ns period)
    //====================================================
    initial clk_in = 0;
    always #5 clk_in = ~clk_in;

    //====================================================
    // STIMULUS
    //====================================================
    initial begin
        // Dump waveform
        $dumpfile("soc.vcd");
        $dumpvars(0, tb_soc_clk_rst_gen);

        // Initial state
        rst_btn_n = 1;

        // Apply RESET
        #10;
        rst_btn_n = 0;
        $display("T=%0t : RESET PRESSED", $time);

        #40;
        rst_btn_n = 1;
        $display("T=%0t : RESET RELEASED", $time);

        // Wait for reset release + stabilization
        #400;

        // Apply RESET again
        rst_btn_n = 0;
        $display("T=%0t : RESET PRESSED AGAIN", $time);

        #30;
        rst_btn_n = 1;
        $display("T=%0t : RESET RELEASED AGAIN", $time);

        #400;

        $finish;
    end

    //====================================================
    // MONITOR (DEBUG OUTPUT)
    //====================================================
    initial begin
        $monitor("T=%0t | rst_btn_n=%b | CPU_RST=%b | UART_RST=%b | GPIO_RST=%b | TIMER_RST=%b | CPU_CLK=%b | I2C_CLK=%b | GPIO_CLK=%b",
                 $time, rst_btn_n,
                 rst_cpu_n, rst_uart_n, rst_gpio_n, rst_timer_n,
                 clk_cpu, clk_i2c, clk_gpio);
    end

endmodule
