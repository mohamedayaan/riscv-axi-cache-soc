module axi_master (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] cache_addr,
    input  wire [31:0] cache_wdata,
    input  wire        cache_wen,
    input  wire        cache_req,
    output reg  [31:0] cache_rdata,
    output reg         cache_ack,
    output reg  [31:0] m_araddr,
    output reg         m_arvalid,
    input  wire        m_arready,
    input  wire [31:0] m_rdata,
    input  wire        m_rvalid,
    output reg         m_rready,
    output reg  [31:0] m_awaddr,
    output reg         m_awvalid,
    input  wire        m_awready,
    output reg  [31:0] m_wdata,
    output reg  [3:0]  m_wstrb,
    output reg         m_wvalid,
    input  wire        m_wready,
    input  wire        m_bvalid,
    output reg         m_bready
);
localparam IDLE=3'd0, AR=3'd1, RD=3'd2, AW=3'd3, WD=3'd4, BR=3'd5;
reg [2:0] state;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state<=IDLE; cache_ack<=0; cache_rdata<=0;
        m_arvalid<=0; m_araddr<=0; m_rready<=0;
        m_awvalid<=0; m_awaddr<=0;
        m_wvalid<=0; m_wdata<=0; m_wstrb<=4'b1111; m_bready<=0;
    end else begin
        cache_ack <= 0;
        case (state)
            IDLE: begin
                if (cache_req && !cache_wen) begin
                    m_araddr<=cache_addr; m_arvalid<=1; m_rready<=1; state<=AR;
                end else if (cache_req && cache_wen) begin
                    m_awaddr<=cache_addr; m_awvalid<=1;
                    m_wdata<=cache_wdata; m_wstrb<=4'b1111; m_wvalid<=1;
                    state<=AW;
                end
            end
            AR: if (m_arready) begin m_arvalid<=0; state<=RD; end
            RD: if (m_rvalid) begin
                cache_rdata<=m_rdata; cache_ack<=1; m_rready<=0; state<=IDLE;
            end
            AW: begin
                if (m_awready) m_awvalid<=0;
                if (m_wready)  m_wvalid<=0;
                if ((m_awready||!m_awvalid) && (m_wready||!m_wvalid)) begin
                    m_bready<=1; state<=BR;
                end
            end
            BR: if (m_bvalid) begin m_bready<=0; cache_ack<=1; state<=IDLE; end
            default: state<=IDLE;
        endcase
    end
end
endmodule
