module spi_master_tb;
    logic clk, rst_n;
    logic [7:0] addr;
    logic [31:0] wdata, rdata;
    logic write_en, read_en, ready;

    logic sclk, mosi, miso, cs_n;
    spi_master dut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .wdata(wdata),
        .write_en(write_en),
        .read_en(read_en),
        .rdata(rdata),
        .ready(ready),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)
    );
    initial clk = 0;
    always #5 clk = ~clk;

    task write_reg(input [7:0] a, input [31:0] d);
        @(posedge clk);
        addr = a;
        wdata = d;
        write_en = 1;
        @(posedge clk);
        write_en = 0;
    endtask

    initial begin
    
        rst_n = 0;
        write_en = 0;
        read_en = 0;
        miso = 0;
        addr = 0;
        wdata = 0;

        #20 rst_n = 1;

        write_reg(8'h00, 32'hA5);

        write_reg(8'h0C, 32'h1);
        repeat (8) begin
            @(negedge sclk);
            miso = 1'b1;   
        end
        #100;

        $display("SPI TRANSFER DONE");
        $finish;
end

    // ---------------- WAVEFORM ----------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, spi_master_tb);
    end

endmodule
