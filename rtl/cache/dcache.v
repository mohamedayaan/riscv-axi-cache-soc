module dcache (
    input  wire        clk,
    input  wire        rst_n,
    
    input  wire [31:0] core_addr,
    input  wire [31:0] core_wdata,
    input  wire        core_wen,
    input  wire [3:0]  core_strb,
    input  wire        core_req,
    output reg         core_ack,
    output reg  [31:0] core_rdata,
    output reg         core_stall,
    
    output reg  [31:0] d_addr,
    output reg         d_req,
    input  wire        d_grant,
    output reg  [31:0] d_wdata,
    output reg         d_wen,
    output reg  [7:0]  d_burst_len,
    output reg  [3:0]  d_wstrb,
    input  wire [31:0] d_rdata,
    input  wire        d_ack,
    input  wire        d_last
);

    localparam IDLE=0, READ_MISS=1, READ_REFILL=2, READ_DONE=3, 
               WRITE_HIT=4, WRITE_MISS=5, WRITE_UPDATE=6;
    reg [2:0] state;

    reg [20:0] tag_array [0:63];
    reg [31:0] data_array [0:63][0:7];
    reg        valid_array [0:63];

    // Registered copies of the request, latched as we LEAVE idle
    // (used by downstream states; safe because they're registered
    // on the same edge the FSM transitions out of IDLE)
    reg [5:0]  r_idx;
    reg [20:0] r_tag;
    reg [2:0]  r_woff;
    reg [3:0]  r_strb;
    reg [31:0] r_wdata;
    reg        r_wen;
    reg [31:0] r_addr;

    // IMPORTANT: decode the live, current-cycle inputs in IDLE.
    // Do NOT use r_idx/r_tag/r_wen for the IDLE decision -- those
    // still hold the *previous* transaction's values on the cycle
    // a new request first arrives.
    wire [5:0]  cur_idx = core_addr[10:5];
    wire [20:0] cur_tag = core_addr[31:11];
    wire        cur_hit = valid_array[cur_idx] && (tag_array[cur_idx] == cur_tag);

    reg [5:0]  miss_idx;
    reg [20:0] miss_tag;
    reg [2:0]  miss_woff;
    reg [3:0]  beat_cnt;
    reg [31:0] line_buffer [0:7];

    integer i, j;

    // Latch the request as we transition OUT of IDLE into a working
    // state, so downstream states have a stable snapshot of this
    // transaction's address/data that won't change even if core_addr
    // changes on the next cycle.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_idx <= 0; r_tag <= 0; r_woff <= 0;
            r_strb <= 0; r_wdata <= 0; r_wen <= 0; r_addr <= 0;
        end else if (state == IDLE && core_req) begin
            r_idx   <= cur_idx;
            r_tag   <= cur_tag;
            r_woff  <= core_addr[4:2];
            r_strb  <= core_strb;
            r_wdata <= core_wdata;
            r_wen   <= core_wen;
            r_addr  <= core_addr;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            core_ack <= 0; core_rdata <= 0; core_stall <= 0;
            d_req <= 0; d_addr <= 0; d_wdata <= 0; d_wen <= 0;
            d_burst_len <= 0; d_wstrb <= 0; beat_cnt <= 0;
            miss_idx <= 0; miss_tag <= 0; miss_woff <= 0;
            for (i=0; i<64; i=i+1) begin
                valid_array[i] <= 0; tag_array[i] <= 0;
                for (j=0; j<8; j=j+1) data_array[i][j] <= 0;
            end
            for (i=0; i<8; i=i+1) line_buffer[i] <= 0;
        end else begin
            core_ack <= 0;

            case (state)
                IDLE: begin
                    core_stall <= 0;
                    if (core_req) begin
                        if (core_wen) begin
                            if (cur_hit) begin
                                core_stall <= 1;
                                state <= WRITE_UPDATE;  // Go to update state first
                            end else begin
                                core_stall <= 1;
                                state <= WRITE_MISS;
                            end
                        end else begin
                            if (cur_hit) begin
                                core_rdata <= data_array[cur_idx][core_addr[4:2]];
                                core_ack <= 1;
                            end else begin
                                miss_idx <= cur_idx;
                                miss_tag <= cur_tag;
                                miss_woff <= core_addr[4:2];
                                d_addr <= {core_addr[31:5], 5'b0};
                                d_req <= 1; d_wen <= 0;
                                d_burst_len <= 7; d_wstrb <= 4'b1111;
                                core_stall <= 1;
                                state <= READ_MISS;
                            end
                        end
                    end
                end

                WRITE_UPDATE: begin
                    // Update cache array here, then go to write-through.
                    // r_idx/r_woff/r_wdata were latched this transaction
                    // (on the edge we left IDLE), so they're correct here.
                    data_array[r_idx][r_woff] <= r_wdata;
                    state <= WRITE_HIT;
                end

                WRITE_HIT: begin
                    if (!d_req && !d_grant) begin
                        d_addr <= {r_addr[31:2], 2'b0};
                        d_wdata <= r_wdata; d_wen <= 1;
                        d_burst_len <= 0; d_wstrb <= r_strb;
                        d_req <= 1;
                    end else if (d_grant) begin
                        d_req <= 0;
                    end
                    if (d_ack) begin
                        core_ack <= 1; core_stall <= 0;
                        state <= IDLE;
                    end
                end

                WRITE_MISS: begin
                    if (!d_req && !d_grant) begin
                        d_addr <= {r_addr[31:2], 2'b0};
                        d_wdata <= r_wdata; d_wen <= 1;
                        d_burst_len <= 0; d_wstrb <= r_strb;
                        d_req <= 1;
                    end else if (d_grant) begin
                        d_req <= 0;
                    end
                    if (d_ack) begin
                        core_ack <= 1; core_stall <= 0;
                        state <= IDLE;
                    end
                end

                READ_MISS: begin
                    if (d_grant) begin
                        d_req <= 0; beat_cnt <= 0;
                        state <= READ_REFILL;
                    end
                end

                READ_REFILL: begin
                    if (d_ack) begin
                        line_buffer[beat_cnt] <= d_rdata;
                        beat_cnt <= beat_cnt + 1;
                        if (d_last) state <= READ_DONE;
                    end
                end

                READ_DONE: begin
                    tag_array[miss_idx] <= miss_tag;
                    valid_array[miss_idx] <= 1;
                    data_array[miss_idx][0] <= line_buffer[0];
                    data_array[miss_idx][1] <= line_buffer[1];
                    data_array[miss_idx][2] <= line_buffer[2];
                    data_array[miss_idx][3] <= line_buffer[3];
                    data_array[miss_idx][4] <= line_buffer[4];
                    data_array[miss_idx][5] <= line_buffer[5];
                    data_array[miss_idx][6] <= line_buffer[6];
                    data_array[miss_idx][7] <= line_buffer[7];
                    core_rdata <= line_buffer[miss_woff];
                    core_ack <= 1; core_stall <= 0;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule