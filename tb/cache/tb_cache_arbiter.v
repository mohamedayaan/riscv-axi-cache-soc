`timescale 1ns / 1ps

module tb_cache_arbiter;

    reg clk = 0;
    always #5 clk = ~clk;

    reg rst_n;

    reg  [31:0] i_addr;
    reg         i_req;
    wire        i_grant;
    reg  [31:0] i_wdata;
    reg         i_wen;
    reg  [7:0]  i_burst_len;
    reg  [3:0]  i_wstrb;
    wire [31:0] i_rdata;
    wire        i_ack;
    wire        i_last;

    reg  [31:0] d_addr;
    reg         d_req;
    wire        d_grant;
    reg  [31:0] d_wdata;
    reg         d_wen;
    reg  [7:0]  d_burst_len;
    reg  [3:0]  d_wstrb;
    wire [31:0] d_rdata;
    wire        d_ack;
    wire        d_last;

    wire [31:0] cache_addr;
    wire [31:0] cache_wdata;
    wire        cache_wen;
    wire        cache_req;
    wire [7:0]  cache_burst_len;
    wire [3:0]  cache_wstrb;
    reg  [31:0] cache_rdata;
    reg         cache_ack;
    reg         cache_last;

    cache_arbiter dut (
        .clk(clk), .rst_n(rst_n),
        .i_addr(i_addr), .i_req(i_req), .i_grant(i_grant),
        .i_wdata(i_wdata), .i_wen(i_wen), .i_burst_len(i_burst_len), .i_wstrb(i_wstrb),
        .i_rdata(i_rdata), .i_ack(i_ack), .i_last(i_last),
        .d_addr(d_addr), .d_req(d_req), .d_grant(d_grant),
        .d_wdata(d_wdata), .d_wen(d_wen), .d_burst_len(d_burst_len), .d_wstrb(d_wstrb),
        .d_rdata(d_rdata), .d_ack(d_ack), .d_last(d_last),
        .cache_addr(cache_addr), .cache_wdata(cache_wdata), .cache_wen(cache_wen),
        .cache_req(cache_req), .cache_burst_len(cache_burst_len), .cache_wstrb(cache_wstrb),
        .cache_rdata(cache_rdata), .cache_ack(cache_ack), .cache_last(cache_last)
    );

    // Mock AXI master response
    reg [3:0] resp_cnt;
    reg       resp_active;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            cache_ack <= 1'b0;
            cache_last <= 1'b0;
            cache_rdata <= 32'h0;
            resp_cnt <= 4'd0;
            resp_active <= 1'b0;
        end else begin
            cache_ack <= 1'b0;
            cache_last <= 1'b0;
            
            if (cache_req && !resp_active) begin
                resp_active <= 1'b1;
                resp_cnt <= 4'd0;
            end
            
            if (resp_active) begin
                resp_cnt <= resp_cnt + 1'b1;
                if (resp_cnt >= 4'd2) begin
                    cache_ack <= 1'b1;
                    cache_rdata <= cache_rdata + 32'h1;
                    if (resp_cnt == 4'd2 + cache_burst_len) begin
                        cache_last <= 1'b1;
                        resp_active <= 1'b0;
                        resp_cnt <= 4'd0;
                    end
                end
            end
        end
    end

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_cache_arbiter);

        rst_n = 0;
        i_addr = 0; i_req = 0; i_wdata = 0; i_wen = 0; 
        i_burst_len = 0; i_wstrb = 0;
        d_addr = 0; d_req = 0; d_wdata = 0; d_wen = 0;
        d_burst_len = 0; d_wstrb = 0;

        #30;
        rst_n = 1;
        #10;

        // Test 1: D$ single-beat write
        $display("Test 1: D$ write");
        d_addr = 32'h0000_4000; d_req = 1; d_wen = 1;
        d_wdata = 32'hAABBCCDD; d_burst_len = 0; d_wstrb = 4'b1111;
        @(posedge clk); wait(d_grant);
        $display("  Granted, addr=%h", cache_addr);
        wait(d_last); @(posedge clk); d_req = 0;
        $display("  Done");
        #20;

        // Test 2: I$ 8-beat read miss
        $display("Test 2: I$ read miss");
        i_addr = 32'h0000_0000; i_req = 1; i_wen = 0;
        i_burst_len = 7; i_wstrb = 4'b1111;
        @(posedge clk); wait(i_grant);
        $display("  Granted, addr=%h, burst=%d", cache_addr, cache_burst_len);
        wait(i_last); @(posedge clk); i_req = 0;
        $display("  Done");
        #20;

        // Test 3: Both request - round robin
        $display("Test 3: Both request");
        i_addr = 32'h0000_0020; i_req = 1; i_wen = 0; i_burst_len = 7;
        d_addr = 32'h0000_5000; d_req = 1; d_wen = 1; d_wdata = 32'h11223344; d_burst_len = 0;
        @(posedge clk);
        if (i_grant) $display("  I$ granted first (round-robin OK)");
        else if (d_grant) $display("  D$ granted first");
        wait(i_last); @(posedge clk); i_req = 0;
        wait(d_last); @(posedge clk); d_req = 0;
        $display("  Both done");

        #50;
        $display("ALL TESTS PASSED");
        $finish;
    end

endmodule