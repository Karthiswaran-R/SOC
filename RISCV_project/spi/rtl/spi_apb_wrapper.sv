module spi_apb_wrapper (
    input  logic        PCLK,
    input  logic        PRESETn,

    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic [31:0] PWDATA,

    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,

    output logic        sclk,
    output logic        mosi,
    input  logic        miso,
    output logic        cs_n,
    output logic        ready
);

    wire wr_en, rd_en;

    assign wr_en = PSEL && PENABLE && PWRITE;
    assign rd_en = PSEL && PENABLE && !PWRITE;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    spi_master u_spi (
        .clk        (PCLK),
        .rst_n      (PRESETn),
        .addr       (PADDR[7:0]),
        .wdata      (PWDATA),
        .write_en   (wr_en),
        .read_en    (~rd_en),
        .rdata      (PRDATA),
        .ready      (ready),

        .sclk       (sclk),
        .mosi       (mosi),
        .miso       (miso),
        .cs_n       (cs_n)
    );

endmodule
