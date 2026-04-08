module watchdog_timer (
    input         clk,
    input         rst_n,

    input  [7:0]  addr,
    input  [31:0] wdata,
    output reg [31:0] rdata,

    input         write_en,
    input         read_en,
    output        ready,

    output reg    wdt_reset_req
);

