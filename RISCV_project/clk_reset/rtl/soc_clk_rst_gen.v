`timescale 1ns/1ps

module soc_clk_rst_gen (
    input clk_in,
    input rst_btn_n,

    // Clocks
    output clk_cpu,
    output clk_uart,
    output clk_gpio,
    output clk_i2c,
    output clk_spi,
    output clk_timer,
    output clk_wdog,
    output clk_ram,
    output clk_rom,
    output clk_debug,
    output clk_intc,

    // Resets
    output rst_cpu_n,
    output rst_uart_n,
    output rst_gpio_n,
    output rst_i2c_n,
    output rst_spi_n,
    output rst_timer_n,
    output rst_wdog_n,
    output rst_ram_n,
    output rst_rom_n,
    output rst_debug_n,
    output rst_intc_n
);

    //====================================================
    // 1. GLOBAL RESET
    //====================================================
    wire rst_async = ~rst_btn_n;

    reg [3:0] hold_cnt;
    wire hold_done;

    always @(posedge clk_in or posedge rst_async) begin
        if (rst_async)
            hold_cnt <= 0;
        else if (!hold_done)
            hold_cnt <= hold_cnt + 1;
    end

    assign hold_done = (hold_cnt == 4'd10);

    reg rst_global_n;
    always @(posedge clk_in or posedge rst_async) begin
        if (rst_async)
            rst_global_n <= 0;
        else if (hold_done)
            rst_global_n <= 1;
    end

    //====================================================
    // 2. CLOCK DIVIDERS
    //====================================================

    // CPU (50 MHz)
    reg cpu_clk_reg;
    always @(posedge clk_in or negedge rst_global_n)
        if (!rst_global_n) cpu_clk_reg <= 0;
        else cpu_clk_reg <= ~cpu_clk_reg;
    assign clk_cpu = cpu_clk_reg;

    // UART (25 MHz)
    reg [1:0] uart_cnt;
    reg uart_clk_reg;
    always @(posedge clk_in or negedge rst_global_n) begin
        if (!rst_global_n) begin
            uart_cnt <= 0;
            uart_clk_reg <= 0;
        end else begin
            if (uart_cnt == 1) begin
                uart_clk_reg <= ~uart_clk_reg;
                uart_cnt <= 0;
            end else
                uart_cnt <= uart_cnt + 1;
        end
    end
    assign clk_uart = uart_clk_reg;

    // I2C (~10 MHz)
    reg [3:0] i2c_cnt;
    reg i2c_clk_reg;
    always @(posedge clk_in or negedge rst_global_n) begin
        if (!rst_global_n) begin
            i2c_cnt <= 0;
            i2c_clk_reg <= 0;
        end else begin
            if (i2c_cnt == 4) begin
                i2c_clk_reg <= ~i2c_clk_reg;
                i2c_cnt <= 0;
            end else
                i2c_cnt <= i2c_cnt + 1;
        end
    end
    assign clk_i2c = i2c_clk_reg;

    // SPI (~20 MHz)
    reg [2:0] spi_cnt;
    reg spi_clk_reg;
    always @(posedge clk_in or negedge rst_global_n) begin
        if (!rst_global_n) begin
            spi_cnt <= 0;
            spi_clk_reg <= 0;
        end else begin
            if (spi_cnt == 2) begin
                spi_clk_reg <= ~spi_clk_reg;
                spi_cnt <= 0;
            end else
                spi_cnt <= spi_cnt + 1;
        end
    end
    assign clk_spi = spi_clk_reg;

    //====================================================
    // 3. CLOCK REUSE (FINAL)
    //====================================================

    assign clk_gpio  = clk_i2c;   // reuse I2C
    assign clk_timer = clk_i2c;   // reuse I2C
    assign clk_wdog  = clk_i2c;   // reuse I2C

    assign clk_ram   = clk_cpu;
    assign clk_rom   = clk_cpu;
    assign clk_debug = clk_uart;
    assign clk_intc  = clk_gpio;

    //====================================================
    // 4. RESET SYNCHRONIZERS
    //====================================================

    // CPU
    reg cpu_r1, cpu_r2;
    always @(posedge clk_cpu or negedge rst_global_n) begin
        if (!rst_global_n) begin
            cpu_r1 <= 0;
            cpu_r2 <= 0;
        end else begin
            cpu_r1 <= 1;
            cpu_r2 <= cpu_r1;
        end
    end
    assign rst_cpu_n = cpu_r2;

    // UART (also used for I2C, SPI, TIMER, WDOG)
    reg uart_r1, uart_r2;
    always @(posedge clk_uart or negedge rst_global_n) begin
        if (!rst_global_n) begin
            uart_r1 <= 0;
            uart_r2 <= 0;
        end else begin
            uart_r1 <= 1;
            uart_r2 <= uart_r1;
        end
    end
    assign rst_uart_n = uart_r2;

    // GPIO (I2C domain)
    reg gpio_r1, gpio_r2;
    always @(posedge clk_gpio or negedge rst_global_n) begin
        if (!rst_global_n) begin
            gpio_r1 <= 0;
            gpio_r2 <= 0;
        end else begin
            gpio_r1 <= 1;
            gpio_r2 <= gpio_r1;
        end
    end
    assign rst_gpio_n = gpio_r2;

    //====================================================
    // 5. RESET REUSE (FINAL)
    //====================================================

    assign rst_i2c_n   = rst_uart_n;
    assign rst_spi_n   = rst_uart_n;
    assign rst_timer_n = rst_uart_n;   // same domain
    assign rst_wdog_n  = rst_uart_n;   // same domain
    assign rst_ram_n   = rst_cpu_n;
    assign rst_rom_n   = rst_cpu_n;
    assign rst_debug_n = rst_uart_n;
    assign rst_intc_n  = rst_gpio_n;

endmodule
