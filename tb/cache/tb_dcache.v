`timescale 1ns / 1ps

module tb_dcache;

    reg clk = 0;
    always #5 clk = ~clk;

    reg rst_n;

    // Core interface
    reg  [31:0] core_addr;
    reg  [31:0] core_wdata;
    reg         core_wen;
    reg  [3:0]  core_strb;
    reg         core_req;
    wire        core_ack;
    wire [31:0] core_rdata;
    wire        core_stall;

    // Arbiter interface (mock)
    wire [31:0] d_addr;
    wire        d_req;
    reg         d_grant;
    wire [31:0] d_wdata;
    wire        d_wen;
    wire [7:0]  d_burst_len;
    wire [3:0]  d_wstrb;
    reg  [31:0] d_rdata;
    reg         d_ack;
    reg         d_last;

    dcache dut (
        .clk(clk), .rst_n(rst_n),
        .core_addr(core_addr), .core_wdata(core_wdata), .core_wen(core_wen),
        .core_strb(core_strb), .core_req(core_req),
        .core_ack(core_ack), .core_rdata(core_rdata), .core_stall(core_stall),
        .d_addr(d_addr), .d_req(d_req), .d_grant(d_grant),
        .d_wdata(d_wdata), .d_wen(d_wen), .d_burst_len(d_burst_len), .d_wstrb(d_wstrb),
        .d_rdata(d_rdata), .d_ack(d_ack), .d_last(d_last)
    );

    // Mock arbiter response
    reg [3:0] beat_cnt;
    reg       resp_active;
    reg       is_write_resp;

    always @(posedge clk) begin
        if (!rst_n) begin
            d_grant <= 1'b0; d_ack <= 1'b0; d_last <= 1'b0;
            d_rdata <= 32'h0; beat_cnt <= 4'd0; resp_active <= 1'b0; is_write_resp <= 1'b0;
        end else begin
            d_grant <= 1'b0; d_ack <= 1'b0; d_last <= 1'b0;

            if (d_req && !resp_active) begin
                d_grant <= 1'b1;
                resp_active <= 1'b1;
                beat_cnt <= 4'd0;
                is_write_resp <= d_wen;  // remember if this was a write
            end

            if (resp_active) begin
                if (is_write_resp) begin
                    // Single-beat write response
                    d_ack <= 1'b1;
                    resp_active <= 1'b0;
                end else begin
                    // 8-beat read burst
                    d_ack <= 1'b1;
                    d_rdata <= {24'h0, 8'h20 + beat_cnt};
                    if (beat_cnt == 4'd7) begin
                        d_last <= 1'b1;
                        resp_active <= 1'b0;
                    end
                    beat_cnt <= beat_cnt + 1'b1;
                end
            end
        end
    end

    initial begin
        $dumpfile("waves_dcache.vcd");
        $dumpvars(0, tb_dcache);

        rst_n = 0;
        core_addr = 0; core_wdata = 0; core_wen = 0; core_strb = 0; core_req = 0;
        d_rdata = 0; d_ack = 0; d_last = 0; d_grant = 0;

        #30; rst_n = 1; #10;

        // Test 1: Read miss
        $display("=== Test 1: Read miss at 0x4000 ===");
        core_addr = 32'h0000_4000; core_wen = 0; core_strb = 4'b1111; core_req = 1;
        wait(core_ack); @(posedge clk);
        $display("Data: 0x%08x", core_rdata);
        if (core_rdata === 32'h0000_0020) $display("PASS");
        else $display("FAIL: Expected 0x00000020");
        core_req = 0; @(posedge clk); #20;

        // Test 2: Read hit
        $display("=== Test 2: Read hit at 0x4000 ===");
        core_addr = 32'h0000_4000; core_wen = 0; core_strb = 4'b1111; core_req = 1;
        wait(core_ack); @(posedge clk);
        $display("Data: 0x%08x", core_rdata);
        if (core_rdata === 32'h0000_0020) $display("PASS");
        else $display("FAIL");
        core_req = 0; @(posedge clk); #20;

        // Test 3: Write hit
        $display("=== Test 3: Write hit at 0x4000 ===");
        core_addr = 32'h0000_4000; core_wdata = 32'hDEADBEEF; core_wen = 1;
        core_strb = 4'b1111; core_req = 1;
        wait(core_ack); @(posedge clk);
        $display("Write ack received");
        core_req = 0; @(posedge clk); #20;

        // Test 4: Read hit after write (verify write-through updated cache)
        $display("=== Test 4: Read hit after write ===");
        core_addr = 32'h0000_4000; core_wen = 0; core_strb = 4'b1111; core_req = 1;
        wait(core_ack); @(posedge clk);
        $display("Data: 0x%08x", core_rdata);
        if (core_rdata === 32'hDEADBEEF) $display("PASS: Write-through worked");
        else $display("FAIL: Expected 0xDEADBEEF");
        core_req = 0; @(posedge clk); #20;

        // Test 5: Write miss (no-allocate)
        $display("=== Test 5: Write miss at 0x5000 ===");
        core_addr = 32'h0000_5000; core_wdata = 32'hCAFEBABE; core_wen = 1;
        core_strb = 4'b1111; core_req = 1;
        wait(core_ack); @(posedge clk);
        $display("Write miss ack received");
        core_req = 0; @(posedge clk); #20;

        $display("=== ALL TESTS COMPLETE ===");
        $finish;
    end

endmodule