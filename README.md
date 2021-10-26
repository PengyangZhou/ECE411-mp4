## Specifications

[TOC]

### 1. Overview

refile entry

| Reg# | Vj (register value) | Qj (register source) |
| :--: | :-----------------: | :------------------: |

instruction queue entry

| PC (PC of this instruction) | next PC (PC of the next instruction right after this one) | br_pred (branch prediction result) | instruction |
| :-------------------------: | :-------------------------------------------------------: | :--------------------------------: | :---------: |

ROB entry

| tag  | busy | inst. type | destination | value | ready |
| :--: | :--: | :--------: | :---------: | :---: | :---: |

Load Buffer entry

| tag  | busy | A (the effective address) |
| :--: | :--: | :-----------------------: |

### 2. Branch Predictor

#### 2.1 Port

**Port to instruction queue.**

`pc[31:0]`

The PC value of current instruction.

`pc_next[31:0]`

The next PC value after this instruction. If branch is involved, the pc_next is the jump destination address.

`instruction[31:0]`

The instruction itself.

`br_pred`

Set high if the corresponding instruction is a branch and is predicted as take. Otherwise is low.

**Port to cache.**

The memory interface.

`mem_read`

`mem_write`

`mem_byte_enable_cpu[3:0]`

`mem_address[31:0]`

`mem_wdata_cpu[31:0]`

32-bit data bus for sending data *to* the cache.

`mem_resp`

`mem_rdata_cpu[31:0]`

32-bit data bus for receiving data *from* the cache.

**Port to CMP.**

`br_en`

Branch enable signal *from* CMP.

#### 2.2 Function

The branch predictor maintains the PC register. 

If opcode is not jal, jalr, branch (6 kinds), PC_next = PC_next + 4. If opcode is jal, PC_next = PC + imm. If opcode is jalr or branch (6 kinds), predict PC_next (always PC_next + 4 in the first version). br_en indicates the branch prediction for B branch.

### 3 Instruction queue

#### 3.1 Port

**Port from branch predictor.**

`pc_in[31:0]`

The PC value of current instruction.

`pc_next_in[31:0]`

The next PC value after this instruction. If branch is involved, the pc_next is the jump destination address.

`inst_in[31:0]`

The instruction itself.

`br_pred_in`

The predicted branch enable signal.

**Port to decoder.**

`pc_out[31:0]`

`pc_next_out[31:0]`

`inst_out[31:0]`

`br_pred_out`

**Control signal.**

`shift`

Active high signal that enables the instruction queue to shift downward, i.e. popping out the instructions.

`flush`

Active high signal that clears the whole queue.

#### 3.2 Function

The instruction queue takes in the instruction data from the branch predictor and passes it along its internel pipeline.

flush means branch misprediction and all instructions need to be omitted (new PC will be sent to branch predictor and then to instruction queue by PC_next).

If one entry does not hold valid instruction data, its value should be set to 32'b0.

### 4 Decoder

#### 4.1 Port



#### 4.2 Function



### 5 ALU reservation station

#### 5.1 ALU RS entry

| tag  | busy | op. type |  Vj  |  Vk  |  Qj  |  Qk  | destination |
| :--: | :--: | :------: | :--: | :--: | :--: | :--: | :---------: |

#### 5.2 Port



#### 5.3 Function

