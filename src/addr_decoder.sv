module address_decoder (
    input  logic [31:0] addr,

    output logic rom_sel,
    output logic ram_sel,
    output logic gpio_sel,
    output logic uart_sel,
    output logic timer_sel,
    output logic wdt_sel,
    output logic spi_sel,
    output logic intc_sel,
    output logic dbg_sel,
    output logic i2c_sel
);

always_comb begin
    // Default
    rom_sel  = 0;
    ram_sel  = 0;
    gpio_sel = 0;
    uart_sel = 0;
    timer_sel= 0;
    wdt_sel  = 0;
    spi_sel  = 0;
    intc_sel = 0;
    dbg_sel  = 0;
    i2c_sel  = 0;

    // Decode (based on memory map)
    unique casez(addr)

        32'h0000_0??? : rom_sel  = 1; // 4KB
        32'h0000_1??? : ram_sel  = 1;

        32'h0000_20?? : gpio_sel = 1;
        32'h0000_21?? : uart_sel = 1;
        32'h0000_22?? : timer_sel= 1;
        32'h0000_23?? : wdt_sel  = 1;
        32'h0000_24?? : spi_sel  = 1;
        32'h0000_25?? : intc_sel = 1;
        32'h0000_26?? : dbg_sel  = 1;
        32'h0000_27?? : i2c_sel  = 1;

        default: ; // unmapped

    endcase
end

endmodule
