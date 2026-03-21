# Predcit
예측 과정을 설명합니다

모든 위치는 pc (program counter) 를 기준으로 설명합니다

## 1. Analysis (분석) 
모든 변수를 분석합니다

### Live Range
변수의 생성위치 부터 마지막 사용위치 까지의 구간입니다

이 Live Range 를 통하여 구간내의 사용 밀도(Usage Density) 를 예측합니다

- 예를 들어 Live Range 가 뒤쪽에 있다면 중간에서는 레지스터를 할당하지 않습니다 (Spilling)

## 2. Spill Cost Scoring (우선순위 점수)

### Instruction Weight (명령어 가중치)
명령어당 변수가 가질 스코어에 대해 가중치를 적용합니다

- 예를 들어 Add 같은 명령어는 0.9 의 가중치를 가집니다

모든 명령어 가중치는 `docs/Instruction.md` 를 참고하세요

### Spill Cost 수식
레지스터가 부족할 때 어떤 변수를 메모리로 둘지 결정하는 spill cost 를 얻는 수식입니다

우선사항(Priority) = (명령어 가중치(Instruction Weight) * 다음사용 확율 (Confidence)) / 변수 점유 시간(Live Range)

다음 사용할 변수를 예측하는 과정은 `docs/Confidence.md` 를 참고하세요

## 3. Allocation (할당)

### Speculative Pre-coloring (투기적 사전 배정)
특정 코드블록이 실행되기전 미래에 사용 확률이 높은 변수들을 미리 레지스터에 로드합니다

- Transition Probability Matrix를 사용하여 A 변수 실행 시점에 B와 C를 Pre-fetch할지 결정합니다

### Intelligent Spilling (지능적 스필링)
단순히 가장 오래 안 쓴 것 즉 LRU(Least Recently Used) 을 버리는 게 아닌
가장 먼 미래에 쓰일것을 예측하여 버립니다 이를 통해 나중에 다시 레지스터로 불러오는 Reload 오버헤드를 최소화합니다

### Register Coalescing (레지스터 합치기)
mov v1 v2 같은 명령어가 있을때
v1 과 v2 의 미래 가중치가 모두높다 판단하면 두 변수를 별개의 레지스터가 아닌 동일한 물리 레지스터에 배치합니다
- 예를 들어 mov v1 v2 와 add v1 v3 가 있다면 mov 를 빼고 add v1 v3 를 실행합니다

## 4. Adaptive Optimization (런타임 최적화)
### Static Pass
컴파일 타임에 명령어 타입과 루프 구조를 보고 초기 가중치를 부여합니다

### Dynamic Pass
VM 실행 중 실제 분기 방향과 변수 사용 간격을 측정하여 가중치를 실시간 업데이트 합니다

### Re Alloc
업데이트된 점수가 임계치를 넘으면 VM 은 레지스터 배치를 즉석에서 변경합니다