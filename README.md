## Specifications

[TOC]

### 1. Overview

ROB entry

| tag  | busy | inst. type | destination | value | ready |
| :--: | :--: | :--------: | :---------: | :---: | :---: |

Load Buffer entry

| tag  | busy | A (the effective address) |
| :--: | :--: | :-----------------------: |

#### 1.1 CDB



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

`br_target`

The target address of the branch if there is one.

`br_pc`

The corresponding PC of the branch instruction. This is used to update the BTB.

#### 2.2 Function

The branch predictor maintains the PC register. 

If opcode is not jal, jalr, branch (6 kinds), PC_next = PC_next + 4. If opcode is jal, PC_next = PC + imm. If opcode is jalr or branch (6 kinds), predict PC_next (always PC_next + 4 in the first version). br_en indicates the branch prediction for B branch.

### 3 Instruction queue

instruction queue entry

| PC (PC of this instruction) | next PC (PC of the next instruction right after this one) | br_pred (branch prediction result) | instruction |
| :-------------------------: | :-------------------------------------------------------: | :--------------------------------: | :---------: |

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

**Port to regfile.**

`rs1`

The index of the first register that we read.

`rs2`

The index of the second register that we read.

**Port to ALU RS.**

`Vj`

The first operand.

`Vk`

The second operand.

`Qj`

The tag of the ROB entry that we will obtain the data Vj.

`Qk`

The tag of the ROB entry that we will obtain the data Vk.

`op_type`

This input indicates what kind of instruction it is.

`dest`

This is the ROB entry tag that indicates where the result of this operation should be stored.

**Port from instruction queue.**

`pc_in[31:0]`

`pc_next_in[31:0]`

`inst_in`

The instruction popped from the instruction queue. If the opcode of the instruction is 32'b0, it means the instruction is illegal and we ignore it.

`br_pred_in`

This value is used later when the comparator produce the `br_en` signal to  give feedback to the branch predictor.

#### 4.2 Function

The decoder module put the right value into the ALU reservation station (RS). It is either a immediate from the instruction, existing register value from regfile, or ROB entry index read from the regfile.

### 5 ALU reservation station

#### 5.1 ALU RS entry

| tag  | busy | op. type |  Vj  |  Vk  |  Qj  |  Qk  | destination |
| :--: | :--: | :------: | :--: | :--: | :--: | :--: | :---------: |

If `Qj` or `Qk` is 0, it means the respective value is currently in `Vj` or `Vk`. Otherwise they refer to the ROB entry where the operands are fetched.

#### 5.2 Port

**Port to decoder.**

`ready`

Active high signal to indicate there is empty space in the reservation station.

**Port from decoder.**

`Vj_in`

The first operand.

`Vk_in`

The second operand.

`Qj_in`

The tag of the ROB entry that we will obtain the data Vj.

`Qk_in`

The tag of the ROB entry that we will obtain the data Vk.

`op_type`

This input indicates what kind of instruction it is.

`dest_in`

This is the ROB entry tag that indicates where the result of this operation should be stored.

**Port to ALU.**

`Vj_out`

`Vk_out`

`Qj_out`

`Qk_out`

`alu_op`

This corresponds to the `op. type` field in the RS entry. It informs the ALU what operation to perform.

**Control signal.**

`flush`

Active high signal that clears all the entries in the ALU reservation station.

**Port from CDB**

`alu_res`

This is a `cdb_itf` type port that receives output from the ALU.

`cmp_res`

This is a `cdb_itf` type port that receives output from the comparator.

`mem_res`

This is a `cdb_itf` type port that receives output from the memory (data cache).

#### 5.3 Functionality

The ALU reservation station contains 5 entries for pending operations waiting to be done by ALU. The destination field indicates where the computed result should go.

### 6 ALU

#### 6.1 Port

**Port from ALU RS**

`Vj_out`

`Vk_out`

`Qj_out`

`Qk_out`

`alu_op`

`destination`

This indicates where the result should go.

**Port to CDB**

`alu_out`

This is a `cdb_itf` type variable. 

#### 6.2 Functionality

The ALU computed a result given the two operands and operation type. Then it broadcasts the result onto the ALU-specific CDB.

### 7 Regfile

refile entry

| Reg# | V (register value) | Q (register source tag) |
| :--: | :----------------: | :---------------------: |

#### 7.1 Port

**Port from ROB**

`rd`

The index of the destination register we want to write.

`val`

The value that we want to write to `rd`.

`load`

Active high signal that enables write operation.

**Port from decoder**

`rs1`

The index of the first register we read.

`rs2`

The index of the second register we read.

**Port to decoder**

`rs1_out`

`rs2_out`

#### 7.2 Functionality

The regfile will check the `Q` field of the requested register and send back the correct value, i.e. if `Q` is 0, send back value in `V`, else send back `Q` itself.

