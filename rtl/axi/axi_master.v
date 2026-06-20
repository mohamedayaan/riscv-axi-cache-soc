module axi_master (
    input  wire        clk,
    input  wire        rst_n,

    // Cache-side interface
    input  wire [31:0] cache_addr,
    input  wire [31:0] cache_wdata,
    input  wire        cache_wen,
    input  wire        cache_req,
    output reg  [31:0] cache_rdata,
    output reg         cache_ack,

    // AR channel (Read Address)
    output reg  [31:0] m_araddr,
    output reg         m_arvalid,
    input  wire        m_arready,

    // R channel (Read Data)
    input  wire [31:0] m_rdata,
    input  wire [1:0]  m_rresp,
    input  wire        m_rvalid,
    output reg         m_rready,

    // AW channel (Write Address)
    output reg  [31:0] m_awaddr,
    output reg         m_awvalid,
    input  wire        m_awready,

    // W channel (Write Data)
    output reg  [31:0] m_wdata,
    output reg  [3:0]  m_wstrb,
    output reg         m_wvalid,
    input  wire        m_wready,

    // B channel (Write Response)
    input  wire [1:0]  m_bresp,
    input  wire        m_bvalid,
    output reg         m_bready
);

// FSM States
localparam IDLE     = 3'd0;
localparam AR_VALID = 3'd1;
localparam R_DATA   = 3'd2;
localparam AW_VALID = 3'd3;
localparam W_DATA   = 3'd4;
localparam B_RESP   = 3'd5;

reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state      <= IDLE;
        cache_ack  <= 0;
        cache_rdata<= 0;
        m_arvalid  <= 0;
        m_araddr   <= 0;
        m_rready   <= 0;
        m_awvalid  <= 0;
        m_awaddr   <= 0;
        m_wvalid   <= 0;
        m_wdata    <= 0;
        m_wstrb    <= 4'b1111;
        m_bready   <= 0;
    end else begin
        case (state)
            IDLE: begin
                cache_ack <= 0;
                if (cache_req && !cache_wen) begin
                    // Read request
                    m_araddr  <= cache_addr;
                    m_arvalid <= 1;
                    state     <= AR_VALID;
                end else if (cache_req && cache_wen) begin
                    // Write request
                    m_awaddr  <= cache_addr;
                    m_awvalid <= 1;
                    state     <= AW_VALID;
                end
            end

            AR_VALID: begin
                if (m_arready) begin
                    m_arvalid <= 0;
                    m_rready  <= 1;
                    state     <= R_DATA;
                end
            end

            R_DATA: begin
                if (m_rvalid) begin
                    cache_rdata <= m_rdata;
                    cache_ack   <= 1;
                    m_rready    <= 0;
                    state       <= IDLE;
                end
            end

            AW_VALID: begin
                if (m_awready) begin
                    m_awvalid <= 0;
                    m_wdata   <= cache_wdata;
                    m_wstrb   <= 4'b1111;
                    m_wvalid  <= 1;
                    state     <= W_DATA;
                end
            end

            W_DATA: begin
                if (m_wready) begin
                    m_wvalid <= 0;
                    m_bready <= 1;
                    state    <= B_RESP;
                end
            end

            B_RESP: begin
                if (m_bvalid) begin
                    m_bready  <= 0;
                    cache_ack <= 1;
                    state     <= IDLE;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
