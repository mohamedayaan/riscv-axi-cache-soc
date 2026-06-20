# Interface Definitions

## Cache <-> AXI Master Interface

### Read Address Channel (AR)
- araddr[31:0]
- arvalid
- arready

### Read Data Channel (R)
- rdata[31:0]
- rresp[1:0]
- rlast
- rvalid
- rready

### Write Address Channel (AW)
- awaddr[31:0]
- awvalid
- awready

### Write Data Channel (W)
- wdata[31:0]
- wstrb[3:0]
- wlast
- wvalid
- wready

### Write Response Channel (B)
- bresp[1:0]
- bvalid
- bready

## Memory Map
- 0x0000_0000 to 0x0000_3FFF → Instruction Memory (16KB)
- 0x0000_4000 to 0x0000_7FFF → Data Memory (16KB)
