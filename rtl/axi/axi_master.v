module axi_master (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] cache_addr,
    input  wire [31:0] cache_wdata,
    input  wire        cache_wen,
    input  wire        cache_req,
    input  wire [7:0]  cache_burst_len,
    input  wire [3:0]  cache_wstrb,
    output reg  [31:0] cache_rdata,
    output reg         cache_ack,
    output reg         cache_last,
    output reg  [3:0]  m_arid,
    output reg  [31:0] m_araddr,
    output reg  [7:0]  m_arlen,
    output reg  [2:0]  m_arsize,
    output reg  [1:0]  m_arburst,
    output reg         m_arvalid,
    input  wire        m_arready,
    input  wire [3:0]  m_rid,
    input  wire [31:0] m_rdata,
    input  wire [1:0]  m_rresp,
    input  wire        m_rlast,
    input  wire        m_rvalid,
    output reg         m_rready,
    output reg  [3:0]  m_awid,
    output reg  [31:0] m_awaddr,
    output reg  [7:0]  m_awlen,
    output reg  [2:0]  m_awsize,
    output reg  [1:0]  m_awburst,
    output reg         m_awvalid,
    input  wire        m_awready,
    output reg  [31:0] m_wdata,
    output reg  [3:0]  m_wstrb,
    output reg         m_wlast,
    output reg         m_wvalid,
    input  wire        m_wready,
    input  wire [3:0]  m_bid,
    input  wire [1:0]  m_bresp,
    input  wire        m_bvalid,
    output reg         m_bready
);
localparam IDLE=3'd0,AR=3'd1,RD=3'd2,AW=3'd3,WD=3'd4,BR=3'd5;
reg [2:0] state;
reg [7:0] burst_len_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state<=IDLE; cache_ack<=0; cache_rdata<=0; cache_last<=0;
        m_arid<=0; m_araddr<=0; m_arlen<=0; m_arsize<=3'b010; m_arburst<=2'b01; m_arvalid<=0; m_rready<=0;
        m_awid<=0; m_awaddr<=0; m_awlen<=0; m_awsize<=3'b010; m_awburst<=2'b01; m_awvalid<=0;
        m_wdata<=0; m_wstrb<=4'b1111; m_wlast<=0; m_wvalid<=0;
        m_bready<=0; burst_len_reg<=0;
    end else begin
        cache_ack<=0; cache_last<=0;
        case (state)
            IDLE: begin
                if (cache_req && !cache_wen) begin
                    m_arid<=4'd0; m_araddr<=cache_addr; m_arlen<=cache_burst_len;
                    m_arsize<=3'b010; m_arburst<=2'b01; m_arvalid<=1; m_rready<=1;
                    burst_len_reg<=cache_burst_len; state<=AR;
                end else if (cache_req && cache_wen) begin
                    m_awid<=4'd0; m_awaddr<=cache_addr; m_awlen<=8'd0;
                    m_awsize<=3'b010; m_awburst<=2'b01; m_awvalid<=1;
                    m_wdata<=cache_wdata; m_wstrb<=cache_wstrb;
                    m_wvalid<=1; m_wlast<=1; state<=AW;
                end
            end
            AR: if(m_arready) begin m_arvalid<=0; state<=RD; end
            RD: if(m_rvalid) begin
                cache_rdata<=m_rdata; cache_ack<=1;
                if(m_rlast) begin cache_last<=1; m_rready<=0; state<=IDLE; end
            end
            AW: begin
                if(m_awready) m_awvalid<=0;
                if(m_wready) begin
                    m_wvalid<=0; m_wlast<=0;
                    if(!m_awvalid) begin m_bready<=1; state<=BR; end
                    else state<=WD;
                end
            end
            WD: if(m_awready) begin m_awvalid<=0; m_bready<=1; state<=BR; end
            BR: if(m_bvalid) begin m_bready<=0; cache_ack<=1; state<=IDLE; end
            default: state<=IDLE;
        endcase
    end
end
endmodule
