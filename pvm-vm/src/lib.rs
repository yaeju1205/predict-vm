use pvm::{Instruction, Program, VirtualRegisterFile, VirtualRegisterValue};

pub struct VirtualMachine {
    pub program: Program,
    pub register_file: VirtualRegisterFile,
}

impl Default for VirtualMachine {
    fn default() -> Self {
        Self {
            program: Program::default(),
            register_file: VirtualRegisterFile::default(),
        }
    }
}

impl VirtualMachine {
    pub fn new(program: Program) -> Self {
        Self {
            program,
            register_file: VirtualRegisterFile::default(),
        }
    }
}

impl VirtualMachine {
    pub fn execute(&mut self) {
        match &self.program.instructions[self.program.count.0] {
            Instruction::Goto(target) => self.program.count = *target,
            Instruction::Mov { src, dst } => self.register_file[*dst] = self.register_file[*src],
            Instruction::Imm { imm, dst } => self.register_file[*dst] = VirtualRegisterValue(*imm),
            Instruction::Add { lhs, rhs, dst } => {
                self.register_file[*dst] = self.register_file[*lhs] + self.register_file[*rhs]
            }
            Instruction::Sub { lhs, rhs, dst } => {
                self.register_file[*dst] = self.register_file[*lhs] - self.register_file[*rhs]
            }
            _ => todo!("not implement the instruction"),
        }
        self.program.count.increment();
    }
}
