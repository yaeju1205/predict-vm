/// predict-vm 에서 사용할수 있는 명령어 입니다
///
/// Goto 제외 dst 를 가지며 값은 dst 에 저장됩니다
///
/// ```asm
/// mov r0, r1
/// add r0, r1, r2
/// ```
///
/// r0 과 r1 을 더해 r2 에 결과를 넣습니다
pub enum Instruction {
    Goto(ProgramCount),
    Mov {
        src: VirtualRegister,
        dst: VirtualRegister,
    },
    Imm {
        imm: u32,
        dst: VirtualRegister,
    },
    Add {
        lhs: VirtualRegister,
        rhs: VirtualRegister,
        dst: VirtualRegister,
    },
    Sub {
        lhs: VirtualRegister,
        rhs: VirtualRegister,
        dst: VirtualRegister,
    },
}

/// predict-vm 의 register 입니다
///
/// 양수의 번호를 가지며
/// 가상 레지스터로 최대크기는 255 입니다
///
/// ```rs
/// let r0 = VirtualRegister(0);
/// let r6 = VirtualRegister(6);
/// ```
///
/// r0 과 r6 을 생성합니다
#[derive(Default, Clone, Copy)]
pub struct VirtualRegister(pub u8);

/// predict-vm 의 register 의 값입니다
///
/// u32 의 자료형을 가집니다
///
/// ```rs
/// let r0_value = self.register_file[VirtualRegister(0)];
/// let r1_value = self.register_file[VirtualRegister(1)];
///
/// let r2_value = r0_value + r1_value;
/// self.register_file[VirtualRegister(2)] = r2_value;
/// ```
#[derive(Default, Clone, Copy)]
pub struct VirtualRegisterValue(pub u32);

impl std::ops::Add for VirtualRegisterValue {
    type Output = Self;

    fn add(self, rhs: Self) -> Self::Output {
        Self(self.0 + rhs.0)
    }
}

impl std::ops::Sub for VirtualRegisterValue {
    type Output = Self;

    fn sub(self, rhs: Self) -> Self::Output {
        Self(self.0 - rhs.0)
    }
}

/// predict-vm 의 register file 입니다
///
/// 인덱싱을 u8 로 하고 결과로 레지스터의 값을 얻습니다
/// 레지스터의 값은 u32 로 저장됩니다
///
/// ```rs
/// let value = program.register_file[VirtualRegister(5)];
/// ```
///
/// 레지스터 5 즉 r5 의 값을 가져옵니다
pub struct VirtualRegisterFile(pub [VirtualRegisterValue; 256]);

impl Default for VirtualRegisterFile {
    fn default() -> Self {
        Self([VirtualRegisterValue::default(); 256])
    }
}

impl std::ops::Index<VirtualRegister> for VirtualRegisterFile {
    type Output = VirtualRegisterValue;

    fn index(&self, index: VirtualRegister) -> &Self::Output {
        &self.0[index.0 as usize]
    }
}

impl std::ops::IndexMut<VirtualRegister> for VirtualRegisterFile {
    fn index_mut(&mut self, index: VirtualRegister) -> &mut Self::Output {
        &mut self.0[index.0 as usize]
    }
}

#[derive(Clone, Copy)]
pub struct ProgramCount(pub usize);
pub struct Program {
    pub instructions: Vec<Instruction>,
    pub count: ProgramCount,
}

impl Default for ProgramCount {
    fn default() -> Self {
        Self(0)
    }
}

impl ProgramCount {
    pub fn increment(&mut self) {
        self.0 += 1;
    }
}

impl Default for Program {
    fn default() -> Self {
        Self {
            instructions: Vec::new(),
            count: ProgramCount::default(),
        }
    }
}

impl Program {
    pub fn new(instructions: Vec<Instruction>) -> Self {
        Self {
            instructions,
            count: ProgramCount::default(),
        }
    }
}
