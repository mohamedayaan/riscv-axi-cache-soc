module soc_top (
    input wire clk,
    input wire rst_n
);

// ─────────────────────────────────────────
// Wires connecting Cache <-> AXI Master
// ─────────────────────────────────────────
wire [31:0] cache_addr;
wire [31:0] cache_wdata;
wire        cache_wen;
wire        cache_req;
wire [31:0] cache_rdata;
wire        cache_ack;

// ─────────────────────────────────────────
// Wires connecting AXI Master <-> AXI Slave
// ─────────────────────────────────────────

// AR channel
wire [31:0] araddr;
wire        arvalid;
wire        arready;

// R channel
wire [31:0] rdata;
wire [1:0]  rresp;
wire        rvalid;
wire        rready;

// AW channel
wire [31:0] awaddr;
wire        awvalid;
wire        awready;

// W channel
wire [31:0] wdata;
wire [3:0]  wstrb;
wire        wvalid;
wire        wready;

// B channel
wire [1:0]  bresp;
wire        bvalid;
wire        bready;

// ─────────────────────────────────────────
// Wires connecting AXI Slave <-> Memory
// ─────────────────────────────────────────
wire [31:0] mem_addr;
wire [31:0] mem_wdata;
wire [3:0]  mem_wstrb;
wire        mem_wen;
wire        mem_ren;
wire [31:0] mem_rdata;
wire        mem_ready;

// ─────────────────────────────────────────
// Module Instantiations
// ─────────────────────────────────────────

// 1. AXI Master
axi_master u_axi_master (
    .clk         (clk),
    .rst_n       (rst_n),
    .cache_addr  (cache_addr),
    .cache_wdata (cache_wdata),
    .cache_wen   (cache_wen),
    .cache_req   (cache_req),
    .cache_rdata (cache_rdata),
    .cache_ack   (cache_ack),
    .m_araddr    (araddr),
    .m_arvalid   (arvalid),
    .m_arready   (arready),
    .m_rdata     (rdata),
    .m_rresp     (rresp),
    .m_rvalid    (rvalid),
    .m_rready    (rready),
    .m_awaddr    (awaddr),
    .m_awvalid   (awvalid),
    .m_awready   (awready),
    .m_wdata     (wdata),
    .m_wstrb     (wstrb),
    .m_wvalid    (wvalid),
    .m_wready    (wready),
    .m_bresp     (bresp),
    .m_bvalid    (bvalid),
    .m_bready    (bready)
);

// 2. AXI Slave
axi_slave u_axi_slave (
    .clk        (clk),
    .rst_n      (rst_n),
    .s_araddr   (araddr),
    .s_arvalid  (arvalid),
    .s_arready  (arready),
    .s_rdata    (rdata),
    .s_rresp    (rresp),
    .s_rvalid   (rvalid),
    .s_rready   (rready),
    .s_awaddr   (awaddr),
    .s_awvalid  (awvalid),
    .s_awready  (awready),
    .s_wdata    (wdata),
    .s_wstrb    (wstrb),
    .s_wvalid   (wvalid),
    .s_wready   (wready),
    .s_bresp    (bresp),
    .s_bvalid   (bvalid),
    .s_bready   (bready),
    .mem_addr   (mem_addr),
    .mem_wdata  (mem_wdata),
    .mem_wstrb  (mem_wstrb),
    .mem_wen    (mem_wen),
    .mem_ren    (mem_ren),
    .mem_rdata  (mem_rdata),
    .mem_ready  (mem_ready)
);

// 3. Memory Model
mem_model u_mem_model (
    .clk        (clk),
    .rst_n      (rst_n),
    .s_araddr   (mem_addr),
    .s_arvalid  (mem_ren),
    .s_arready  (),
    .s_rdata    (mem_rdata),
    .s_rresp    (),
    .s_rvalid   (mem_ready),
    .s_rready   (1'b1),
    .s_awaddr   (mem_addr),
    .s_awvalid  (mem_wen),
    .s_awready  (),
    .s_wdata    (mem_wdata),
    .s_wstrb    (mem_wstrb),
    .s_wvalid   (mem_wen),
    .s_wready   (),
    .s_bresp    (),
    .s_bvalid   (),
    .s_bready   (1'b1)
);

endmodule
