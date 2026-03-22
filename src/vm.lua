--- @alias VMProgramCount number
--- @alias VMStackPoint number

--- @alias VMOPCode number
local vm_opcode = {
    load_imm = 0,
    bind_var = 1,
    sync_var = 2,
    add      = 3,
    sub      = 4,
    mul      = 5,
    div      = 6,
    call     = 7,
    ret      = 8,
    jmp      = 9,
    jmp_le   = 10,
    jmp_lt   = 11,
}
--- @class VMInstruction
--- @field opcode VMOPCode
--- @field dst? number
--- @field src? number
--- @field src1? number
--- @field src2? number
--- @field offset? number
--- @field imm? number
--- @type table<number, VMInstruction>
local vm_instructions = {}

--- @alias VMVariable number
--- @type table<number, VMVariable>
local vm_variables = {}

--- @alias VMRegister number
--- @type table<number, VMRegister>
local vm_registers = {}
local vm_register_count = 256

--- @type table<VMVariable, VMRegister>
local vm_bind_variables = {}
--- @type table<VMRegister, VMVariable>
local vm_sync_variables = {}

--- @type table<VMStackPoint, VMProgramCount>
local vm_stack = {}

--- @type VMProgramCount
local vm_program_count = 1

--- @type VMStackPoint
local vm_stack_point = 1

--- @class VMStaticInfo
--- @field density table<VMRegister, number>
--- @field tpm table<VMRegister, table<VMRegister, number>>
local vm_static_info = {
    density = {},
    tpm = {},
}
local function vm_static_analyze()
    --- @type number?
    local prev_reg
    local density = vm_static_info.density
    local tpm = vm_static_info.tpm
    for pc=1, #vm_instructions do
        local inst = vm_instructions[pc]
        local dst = inst.dst
        local src = inst.src
        local src1 = inst.src1
        local src2 = inst.src2
        if dst then
            density[dst] = density[dst] and density[dst] + 1 or 1
            if prev_reg then
                local prev_vec = tpm[prev_reg]
                prev_vec = prev_vec or {}
                prev_vec[dst] = prev_vec[dst] and prev_vec[dst] + 1 or 1
            end
            prev_reg = dst
        end
        if src then
            density[src] = density[src] and density[src] + 1 or 1
            if prev_reg then
                local prev_vec = tpm[prev_reg]
                prev_vec = prev_vec or {}
                prev_vec[src] = prev_vec[src] and prev_vec[src] + 1 or 1
            end
            prev_reg = src
        end
        if src1 then
            density[src1] = density[src1] and density[src1] + 1 or 1
            if prev_reg then
                local prev_vec = tpm[prev_reg]
                prev_vec = prev_vec or {}
                prev_vec[src1] = prev_vec[src1] and prev_vec[src1] + 1 or 1
            end
            prev_reg = src1
        end
        if src2 then
            density[src2] = density[src2] and density[src2] + 1 or 1
            if prev_reg then
                local prev_vec = tpm[prev_reg]
                prev_vec = prev_vec or {}
                prev_vec[src2] = prev_vec[src2] and prev_vec[src2] + 1 or 1
            end
            prev_reg = src2
        end
    end
end

--- @type table<VMRegister, number>
local vm_weights = {}
--- @type VMRegister?
local vm_prev_register
--- @type VMProgramCount
local vm_prev_update_pc = 0
--- @param reg VMRegister
local function vm_update_dynamic_weight(reg)
    local static_score = vm_static_info.density[reg] or 0
    local tpm_score = 0
    if vm_prev_register then
        local tpm_vec = vm_static_info.tpm[vm_prev_register]
        if tpm_vec then
            tpm_score = tpm_vec[reg]
        end
    end
    vm_weights[reg] = static_score * 0.1 + tpm_score * 0.5 * ((vm_program_count - vm_prev_update_pc) * 0.9)
    vm_prev_register = reg
    vm_prev_update_pc = vm_program_count
end

--- @return VMRegister
local function vm_ensure_register()
    for reg=1, vm_register_count do
        if not vm_registers[reg] then
            vm_registers[reg] = 0
            return reg
        elseif not vm_sync_variables[reg] then
            return reg
        else
            vm_update_dynamic_weight(reg)
        end
    end
    local victim_reg
    for i=1, vm_weights do
        if not victim_reg or vm_weights[i] <= vm_weights[victim_reg] then
            victim_reg = i
        end
    end
    vm_bind_variables[vm_sync_variables[victim_reg]] = nil
    return victim_reg
