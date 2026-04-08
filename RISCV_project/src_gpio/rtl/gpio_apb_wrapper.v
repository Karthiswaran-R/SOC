module gpio_apb_wrapper (
    input PCLK,
    input PRESETn,
    input PSEL,
    input PENABLE,
    input [31:0] PADDR,
    input PWRITE,
    input [31:0] PWDATA,
    output [31:0] PRDATA,
    output PREADY,
    output PSLVERR,
    input  [7:0] gpio_in,
    output [7:0] gpio_out,
    output [7:0] gpio_dir,
    output ready
);
    wire wr_en;
    wire rd_en;
    assign wr_en = PSEL && PENABLE && PWRITE;
    assign rd_en = PSEL && PENABLE && !PWRITE;
    assign PSLVERR = 1'b0;
    assign PREADY  = 1'b1;
    gpio u_gpio (
        .clk        (PCLK),
        .rst_n      (PRESETn),
        .addr       (PADDR[7:0]),
        .wdata      (PWDATA),
        .write_en   (wr_en),
        .read_en    (~rd_en),
        .rdata      (PRDATA),
        .ready      (ready),
        .gpio_in    (gpio_in),
        .gpio_out   (gpio_out),
        .gpio_dir   (gpio_dir)
    );
endmodule
