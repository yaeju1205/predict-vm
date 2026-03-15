# predict-vm

predict-vm 은 c 로 구성될 예정인 레지스터 vm 입니다
최종목표는 vm 을 기계어로 컴파일 하는것입니다

특징은 레지스터 배치에 있습니다

모든 변수들을 분석합니다
변수 생성처, 변수 사용처, 남은 변수 사용 회수 등을 수집합니다

분석 방법으로는 머신러닝을 사용합니다
첫번째로는 모든 instruction 에 대하여 강도를 지정합니다

산술 연산 add, sub, mul, div = 1.0
논리 연산 and, or, not = 0.75
제어 흐름 jmp, call, ret = 0.9
조건 제어 ifeq, iflt, ifle = 0.9
데이터 이동 mov, loadk, getvar, setvar = 0.6

a 다음 b 가 오는 횟수를 a 가 지금까지 등장한 회수로 나눕니다
old_predict(a->b) = count(a->b) / count(a)

reword 는 예측이 맞았을때 1, 틀렸을때 0 의 값을 가집니다
a = Learning Rate 
predict = (1 - a) * old_predict + a * reword

최종 변수의 스코어는 예측값에다 연산 강도를 곱합니다
또한 b 가 너무 적을 경우를 대비하여 빈도를 보정합니다
score = predict(a->b) * op * log(count(b) + 1)

이렇게 변수들의 스코어를 얻어 어떤 레지스터에 배치할지 예측합니다