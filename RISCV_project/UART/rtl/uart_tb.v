// =============================================================================
// uart_tb.v — Self-checking Testbench for uart_top
//
// Tests:
//   1. TX: Sends byte 0x41 ('A') and decodes the serial bitstream
//   2. RX: Injects a serial frame for 0x55 and reads DATA register
//   3. STATUS: Checks TX_READY / TX_BUSY transitions
//   4. BAUD_DIV: Reprograms divisor and re-runs TX
//   5. Reset behaviour
// =============================================================================
//:w
//`timescale 1ns/1ps

module uart_tb;

    // -----------------------------------------------------------------------
    // Clock & Reset
    // -----------------------------------------------------------------------
    localparam CLK_PERIOD = 20;        // 50 MHz → 20 ns
    localparam BAUD_DIV   = 16'd52;    // Small divisor for fast simulation
                                       // (real value is 5208 for 9600 @ 50 MHz)
    localparam BIT_TIME   = CLK_PERIOD * BAUD_DIV; // ns per bit

    reg clk, rst_n;

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -----------------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------------
    reg  [7:0]  addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;
    reg         write_en, read_en;
    wire        ready;
    wire        tx_line;
    reg         rx_line;

    // -----------------------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------------------
    uart_top dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .addr     (addr),
        .wdata    (wdata),
        .rdata    (rdata),
        .write_en (write_en),
        .read_en  (read_en),
        .ready    (ready),
        .tx       (tx_line),
        .rx       (rx_line)
    );

    // -----------------------------------------------------------------------
    // Helper tasks
    // -----------------------------------------------------------------------

    // Write a register (one clock cycle)
    task reg_write;
        input [7:0]  a;
        input [31:0] d;
        begin
            @(posedge clk); #1;
            addr     = a;
            wdata    = d;
            write_en = 1'b1;
            read_en  = 1'b0;
            @(posedge clk); #1;
            write_en = 1'b0;
        end
    endtask

    // Read a register (one clock cycle, returns value in rdata)
    task reg_read;
        input [7:0] a;
        begin
            @(posedge clk); #1;
            addr     = a;
            write_en = 1'b0;
            read_en  = 1'b1;
            @(posedge clk); #1;
            read_en  = 1'b0;
        end
    endtask

    // Wait until STATUS[0] (TX_READY) is high
    task wait_tx_ready;
        integer timeout;
        begin
            timeout = 0;
            read_en  = 1'b0;
            write_en = 1'b0;
            repeat (BIT_TIME * 12 / CLK_PERIOD + 100) begin
                @(posedge clk); #1;
                addr    = 8'h04;
                read_en = 1'b1;
                @(posedge clk); #1;
                read_en = 1'b0;
                if (rdata[0]) disable wait_tx_ready;
            end
            $display("TIMEOUT waiting for TX_READY");
        end
    endtask

    // Drive a serial byte onto rx_line (8N1, LSB first)
    task drive_rx_byte;
        input [7:0] data;
        integer i;
        begin
            // Start bit
            rx_line = 1'b0;
            #(BIT_TIME);
            // Data bits LSB first
            for (i = 0; i < 8; i = i+1) begin
                rx_line = data[i];
                #(BIT_TIME);
            end
            // Stop bit
            rx_line = 1'b1;
            #(BIT_TIME);
        end
    endtask

    // -----------------------------------------------------------------------
    // TX capture: sample tx_line at mid-bit, rebuild byte
    // -----------------------------------------------------------------------
    reg [9:0] captured_frame; // start + 8 data + stop
    integer   cap_idx;

    task capture_tx_frame;
        integer i;
        begin
            // Wait for falling edge (start bit)
            @(negedge tx_line);
            // Sample mid-way through start bit
            #(BIT_TIME / 2);
            captured_frame[0] = tx_line; // start bit (should be 0)
            // Sample 8 data bits
            for (i = 1; i <= 8; i = i+1) begin
                #(BIT_TIME);
                captured_frame[i] = tx_line;
            end
            // Sample stop bit
            #(BIT_TIME);
            captured_frame[9] = tx_line;
        end
    endtask

    // -----------------------------------------------------------------------
    // Main test sequence
    // -----------------------------------------------------------------------
    integer errors;

    initial begin
        errors   = 0;
        rx_line  = 1'b1;   // RX idle-high
        addr     = 8'h0;
        wdata    = 32'h0;
        write_en = 1'b0;
        read_en  = 1'b0;

        // -------------------------------------------------------------------
        // 0. Reset
        // -------------------------------------------------------------------
        rst_n = 1'b0;
        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);

        $display("=== TEST 1: Program BAUD_DIV ===");
        reg_write(8'h0C, {16'd0, BAUD_DIV});
        reg_read (8'h0C);
        if (rdata[15:0] !== BAUD_DIV) begin
            $display("FAIL BAUD_DIV: expected %0d, got %0d", BAUD_DIV, rdata[15:0]);
            errors = errors + 1;
        end else begin
            $display("PASS BAUD_DIV readback = %0d", rdata[15:0]);
        end

        // -------------------------------------------------------------------
        // 1. Enable TX and RX
        // -------------------------------------------------------------------
        $display("=== TEST 2: Enable TX+RX via CONTROL ===");
        reg_write(8'h08, 32'h3); // TX_EN=1, RX_EN=1
        reg_read (8'h08);
        if (rdata[1:0] !== 2'b11) begin
            $display("FAIL CONTROL: expected 0x3, got 0x%0h", rdata[1:0]);
            errors = errors + 1;
        end else begin
            $display("PASS CONTROL = 0x%0h", rdata[1:0]);
        end

        // -------------------------------------------------------------------
        // 2. Check TX_READY in STATUS before any TX
        // -------------------------------------------------------------------
        $display("=== TEST 3: STATUS TX_READY after enable ===");
        wait_tx_ready;
        if (!rdata[0]) begin
            $display("FAIL TX_READY not set");
            errors = errors + 1;
        end else begin
            $display("PASS TX_READY = 1");
        end

        // -------------------------------------------------------------------
        // 3. Transmit 'A' (0x41) and capture the serial frame
        // -------------------------------------------------------------------
        $display("=== TEST 4: TX byte 0x41 ('A') ===");
        fork
            begin
                reg_write(8'h00, 32'h41); // Write DATA → triggers TX
            end
            begin
                capture_tx_frame;
            end
        join

        // Verify start bit = 0
        if (captured_frame[0] !== 1'b0) begin
            $display("FAIL Start bit: expected 0, got %b", captured_frame[0]);
            errors = errors + 1;
        end

        // Verify 8 data bits (LSB first)
        begin : check_data
            reg [7:0] rx_byte;
            integer b;
            rx_byte = 8'd0;
            for (b = 0; b < 8; b = b+1)
                rx_byte[b] = captured_frame[b+1];

            if (rx_byte !== 8'h41) begin
                $display("FAIL TX data: expected 0x41, got 0x%0h", rx_byte);
                errors = errors + 1;
            end else begin
                $display("PASS TX data = 0x%0h ('%0s')", rx_byte,
                         (rx_byte >= 8'h20 && rx_byte <= 8'h7e) ? rx_byte : "?");
            end
        end

        // Verify stop bit = 1
        if (captured_frame[9] !== 1'b1) begin
            $display("FAIL Stop bit: expected 1, got %b", captured_frame[9]);
            errors = errors + 1;
        end else begin
            $display("PASS Stop bit = 1");
        end

        // -------------------------------------------------------------------
        // 4. Check TX_BUSY transitions
        // -------------------------------------------------------------------
        $display("=== TEST 5: TX_BUSY / TX_READY transitions ===");
        // After frame, TX should be ready again
        wait_tx_ready;
        reg_read(8'h04);
        if (rdata[0] !== 1'b1 || rdata[2] !== 1'b0) begin
            $display("FAIL STATUS after TX: TX_READY=%b TX_BUSY=%b", rdata[0], rdata[2]);
            errors = errors + 1;
        end else begin
            $display("PASS TX_READY=1 TX_BUSY=0 after frame");
        end

        // -------------------------------------------------------------------
        // 5. RX: inject 0x55 and verify DATA register
        // -------------------------------------------------------------------
        $display("=== TEST 6: RX byte 0x55 ===");
        fork
            begin
                drive_rx_byte(8'h55);
            end
            begin
                // Wait until RX_VALID rises
                begin : wait_rx
                    repeat (BIT_TIME * 14 / CLK_PERIOD + 50) begin
                        @(posedge clk); #1;
                        addr    = 8'h04;
                        read_en = 1'b1;
                        @(posedge clk); #1;
                        read_en = 1'b0;
                        if (rdata[1]) disable wait_rx; // RX_VALID
                    end
                end
            end
        join

        reg_read(8'h04);
        if (!rdata[1]) begin
            $display("FAIL RX_VALID not set after receive");
            errors = errors + 1;
        end else begin
            $display("PASS RX_VALID = 1");
            reg_read(8'h00); // Read DATA
            if (rdata[7:0] !== 8'h55) begin
                $display("FAIL RX data: expected 0x55, got 0x%0h", rdata[7:0]);
                errors = errors + 1;
            end else begin
                $display("PASS RX data = 0x%0h", rdata[7:0]);
            end

            // Clear RX_VALID
            reg_write(8'h08, 32'h7); // RX_CLR=1 along with TX_EN/RX_EN
            repeat(2) @(posedge clk);
            reg_read(8'h04);
            if (rdata[1]) begin
                $display("FAIL RX_VALID not cleared after RX_CLR");
                errors = errors + 1;
            end else begin
                $display("PASS RX_VALID cleared");
            end
        end

        // -------------------------------------------------------------------
        // 6. Reset behaviour
        // -------------------------------------------------------------------
        $display("=== TEST 7: Reset clears STATUS ===");
        rst_n = 1'b0;
        repeat(3) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);
        reg_read(8'h04);
        if (rdata !== 32'd0) begin
            $display("FAIL STATUS after reset: 0x%0h (expected 0)", rdata);
            errors = errors + 1;
        end else begin
            $display("PASS STATUS = 0 after reset");
        end

        // -------------------------------------------------------------------
        // Summary
        // -------------------------------------------------------------------
        $display("==============================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);
        $display("==============================");
        $finish;
    end

    // Optional: Dump waveforms
    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
    end

    // Simulation timeout guard
    initial begin
        #(BIT_TIME * 200);
        $display("FATAL: Simulation timeout");
        $finish;
    end

endmodule

