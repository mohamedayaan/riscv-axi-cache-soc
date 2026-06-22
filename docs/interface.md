# Interface Definitions

## Protocol: Full AXI4
## Data Width: 32-bit
## Address Width: 32-bit
## ID Width: 4-bit
## Burst: INCR, max 8 beats (cache line refill)

---

## 1. Cache <-> AXI Master Interface
(This is how friend's cache connects to our AXI master)

### Cache sends to AXI Master:
- cache_addr[31:0]      — address to read/write
- cache_wdata[31:0]     — data to write
- cache_wen             — 1=write, 0=read
- cache_req             — 1=request active
- cache_burst_len[7:0]  — 0=single beat, 7=8 beat cache line refill

### AXI Master sends to Cache:
- cache_rdata[31:0]     — read data (one word per beat)
- cache_ack             — pulses high for each beat
- cache_last            — pulses high on last beat of burst

---

## 2. AXI Master <-> AXI Slave Interface
(Internal signals between our modules)

### AR channel (Read Address)
- arid[3:0]
- araddr[31:0]
- arlen[7:0]
- arsize[2:0]           — always 3'b010 (4 bytes)
- arburst[1:0]          — always 2'b01 (INCR)
- arvalid
- arready

### R channel (Read Data)
- rid[3:0]
- rdata[31:0]
- rresp[1:0]            — 00=OKAY
- rlast
- rvalid
- rready

### AW channel (Write Address)
- awid[3:0]
- awaddr[31:0]
- awlen[7:0]
- awsize[2:0]           — always 3'b010 (4 bytes)
- awburst[1:0]          — always 2'b01 (INCR)
- awvalid
- awready

### W channel (Write Data)
- wdata[31:0]
- wstrb[3:0]
- wlast
- wvalid
- wready

### B channel (Write Response)
- bid[3:0]
- bresp[1:0]            — 00=OKAY
- bvalid
- bready

---

## 3. Memory Map
- 0x0000_0000 to 0x0000_3FFF -> Instruction Memory (16KB)
- 0x0000_4000 to 0x0000_7FFF -> Data Memory (16KB)

---

## 4. Key Rules
- Cache line = 32 bytes = 8 words
- Cache line refill = burst read with arlen=7 (8 beats)
- Write from cache = single beat (awlen=0)
- Burst type always INCR
- ID always 4'd0 for now
