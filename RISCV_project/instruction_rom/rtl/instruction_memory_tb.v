
module instruction_memory_tb;
    reg  [31:0] addr;
    wire [31:0] rdata;

    integer i;
    instruction_memory uut (
        .addr(addr),
        .rdata(rdata)
    );
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, instruction_memory_tb);
    end
    initial begin
        $monitor("Time=%0t | Address=%0d | Data=%h", $time, addr, rdata);
        for (i = 0; i <=256; i = i + 1) begin
            addr = i * 4;   
            #10;
        end
        $finish;
    end

endmodule
