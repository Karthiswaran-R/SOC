module gpio_controller (
    input wire clk,
    input wire rst_n,

    input wire [7:0] addr,
    input wire [31:0] wdata,
    output reg [31:0] rdata,

    input wire write_en,
    input wire read_en,
    output reg ready,

    input wire [7:0] gpio_in,
    output reg [7:0] gpio_out,
    output reg [7:0] gpio_dir
);

    reg [7:0] data_in_reg;
    reg [7:0] data_out_reg;
    reg [7:0] dir_reg;
    wire unused_wdata;
    assign unused_wdata = |wdata[31:8];

    localparam GPIO_IN_ADDR     = 8'h00;
    localparam GPIO_OUT_ADDR    = 8'h04;
    localparam GPIO_DIR_ADDR    = 8'h08;
    localparam GPIO_STATUS_ADDR = 8'h0C;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_in_reg <= 8'b0;
        else
            data_in_reg <= gpio_in;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg <= 8'b0;
            dir_reg      <= 8'b0;
        end else if (write_en) begin
            case (addr)
                GPIO_OUT_ADDR: data_out_reg <= wdata[7:0];
                GPIO_DIR_ADDR: dir_reg      <= wdata[7:0];
                default: ;
            endcase
        end
    end
    always @(*) begin
        gpio_out = data_out_reg & dir_reg;
        gpio_dir = dir_reg;
    end
    always @(*) begin
        if (read_en) begin
            case (addr)
                GPIO_IN_ADDR:     rdata = {24'b0, data_in_reg};
                GPIO_OUT_ADDR:    rdata = {24'b0, data_out_reg};
                GPIO_DIR_ADDR:    rdata = {24'b0, dir_reg};
                GPIO_STATUS_ADDR: rdata = {24'b0, data_in_reg};
                default:          rdata = 32'b0;
            endcase
        end else begin
            rdata = 32'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ready <= 1'b0;
        else
            ready <= 1'b1;
    end
endmodule

Testbench
module gpio_tb;

    reg clk;
    reg rst_n;
    reg [7:0] addr;
    reg [31:0] wdata;
    wire [31:0] rdata;
    reg write_en;
    reg read_en;

    reg [7:0] gpio_in;
    wire [7:0] gpio_out;
    wire [7:0] gpio_dir;

    reg [31:0] read_data;
    wire ready;

    gpio_controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .write_en(write_en),
        .read_en(read_en),
        .ready(ready),        
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_dir(gpio_dir)
    );

    initial begin
        $dumpfile("gpio_controller.vcd");
        $dumpvars(0, gpio_tb);
        clk = 0;
        rst_n = 0;
        addr = 0;
        wdata = 0;
        write_en = 0;
        read_en = 0;
        gpio_in = 0;
        read_data = 0;

    
        rst_n = 1;
        addr = 8'h08;
        wdata = 32'hFF;
        write_en = 1;
        clk = 1; clk = 0;
        write_en = 0;

        if (gpio_dir !== 8'hFF)
            $display("ERROR: DIR failed");
        else
            $display("PASS: DIR OK");
        addr = 8'h04;
        wdata = 32'hAA;
        write_en = 1;
        clk = 1; clk = 0;
        write_en = 0;

        if (gpio_out !== 8'hAA)
            $display("ERROR: OUT failed");
        else
            $display("PASS: OUT OK");
        addr = 8'h04;
        read_en = 1;
        clk = 1; clk = 0;
        read_en = 0;

        read_data = rdata;
        $display("GPIO_OUT = %h", read_data);
        addr = 8'h08;
        wdata = 32'h00;
        write_en = 1;
        clk = 1; clk = 0;
        write_en = 0;
        gpio_in = 8'h3C;

        if (gpio_out !== 8'h00)
            $display("ERROR: Output not disabled");
        else
            $display("PASS: Input mode OK");
        addr = 8'h00;
        read_en = 1;
        clk = 1; clk = 0;
        read_en = 0;

        read_data = rdata;
        $display("GPIO_IN = %h", read_data);

        $display("TEST COMPLETED");
        $finish;
    end
endmodule

