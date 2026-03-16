# Confidence
다음 사용할 변수와 곧 쓸 변수를 예측하는 과정입니다
이를 통하여 Pre-fetching 과 Spilling 등을 할수 있습니다

## Transition Probability Matrix (전이 확률 행렬)
특정 명령어 에서 변수​가 사용되었을 때, 다음 인스트럭션에서 다른 변수들이​ 사용될 확률을 계산합니다

- P(vb​∣va​)=Count(va​->vb​) / Count(va​)​

## Distance-based Density Estimation (거리 기반 밀도 예측)
현제 pc 에서 다음 사용 거리를 기반으로 예측합니다

- 변수의 사용 간격이 일정하다면 모델은 높은 신뢰도로 짧은 거리를 예측합니다

- 거리가 짧을수록 가중치가 커집니다

## 3. Branch-Conditioned Probability (분기 조건부 확률)
분기점 이후 확률이 급격하게 변할수 있습니다

분기확률에따라 레지스터 배치를 미리 변경합니다

## 4. Exponential Decay (지수적 감소)
과거의 확률이 현재까지 영향을 주지 않도록, 시간의 흐름에 따라 과거 데이터 점점 줄입니다


