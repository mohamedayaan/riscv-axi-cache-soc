module soc_top (
    input  wire        clk,
    input  wire        rst_n,

    // Core interface (will connect to RISC-V core later)
    input  wire [31:0] core_pc,
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
    output wire        core_mem_stall
);

// Wires between cache_subsystem and axi_master
wire [31:0] cache_addr;
wire [31:0] cache_wdata;
wire        cache_wen;
wire        cache_req;
wire [7:0]  cache_burst_len;
wire [3:0]  cache_wstrb;
wire [31:0] cache_rdata;
wire        cache_ack;
wire        cache_last;

// AXI wires between master and slave
wire [3:0]  arid,  rid,  awid,  bid;
wire [31:0] araddr, rdata, awaddr, wdata;
wire [7:0]  arlen, awlen;
wire [2:0]  arsize, awsize;
wire [1:0]  arburst, awburst, rresp, bresp;
wire        arvalid, arready, rvalid, rready, rlast;
wire        awvalid, awready, wvalid, wready, wlast, bvalid, bready;
wire [3:0]  wstrb, mem_wstrb;

// Memory wires
wire [31:0] mem_addr, mem_wdata, mem_rdata;
wire        mem_wen, mem_ren, mem_rvalid;

// 1. Cache Subsystem (friend's module)
cache_subsystem u_cache(
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
    .core_mem_stall(core_mem_stall),
    .cache_addr(cache_addr),
    .cache_wdata(cache_wdata),
    .cache_wen(cache_wen),
    .cache_req(cache_req),
    .cache_burst_len(cache_burst_len),
    .cache_wstrb(cache_wstrb),
    .cache_rdata(cache_rdata),
    .cache_ack(cache_ack),
    .cache_last(cache_last)
);

// 2. AXI Master (your module)
axi_master u_master(
    .clk(clk), .rst_n(rst_n),
    .cache_addr(cache_addr), .cache_wdata(cache_wdata),
    .cache_wen(cache_wen), .cache_req(cache_req),
    .cache_burst_len(cache_burst_len), .cache_wstrb(cache_wstrb),
    .cache_rdata(cache_rdata), .cache_ack(cache_ack), .cache_last(cache_last),
    .m_arid(arid), .m_araddr(araddr), .m_arlen(arlen),
    .m_arsize(arsize), .m_arburst(arburst),
    .m_arvalid(arvalid), .m_arready(arready),
    .m_rid(rid), .m_rdata(rdata), .m_rresp(rresp),
    .m_rlast(rlast), .m_rvalid(rvalid), .m_rready(rready),
    .m_awid(awid), .m_awaddr(awaddr), .m_awlen(awlen),
    .m_awsize(awsize), .m_awburst(awburst),
    .m_awvalid(awvalid), .m_awready(awready),
    .m_wdata(wdata), .m_wstrb(wstrb), .m_wlast(wlast),
    .m_wvalid(wvalid), .m_wready(wready),
    .m_bid(bid), .m_bresp(bresp), .m_bvalid(bvalid), .m_bready(bready)
);

// 3. AXI Slave (your module)
axi_slave u_slave(
    .clk(clk), .rst_n(rst_n),
    .s_arid(arid), .s_araddr(araddr), .s_arlen(arlen),
    .s_arsize(arsize), .s_arburst(arburst),
    .s_arvalid(arvalid), .s_arready(arready),
    .s_rid(rid), .s_rdata(rdata), .s_rresp(rresp),
    .s_rlast(rlast), .s_rvalid(rvalid), .s_rready(rready),
    .s_awid(awid), .s_awaddr(awaddr), .s_awlen(awlen),
    .s_awsize(awsize), .s_awburst(awburst),
    .s_awvalid(awvalid), .s_awready(awready),
    .s_wdata(wdata), .s_wstrb(wstrb), .s_wlast(wlast),
    .s_wvalid(wvalid), .s_wready(wready),
    .s_bid(bid), .s_bresp(bresp), .s_bvalid(bvalid), .s_bready(bready),
    .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb),
    .mem_wen(mem_wen), .mem_ren(mem_ren),
    .mem_rdata(mem_rdata), .mem_rvalid(mem_rvalid)
);

// 4. Memory Model (your module)
mem_model u_mem(
    .clk(clk), .rst_n(rst_n),
    .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb),
    .mem_wen(mem_wen), .mem_ren(mem_ren),
    .mem_rdata(mem_rdata), .mem_rvalid(mem_rvalid)
);

endmodule
