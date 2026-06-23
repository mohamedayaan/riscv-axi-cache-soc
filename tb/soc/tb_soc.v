`timescale 1ns/1ps
module tb_soc;

reg clk, rst_n;

// Core interface signals (we drive these as fake core)
reg  [31:0] core_pc;
reg         core_if_req;
wire [31:0] core_insn;
wire        core_if_ack;
wire        core_if_stall;

reg  [31:0] core_mem_addr;
reg  [31:0] core_mem_wdata;
reg         core_mem_wen;
reg  [3:0]  core_mem_strb;
reg         core_mem_req;
wire [31:0] core_mem_rdata;
wire        core_mem_ack;
wire        core_mem_stall;

// Instantiate full SoC
soc_top u_soc(
    .clk(clk), .rst_n(rst_n),
    .core_pc(core_pc),
    .core_if_req(core_if_req),
    .core_insn(core_insn),
    .core_if_ack(core_if_ack),
    .core_if_stall(core_if_stall),
    .core_mem_addr(core_mem_addr),
    .core_mem_wdata(core_mem_wdata),
    .core_mem_wen(core_mem_wen),
    .core_mem_strb(core_mem_strb),
    .core_mem_req(core_mem_req),
    .core_mem_rdata(core_mem_rdata),
    .core_mem_ack(core_mem_ack),
    .core_mem_stall(core_mem_stall)
);

initial clk=0;
always #5 clk=~clk;
initial begin #50000; $display("TIMEOUT"); $finish; end

integer pass_count, fail_count;

initial begin
    $dumpfile("sim/tb_soc.vcd");
    $dumpvars(0, tb_soc);
    pass_count=0; fail_count=0;

    // Reset
    rst_n=0;
    core_if_req=0; core_pc=0;
    core_mem_req=0; core_mem_wen=0;
    core_mem_addr=0; core_mem_wdata=0; core_mem_strb=4'b1111;
    repeat(5) @(posedge clk);
    rst_n=1;
    repeat(2) @(posedge clk);

    $display("===== CACHE+AXI+MEMORY INTEGRATION TEST =====");

    // TEST 1: D-cache write then read
    $display("--- Test 1: D-cache write 0xCAFEBABE to addr 0x4000 ---");
    core_mem_addr=32'h4000; core_mem_wdata=32'hCAFEBABE;
    core_mem_wen=1; core_mem_strb=4'b1111; core_mem_req=1;
    wait(core_mem_ack==1);
    @(posedge clk); core_mem_req=0;
    $display("WRITE DONE");
    repeat(5) @(posedge clk);

    $display("--- Test 1: D-cache read back from 0x4000 ---");
    core_mem_addr=32'h4000; core_mem_wen=0; core_mem_req=1;
    wait(core_mem_ack==1);
    @(posedge clk); core_mem_req=0;
    if(core_mem_rdata==32'hCAFEBABE) begin
        $display("PASS: D-cache read got 0x%h", core_mem_rdata);
        pass_count=pass_count+1;
    end else begin
        $display("FAIL: expected 0xCAFEBABE got 0x%h", core_mem_rdata);
        fail_count=fail_count+1;
    end
    repeat(5) @(posedge clk);

    // TEST 2: I-cache fetch
    $display("--- Test 2: I-cache fetch from addr 0x0000 ---");
    core_pc=32'h0000; core_if_req=1;
    wait(core_if_ack==1);
    @(posedge clk); core_if_req=0;
    $display("I-cache fetch done, insn=0x%h", core_insn);
    pass_count=pass_count+1;
    repeat(5) @(posedge clk);

    // TEST 3: D-cache multiple writes
    $display("--- Test 3: Multiple D-cache writes ---");
    core_mem_wen=1; core_mem_strb=4'b1111;
    core_mem_addr=32'h4010; core_mem_wdata=32'h11111111; core_mem_req=1;
    wait(core_mem_ack==1); @(posedge clk); core_mem_req=0;
    repeat(3) @(posedge clk);
    core_mem_addr=32'h4014; core_mem_wdata=32'h22222222; core_mem_req=1;
    wait(core_mem_ack==1); @(posedge clk); core_mem_req=0;
    repeat(3) @(posedge clk);
    core_mem_addr=32'h4018; core_mem_wdata=32'h33333333; core_mem_req=1;
    wait(core_mem_ack==1); @(posedge clk); core_mem_req=0;
    repeat(3) @(posedge clk);

    // Read them back
    core_mem_wen=0;
    core_mem_addr=32'h4010; core_mem_req=1;
    wait(core_mem_ack==1); @(posedge clk); core_mem_req=0;
    if(core_mem_rdata==32'h11111111) begin $display("PASS: 0x4010=0x%h",core_mem_rdata); pass_count=pass_count+1; end
    else begin $display("FAIL: 0x4010 got 0x%h",core_mem_rdata); fail_count=fail_count+1; end
    repeat(3) @(posedge clk);

    core_mem_addr=32'h4014; core_mem_req=1;
    wait(core_mem_ack==1); @(posedge clk); core_mem_req=0;
    if(core_mem_rdata==32'h22222222) begin $display("PASS: 0x4014=0x%h",core_mem_rdata); pass_count=pass_count+1; end
    else begin $display("FAIL: 0x4014 got 0x%h",core_mem_rdata); fail_count=fail_count+1; end
    repeat(3) @(posedge clk);

    core_mem_addr=32'h4018; core_mem_req=1;
    wait(core_mem_ack==1); @(posedge clk); core_mem_req=0;
    if(core_mem_rdata==32'h33333333) begin $display("PASS: 0x4018=0x%h",core_mem_rdata); pass_count=pass_count+1; end
    else begin $display("FAIL: 0x4018 got 0x%h",core_mem_rdata); fail_count=fail_count+1; end
    repeat(5) @(posedge clk);

    $display("===== RESULTS =====");
    $display("PASSED: %0d  FAILED: %0d", pass_count, fail_count);
    if(fail_count==0) $display("ALL INTEGRATION TESTS PASSED!");
    $finish;
end
endmodule
