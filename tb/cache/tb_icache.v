`timescale 1ns / 1ps

module tb_icache;

    reg clk = 0;
    always #5 clk = ~clk;

    reg rst_n;

    // Core interface
    reg  [31:0] core_addr;
    reg         core_req;
    wire        core_ack;
    wire [31:0] core_rdata;
    wire        core_stall;

    // Arbiter interface (mock)
    wire [31:0] i_addr;
    wire        i_req;
    reg         i_grant;
    wire [31:0] i_wdata;
    wire        i_wen;
    wire [7:0]  i_burst_len;
    wire [3:0]  i_wstrb;
    reg  [31:0] i_rdata;
    reg         i_ack;
    reg         i_last;

    icache dut (
        .clk(clk), .rst_n(rst_n),
        .core_addr(core_addr), .core_req(core_req),
        .core_ack(core_ack), .core_rdata(core_rdata), .core_stall(core_stall),
        .i_addr(i_addr), .i_req(i_req), .i_grant(i_grant),
        .i_wdata(i_wdata), .i_wen(i_wen), .i_burst_len(i_burst_len), .i_wstrb(i_wstrb),
        .i_rdata(i_rdata), .i_ack(i_ack), .i_last(i_last)
    );

    // Mock arbiter + AXI response
    reg [3:0] beat_cnt;
    reg       resp_active;

    always @(posedge clk) begin
        if (!rst_n) begin
            i_grant <= 1'b0;
            i_ack <= 1'b0;
            i_last <= 1'b0;
            i_rdata <= 32'h0;
            beat_cnt <= 4'd0;
            resp_active <= 1'b0;
        end else begin
            i_grant <= 1'b0;
            i_ack <= 1'b0;
            i_last <= 1'b0;

            if (i_req && !resp_active) begin
                i_grant <= 1'b1;
                resp_active <= 1'b1;
                beat_cnt <= 4'd0;
            end

            if (resp_active) begin
                i_ack <= 1'b1;
                i_rdata <= {24'h0, 8'h10 + beat_cnt};
                if (beat_cnt == 4'd7) begin
                    i_last <= 1'b1;
                    resp_active <= 1'b0;
                end
                beat_cnt <= beat_cnt + 1'b1;
            end
        end
    end

    initial begin
        $dumpfile("waves_icache.vcd");
        $dumpvars(0, tb_icache);

        rst_n = 0;
        core_addr = 32'h0;
        core_req = 1'b0;
        i_rdata = 32'h0;
        i_ack = 1'b0;
        i_last = 1'b0;
        i_grant = 1'b0;

        #30;
        rst_n = 1;
        #10;

        // Test 1: Miss at addr 0x0000_0004 (word offset 1, line base 0x0000_0000)
        $display("=== Test 1: Miss at 0x0000_0004 ===");
        core_addr = 32'h0000_0004;
        core_req = 1'b1;
        @(posedge clk); // LOOKUP
        if (core_stall !== 1'b1) $display("FAIL: Should stall on miss");
        else $display("PASS: Stalled on miss");
        
        wait(core_ack);
        @(posedge clk); // DONE
        $display("Data returned: 0x%08x", core_rdata);
        if (core_rdata === 32'h0000_0011) $display("PASS: Correct word (offset 1)");
        else $display("FAIL: Expected 0x00000011");
        
        core_req = 1'b0;
        @(posedge clk);
        #20;

        // Test 2: Hit on same address
        $display("=== Test 2: Hit at 0x0000_0004 ===");
        core_addr = 32'h0000_0004;
        core_req = 1'b1;
        @(posedge clk); // LOOKUP
        if (core_stall === 1'b0 && core_ack === 1'b1) begin
            $display("PASS: Hit, no stall");
            $display("Data: 0x%08x", core_rdata);
            if (core_rdata === 32'h0000_0011) $display("PASS: Data correct");
            else $display("FAIL: Data mismatch");
        end else begin
            $display("FAIL: Should be a hit");
        end
        core_req = 1'b0;
        @(posedge clk);
        #20;

        // Test 3: Miss at different line (0x0000_0020)
        $display("=== Test 3: Miss at 0x0000_0020 ===");
        core_addr = 32'h0000_0020;
        core_req = 1'b1;
        wait(core_ack);
        @(posedge clk);
        $display("Data returned: 0x%08x", core_rdata);
        if (core_rdata === 32'h0000_0010) $display("PASS: Correct word (offset 0)");
        else $display("FAIL: Expected 0x00000010");
        core_req = 1'b0;
        @(posedge clk);
        #20;

        $display("=== ALL TESTS COMPLETE ===");
        $finish;
    end

endmodule