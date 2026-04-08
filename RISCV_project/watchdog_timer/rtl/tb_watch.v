
module tb_watchdog_timer;

    reg         clk;
    reg         rst_n;

    reg  [7:0]  addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;

    reg         write_en;
    reg         read_en;
    wire        ready;

    wire        wdt_reset_req;

    // Instantiate DUT
    watchdog_timer dut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .write_en(write_en),
        .read_en(read_en),
        .ready(ready),
        .wdt_reset_req(wdt_reset_req)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    // -----------------------------
    // TASK: WRITE
    // -----------------------------
    task write_reg(input [7:0] a, input [31:0] d);
    begin
        @(posedge clk);
        addr     = a;
        wdata    = d;
        write_en = 1;
        read_en  = 0;

        @(posedge clk);
        write_en = 0;
    end
    endtask

    // -----------------------------
    // TASK: READ
    // -----------------------------
    task read_reg(input [7:0] a);
    begin
        @(posedge clk);
        addr     = a;
        read_en  = 1;
        write_en = 0;

        @(posedge clk);
        read_en  = 0;
    end
    endtask

    // -----------------------------
    // TEST SEQUENCE
    // -----------------------------
    initial begin
        // Init
        clk = 0;
        rst_n = 0;
        addr = 0;
        wdata = 0;
        write_en = 0;
        read_en = 0;

        // Reset
        #20;
        rst_n = 1;

        // ---------------------------------
        // TEST 1: Load value
        // ---------------------------------
        $display("Loading watchdog value = 10");
        write_reg(8'h00, 32'd10);

        // ---------------------------------
        // TEST 2: Enable watchdog
        // ---------------------------------
        $display("Enabling watchdog");
        write_reg(8'h08, 32'h1);

        // ---------------------------------
        // TEST 3: Kick watchdog
        // ---------------------------------
        $display("Kick watchdog (A5)");
        write_reg(8'h08, 32'hA);

        // Let it run few cycles
        repeat (5) @(posedge clk);

        // ---------------------------------
        // TEST 4: Kick again before timeout
        // ---------------------------------
        $display("Kick again before timeout");
        write_reg(8'h08, 32'hA5);

        repeat (5) @(posedge clk);

        // --------------------------------
        // TEST 5: No kick → expect timeout
        // ---------------------------------
        $display("Waiting for timeout...");
        repeat (15) @(posedge clk);

        if (wdt_reset_req)
            $display("✅ TIMEOUT detected, reset asserted");
        else
            $display("❌ ERROR: Timeout not detected");

        // ---------------------------------
        // TEST 6: Read status
        // ---------------------------------
        read_reg(8'h0C);
        $display("STATUS = %h", rdata);

        // Finish
        #20;
        $finish;
    end
initial begin
    $dumpfile("watchdog.vcd");   // Name of VCD file
    $dumpvars(0, tb_watchdog_timer); // Dump all signals in testbench
end
endmodule

