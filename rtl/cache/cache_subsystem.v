module cache_subsystem (
    input  wire        clk,
    input  wire        rst_n,
    
    // Core interface
    input  wire [31:0] core_pc,        // IF stage PC
    input  wire        core_if_req,
    output wire [31:0] core_insn,
    output wire        core_if_ack,
    output wire        core_if_stall,
    
    input  wire [31:0] core_mem_addr,
    input  wire [31:0] core_mem_wdata,
    input  wire        core_mem_wen,
    input  wire [3:0]  core_mem_strb,
    input  wire        core_mem_req,
    output wire [31:0] core_mem_rdata,
    output wire        core_mem_ack,
    output wire        core_mem_stall,
    
    // To Ayaan's axi_master
    output wire [31:0] cache_addr,
    output wire [31:0] cache_wdata,
    output wire        cache_wen,
    output wire        cache_req,
    output wire [7:0]  cache_burst_len,
    output wire [3:0]  cache_wstrb,
    input  wire [31:0] cache_rdata,
    input  wire        cache_ack,
    input  wire        cache_last
);

    // Internal wires between I$/D$ and arbiter
    wire [31:0] i_addr, i_wdata;
    wire        i_req, i_grant, i_wen;
    wire [7:0]  i_burst_len;
    wire [3:0]  i_wstrb;
    wire [31:0] i_rdata;
    wire        i_ack, i_last;

    wire [31:0] d_addr, d_wdata;
    wire        d_req, d_grant, d_wen;
    wire [7:0]  d_burst_len;
    wire [3:0]  d_wstrb;
    wire [31:0] d_rdata;
    wire        d_ack, d_last;

    // I-cache instance
    icache icache_inst (
        .clk(clk), .rst_n(rst_n),
        .core_addr(core_pc),
        .core_req(core_if_req),
        .core_ack(core_if_ack),
        .core_rdata(core_insn),
        .core_stall(core_if_stall),
        .i_addr(i_addr), .i_req(i_req), .i_grant(i_grant),
        .i_wdata(i_wdata), .i_wen(i_wen), .i_burst_len(i_burst_len), .i_wstrb(i_wstrb),
        .i_rdata(i_rdata), .i_ack(i_ack), .i_last(i_last)
    );

    // D-cache instance
    dcache dcache_inst (
        .clk(clk), .rst_n(rst_n),
        .core_addr(core_mem_addr),
        .core_wdata(core_mem_wdata),
        .core_wen(core_mem_wen),
        .core_strb(core_mem_strb),
        .core_req(core_mem_req),
        .core_ack(core_mem_ack),
        .core_rdata(core_mem_rdata),
        .core_stall(core_mem_stall),
        .d_addr(d_addr), .d_req(d_req), .d_grant(d_grant),
        .d_wdata(d_wdata), .d_wen(d_wen), .d_burst_len(d_burst_len), .d_wstrb(d_wstrb),
        .d_rdata(d_rdata), .d_ack(d_ack), .d_last(d_last)
    );

    // Arbiter instance
    cache_arbiter arbiter_inst (
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

endmodule