end

--- @param dst VMRegister
--- @param src VMRegister
local function vm_mov_regsiter(dst, src)
    local temp = vm_registers[dst]
    vm_registers[dst] = vm_registers[src]
    vm_registers[src] = temp
    local src_var = vm_sync_variables[src]
    local dst_var = vm_sync_variables[dst]
    if dst_var then
        vm_bind_variables[dst_var] = src
        vm_sync_variables[src] = dst_var
        if not src_var then
            vm_sync_variables[dst] = nil
        end
    end
    if src_var then
        vm_bind_variables[src_var] = dst
        vm_sync_variables[dst] = src_var
        if not dst_var then
            vm_sync_variables[src] = nil
        end
    end
end

--- @param dst VMRegister
local function vm_ensure_dst(dst)
    local ensure_reg = vm_ensure_register()
    if dst ~= ensure_reg then
        if not vm_registers[dst] then
            vm_registers[dst] = 0
        end
        vm_mov_regsiter(dst, ensure_reg)
    end
end

local function vm_decode_instruction()
    local inst = vm_instructions[vm_program_count]
    local opcode = inst.opcode
    local jmp_pc = false
    local jmp_if = false
    if opcode == vm_opcode.load_imm then
        vm_ensure_dst(inst.dst)
        vm_registers[inst.dst] = inst.imm
    elseif opcode == vm_opcode.bind_var then
        vm_ensure_dst(inst.dst)
        vm_bind_variables[inst.dst] = inst.src
        vm_sync_variables[inst.src] = inst.dst
        vm_registers[inst.dst] = vm_variables[inst.src]
    elseif opcode == vm_opcode.sync_var then
        vm_sync_variables[inst.dst] = inst.src
        vm_bind_variables[inst.src] = inst.dst
        vm_variables[inst.dst] = vm_registers[inst.src]
    elseif opcode == vm_opcode.add then
        vm_ensure_dst(inst.dst)
        vm_registers[inst.dst] = vm_registers[inst.src1] + vm_registers[inst.src2]
    elseif opcode == vm_opcode.sub then
        vm_ensure_dst(inst.dst)
        vm_registers[inst.dst] = vm_registers[inst.src1] - vm_registers[inst.src2]
    elseif opcode == vm_opcode.mul then
        vm_ensure_dst(inst.dst)
        vm_registers[inst.dst] = vm_registers[inst.src1] * vm_registers[inst.src2]
    elseif opcode == vm_opcode.div then
        vm_ensure_dst(inst.dst)
        vm_registers[inst.dst] = vm_registers[inst.src1] / vm_registers[inst.src2]
    else
        jmp_pc = true
    end
    if jmp_pc then
        if opcode == vm_opcode.call then
            local sp = vm_stack_point + 1
            vm_stack_point = sp
            vm_stack[sp] = vm_program_count
            vm_program_count = inst.offset
        elseif opcode == vm_opcode.ret then
            local sp = vm_stack_point - 1
            vm_program_count = vm_stack[sp]
            vm_stack_point = sp
        elseif opcode == vm_opcode.jmp then
            vm_program_count = inst.offset
        else
            jmp_if = true
        end
        if jmp_if then
            if opcode == vm_opcode.jmp_le then
                if inst.src1 == inst.src2 then
                    vm_program_count = inst.offset
                end
            elseif opcode == vm_opcode.jmp_lt then
                if inst.src1 >= inst.src2 then
                    vm_program_count = inst.offset
                end
            end
        end
    else
        vm_program_count = vm_program_count + 1
    end
end

local function vm_execute_instructions()
    while vm_program_count <= #vm_instructions do
        vm_decode_instruction()
    end
end

local function debug()
    vm_instructions = {
        {
            opcode = vm_opcode.load_imm,
            dst = 2, -- R2
            imm = 4,
        },
        {
            opcode = vm_opcode.sync_var,
            dst = 1, -- V1
            src = 2, -- R2
        },
        {
            opcode = vm_opcode.bind_var,
            dst = 1, -- R1
            src = 1, -- V1
        },
        {
            opcode = vm_opcode.add,
            dst = 3,
            src1 = 1,
            src2 = 2,
        },
    }

    -- TODO: Add Branch Predict
    vm_execute_instructions()
    for i=1, vm_register_count do
        if vm_registers[i] then
            print("R" .. i .. " -> " .. vm_registers[i])
        end
    end
end