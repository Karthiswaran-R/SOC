module address_decoder(
  input logic [31:0]addr,
  output logic rom_sel,
  ram_sel,
  gpio_sel,
  uart_sel,
  timer_sel,
  wdt_sel,
  spi_sel,
  intc_sel,
  dbg_sel,
  i2c_sel);
  always_comb begin
    rom_sel = 0;
    ram_sel = 0;
    gpio_sel = 0;
    uart_sel = 0;
    timer_sel = 0;
    wdt_sel = 0;
    spi_sel = 0;
    intc_sel = 0;
    dbg_sel = 0;
    i2c_sel = 0;
    casez(addr) 
     32'h0000_0???: rom_sel = 1;
     32'h0000_1???: ram_sel = 1;
     32'h0000_20??: gpio_sel = 1;
     32'h0000_21??: uart_sel = 1;
     32'h0000_22??: timer_sel = 1;
     32'h0000_23??: timer_sel = 1;
     32'h0000_24??: wdt_sel = 1;
     32'h0000_25??: spi_sel = 1;
     32'h0000_26??: intc_sel = 1;
     32'h0000_27??: dbg_sel = 1;
     32'h0000_28??: i2c_sel = 1;
     endcase
end
endmodule

