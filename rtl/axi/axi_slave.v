module axi_slave (
    input  wire        clk,
    input  wire        rst_n,

    // AR channel (Read Address) - receiving from master
    input  wire [31:0] s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,

    // R channel (Read Data) - sending to master
    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready,

    // AW channel (Write Address) - receiving from master
    input  wire [31:0] s_awaddr,
    input  wire        s_awvalid,
    output reg         s_awready,

    // W channel (Write Data) - receiving from master
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output reg         s_wready,

    // B channel (Write Response) - sending to master
    output reg  [1:0]  s_bresp,
    output reg         s_bvalid,
    input  wire        s_bready,

    // Memory interface
    output reg  [31:0] mem_addr,
    output reg  [31:0] mem_wdata,
    output reg  [3:0]  mem_wstrb,
    output reg         mem_wen,
    output reg         mem_ren,
    input  wire [31:0] mem_rdata,
    input  wire        mem_ready
);

// FSM States
localparam IDLE   = 3'd0;
localparam R_WAIT = 3'd1;
localparam R_RESP = 3'd2;
localparam W_ADDR = 3'd3;
localparam W_DATA = 3'd4;
localparam W_RESP = 3'd5;

reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state      <= IDLE;
        s_arready  <= 0;
        s_rvalid   <= 0;
        s_rdata    <= 0;
        s_rresp    <= 2'b00;
        s_awready  <= 0;
        s_wready   <= 0;
        s_bvalid   <= 0;
        s_bresp    <= 2'b00;
        mem_wen    <= 0;
        mem_ren    <= 0;
    end else begin
        case (state)

            // Waiting for any request
            IDLE: begin
                s_arready <= 1;
                s_awready <= 1;
                mem_ren   <= 0;
                mem_wen   <= 0;

                if (s_arvalid) begin
                    // Read request coming in
                    mem_addr  <= s_araddr;
                    mem_ren   <= 1;
                    s_arready <= 0;
                    s_awready <= 0;
                    state     <= R_WAIT;
                end else if (s_awvalid) begin
                    // Write request coming in
                    mem_addr  <= s_awaddr;
                    s_awready <= 0;
                    s_arready <= 0;
                    s_wready  <= 1;
                    state     <= W_DATA;
                end
            end

            // Wait for memory to return read data
            R_WAIT: begin
                mem_ren <= 0;
                if (mem_ready) begin
                    s_rdata  <= mem_rdata;
                    s_rresp  <= 2'b00; // OKAY
                    s_rvalid <= 1;
                    state    <= R_RESP;
                end
            end

            // Send read data back to master
            R_RESP: begin
                if (s_rready) begin
                    s_rvalid <= 0;
                    state    <= IDLE;
                end
            end

            // Receive write data from master
            W_DATA: begin
                if (s_wvalid) begin
                    mem_wdata <= s_wdata;
                    mem_wstrb <= s_wstrb;
                    mem_wen   <= 1;
                    s_wready  <= 0;
                    state     <= W_RESP;
                end
            end

            // Send write response back to master
            W_RESP: begin
                mem_wen  <= 0;
                s_bvalid <= 1;
                s_bresp  <= 2'b00; // OKAY
                if (s_bready) begin
                    s_bvalid <= 0;
                    state    <= IDLE;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
