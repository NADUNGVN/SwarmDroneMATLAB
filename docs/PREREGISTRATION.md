# Pre-registration — EXP07 → EXP10

**Ngày chốt: 2026-08-21.**
**Tag: `prereg-exp07-exp10`.**

Tài liệu này được commit và tag **trước khi tồn tại bất kỳ kết quả EXP07 nào**. Lịch sử git là
bằng chứng thời điểm rằng tiêu chí chấp nhận có trước dữ liệu.

Mục đích: loại bỏ khả năng tune experiment để đạt "số đẹp". Ngưỡng đã chốt sẽ **không đổi** sau
khi nhìn kết quả, trừ khi phát hiện một **bug thật sự** — và trong trường hợp đó, bug phải được
mô tả cụ thể trong `docs/RESEARCH_REVIEW.md` cùng với commit sửa nó.

Nếu một gate không đạt, chính thất bại đó là kết quả khoa học: nó chỉ ra giả định nào của phương
pháp không đúng. Không được im lặng hạ ngưỡng.

---

## 0. Quy tắc chung từ EXP07 trở đi

1. **EXP05B / EXP05C / EXP05D / EXP06A giữ nguyên làm ideal-feedback reference.** Không sửa các
   file LOCK: `simulation/simSwarmAoIAware.m`, `simulation/simSwarmAoIAblation.m`,
   `simulation/simSwarmEventTriggered.m`, `experiments/exp05*.m`, `experiments/exp06a*.m`.

2. **Phương pháp mới tên là `Causal-AoI` (đầy đủ: `Full-AoI-Causal`)**, cài trong file riêng
   `simulation/simSwarmAoICausal.m`. Không ghi đè `simSwarmAoIAware.m`.

3. **Quy trình mỗi experiment:** 3 seeds debug → người dùng verify → 20 seeds final.
   EXP10 statistical confirmation dùng **50 seeds** ở selected points.

4. **Tham số phương pháp KHÔNG đổi giữa các scenario:**

   | Tham số | Giá trị |
   |---|---|
   | `epsP` | 0.05 m |
   | `epsV` | 0.10 m/s |
   | `aoiThreshold` | 0.12 s |
   | `aoiCooldown` (`aoiMinInterTx`) | 0.10 s |
   | `maxSilence` | 0.50 s |
   | `aoiStateScaleBase` | 0.50 |
   | `aoiStateScaleMin` | 0.20 |
   | `aoiAdaptRange` | 1.00 |

5. **Mỗi run phải lưu** `console.log`, `tidy.csv`, `meta.json`, `figures/`, và source snapshot.
   Raw `.mat` lưu local (đã bị `.gitignore` loại vì dung lượng).

6. **Nếu một gate thất bại: KHÔNG tune.** Phân tích nguyên nhân trước. Nếu buộc phải đổi thuật
   toán hoặc protocol thì tạo version mới (`Causal-AoI-v2`), giữ v1 để so sánh, và chạy lại các
   ablation / Pareto liên quan.

7. **Mọi gate so sánh dùng baseline đo trong CÙNG run, CÙNG seed set.** Không so với số lưu từ
   experiment khác. Các số ở §1 chỉ để tham khảo và để phát hiện hồi quy, không phải để làm mẫu
   số của gate.

---

## 1. Số tham chiếu đã đo (ideal-feedback, để phát hiện hồi quy)

Nguồn: `results/exp06a_scalability/2026-08-20_115133/tidy.csv`, N = 5, 20 seeds.

| Scenario | P10 RMSE | P20 RMSE | State-event RMSE | Ideal Full-AoI RMSE | Ideal Full-AoI rate |
|---|---|---|---|---|---|
| Moderate | 0.0954 | 0.0727 | 0.1690 | 0.0973 | 11.19 Hz |
| Stressed | 0.1456 | 0.1103 | 0.2591 | 0.1310 | 15.81 Hz |

Điều kiện mạng:

| Scenario | packet loss | delay | jitter |
|---|---|---|---|
| Clean | 0 % | 0 ms | 0 |
| Moderate | 20 % | 80 ms | 0 |
| Stressed | 40 % | 120 ms | 0 |

**Ghi chú quan trọng:** ở Stressed, conventional State-event đã có **SafeFail = 0.15** (15 % số
seed vi phạm khoảng cách an toàn). Gate `SafeFail = 0` của Causal-AoI vì thế là một bar thật mà
chính baseline không vượt qua — không phải một ngưỡng dễ dãi.

---

## 2. Định nghĩa vận hành

Các định nghĩa này là một phần của pre-registration. Chúng tồn tại để tiêu chí PASS/FAIL không
thể bị diễn giải lại sau khi nhìn số.

### 2.1 Metric cơ bản (giữ nguyên định nghĩa hiện có)

- `FormFail` ⟺ `formationRMSE > 0.10 m`
- `SafeFail` ⟺ `minSeparationEval < 0.25 m`
- Cửa sổ đánh giá: `t ≥ 8 s`
- `formationRMSE`: RMS sai số vị trí của các follower so với `leaderPos + offset`, trên cửa sổ
  đánh giá (`metrics/computeSwarmMetrics.m`)
- Communication rate mặc định báo cáo theo **Hz trên mỗi directed channel**;
  `nChannels = nnz(A) + sum(pin)`

### 2.2 Recovery time (EXP08B, EXP08C)

`e(t)` = max sai số formation trên các follower tại thời điểm `t`.

`e_base` = trung bình `e(t)` trong **3 s ngay trước** khi lỗi bắt đầu.

`T_recovery` = (thời điểm `t` sớm nhất **sau khi lỗi được gỡ** sao cho `e(t') ≤ 1.1 · e_base`
với **mọi** `t' ∈ [t, t+1 s]`) − (thời điểm gỡ lỗi).

Nếu điều kiện không bao giờ đạt trong thời gian còn lại của run → `T_recovery = NaN`, và
**`NaN` tính là FAIL** cho mọi gate về recovery.

### 2.3 Peak error after fault

`E_max` = `max e(t)` trên khoảng `[thời điểm lỗi bắt đầu, hết run]`.

### 2.4 Connectivity (EXP08)

Dựng đồ thị **vô hướng** `G` trên `N` node:
- cạnh `(i,j)` nếu `A(i,j) ≠ 0` **hoặc** `A(j,i) ≠ 0`
- thêm cạnh `(1,i)` nếu `pin(i) ≠ 0`

`L = D − Adj` (Laplacian không chuẩn hoá). `λ2` = trị riêng nhỏ thứ hai của `L`.

**Connected ⟺ `λ2 > 1e-9`.**

Mọi condition có `λ2 ≤ 1e-9` được ghi vào **connectivity impossibility region** và **loại khỏi
mọi phép tính tỉ lệ PASS**. Một policy không bị coi là fail vì đồ thị đã đứt.

### 2.5 Non-dominated / Pareto-competitive (EXP10B)

Trong một scenario, method `M` là **non-dominated** nếu **không tồn tại** method `M'` thoả
**đồng thời**:

```
RMSE(M') ≤ 0.99 · RMSE(M)      VÀ      cost(M') ≤ 0.99 · cost(M)
```

Biên 1 % để tie không lật vì nhiễu Monte-Carlo.
`cost` = TOTAL cost dưới **cost model giữa** (`packet-w` với `w = 0.25`) của EXP07C.

### 2.6 "Ranking không bị đảo hoàn toàn" (EXP09A)

Đặt `r = sign(RMSE_Causal − RMSE_P10)` và `s = sign(RMSE_Causal − RMSE_P20)`.

So dấu của `r` và `s` trong 6-DOF với chính chúng trong double-integrator, cùng scenario.

**Gate: `r` khớp ở ≥ 2/3 scenario VÀ `s` khớp ở ≥ 2/3 scenario.**

Đảo cả `r` lẫn `s` ở cả 3 scenario = FAIL.

### 2.7 Mức ACK impairment (EXP07B)

| Mức | ACK loss | ACK delay |
|---|---|---|
| reliable | 0 % | tối thiểu (1 timestep) |
| moderate | 10 % | = delay DATA của scenario |
| severe | 20 % | = 2 × delay DATA của scenario |

### 2.8 Cost model (EXP07C)

Báo cáo cả ba; kết luận phải tồn tại dưới **≥ 2/3** model.

1. **`packet-w`** — `cost = nDATA + w · nACK`, với `w ∈ {0.1, 0.25, 0.5}`.
   Ba giá trị `w` là ba biến thể của **một** model.
2. **`airtime`** — DATA = 16 B header + 32 B payload; ACK = 16 B header + 8 B payload
   → tỉ lệ ACK/DATA ≈ 0.5 theo airtime.
3. **`broadcast`** — một lần phát của node `j` tại bước `k` tính **một** đơn vị bất kể bao nhiêu
   neighbor nhận được; ACK vẫn tính unicast.

Mọi bảng chi phí phải báo riêng **DATA / ACK / TOTAL**.

---

## 3. EXP07 — Biến feedback thành communication protocol thật

### 3.1 EXP07A — Explicit causal ACK

Luồng: `DATA → receiver accept → ACK → sender update`.
Sender **không** được đọc trực tiếp trạng thái receiver.

**Sender chỉ có quyền biết:**
```
lastAckedGenTime
lastAckedPos
lastAckedVel
```

**Sender KHÔNG được gọi, trong đường ra quyết định trigger:**
```
net.genTime(i,j)
net.leaderGenTime(i)
net.Pij / net.Vij
net.leaderPos / net.leaderVel / net.leaderAcc
net.valid / net.leaderValid
```

**Độ trễ ACK tối thiểu:** `ackDelay ≥ cfg.swarm.dt` **luôn luôn**, kể cả ở Clean. Receiver chỉ
ra quyết định accept tại nhịp lấy mẫu của nó, nên không tồn tại ACK trong-cùng-một-timestep. Đây
là ràng buộc vật lý, không phải tham số điều chỉnh được.

#### Invariant bắt buộc — tất cả phải bằng 0

```
ackBeforeAcceptCount      = 0    ACK tới sender trước acceptTime của chính nó
ackForDroppedDataCount    = 0    ACK mang seq chưa từng được deliver
senderRollbackCount       = 0    gán ackGenTime ≤ giá trị hiện tại
futureGenTimeCount        = 0    genTime hoặc ackedGenTime > tk + tol
staleAckAcceptedCount     = 0    ACK cũ nhưng vẫn sửa được state
unknownSeqAckCount        = 0    seq không nằm trong tập outstanding của sender
```

Cưỡng chế hai lớp:
- **Runtime** — `cfg.ack.assertInvariants = true` làm mọi vi phạm `error()` ngay lập tức.
- **Tĩnh** — `tests/test_causal_invariants.m` quét source của đường trigger/enqueue causal và
  FAIL nếu xuất hiện bất kỳ identifier receiver-side nào ở trên.

**Nếu EXP07A không đảm bảo các invariant này thì KHÔNG PASS, bất kể RMSE đẹp đến đâu.**

#### Gate EXP07A

```
Causality       : cả 6 invariant = 0, và test_causal_invariants PASS
Clean           : |RMSE_Causal − RMSE_Ideal| / RMSE_Ideal ≤ 2 %
Moderate        : RMSE_Causal ≤ 1.10 × RMSE_P10
Stressed        : RMSE_Causal <  RMSE_P10
Both            : RMSE_Causal < RMSE_State-event ở Moderate VÀ Stressed
Rate ordering   : rate(Clean) < rate(Moderate) < rate(Stressed)
Rate ceiling    : rate(Stressed) ≤ 20 Hz
Safety          : SafeFail = 0, cả 3 scenario, 20 seeds
```

**Lý do có trần 20 Hz:** không có nó, một phiên bản chỉ đơn giản truyền thật nhiều sẽ pass mọi
gate còn lại. 20 Hz chính là rate của P20; vượt ngưỡng đó thì Causal-AoI bị P20 dominate hoàn
toàn ở Stressed (P20 vừa rẻ hơn vừa có RMSE 0.1103 tốt hơn), nên đây là ranh giới có ý nghĩa
khoa học chứ không phải con số tuỳ ý.

#### Dự đoán ghi trước khi chạy

`tk − lastAckedGenTime` là **cận trên** của AoI thật: nó không reset khi gói tới mà ACK chưa về.
Do đó Causal sẽ truyền **nhiều hơn** Ideal ở cùng ngưỡng. Ở Stressed, RTT ≥ 0.24 s = 2 ×
`aoiThreshold`, nên `normalizedExcess` bão hoà và `adaptiveScale` kẹt ở `scaleMin = 0.20` gần
như suốt run.

Ghi dự đoán này ở đây để sau khi chạy có thể đối chiếu, chứ không phải để biện minh cho kết quả.

#### Ablation dưới điều kiện nhân quả

EXP07A cũng đo lại chuỗi ablation với AoI **ước lượng**:

```
A1  = State-event (không AoI)
A2c = fixed AoI coupling,    AoI ước lượng từ ACK
A3c = adaptive AoI coupling, AoI ước lượng từ ACK
A4c = Causal-Full-AoI
```

Lý do: con số "accepted-state feedback đóng góp 16.07 % ở Stressed" là claim dễ bị tấn công nhất
của bài báo, vì đóng góp lớn nhất đến từ thành phần phi vật lý nhất. Nó phải được đo lại ở đúng
chỗ mà tính phi vật lý bị loại bỏ.

Ma trận: 8 arm × 3 scenario × 20 seeds = 480 sim.
Arms: `P10`, `P20`, `State-event`, `Ideal-Full-AoI` (reference), `A2c`, `A3c`, `A4c` = `Causal-Full-AoI`.

### 3.2 EXP07B — ACK loss / delay / stale ACK

Điều kiện: ba mức ở §2.7, trên Moderate + Stressed.

```
Protocol : không deadlock, không future ACK, không stale rollback
moderate : RMSE degradation ≤ 10 % so với reliable ACK
severe   : RMSE degradation ≤ 25 %
Safety   : SafeFail ≤ 5 % ở mức moderate
```

### 3.3 EXP07C — Communication cost realism

Ba cost model ở §2.8, báo riêng DATA / ACK / TOTAL, có cả unicast và broadcast accounting.

```
Robustness : kết luận tồn tại dưới ≥ 2/3 cost model
Stressed   : Causal-AoI còn Pareto-competitive với P10/P20 theo §2.5
```

---

## 4. EXP08 — Tổng quát hoá topology và lỗi mạng

### 4.1 EXP08A — Static topology robustness

`N ∈ {10, 20, 50}` × 4 topology × {Moderate, Stressed} = **24 condition**.

Topology: ring degree-2, sparse degree-4, sparse degree-6, random geometric (connected).

Bắt buộc lưu: `numEdges`, `meanDegree`, `minDegree`, `λ2`, `RMSE`, `AoI`, `MinSep`,
`TxData`, `TxTotal`, `FormFail`, `SafeFail`.

```
Pre-check : mọi graph phải connected trước simulation (§2.4)
Safety    : SafeFail ≤ 5 % ở những condition mà P20 cũng safe
Advantage : ở Stressed, Causal-AoI tốt hơn P10 về RMSE HOẶC tốt hơn P20 về
            communication cost, ở ≥ 80 % condition connected
Robustness: bỏ bất kỳ MỘT topology nào ra khỏi tập vẫn còn ≥ 80 %
            (không được có topology duy nhất quyết định kết luận)
```

### 4.2 EXP08B — Link failure / burst outage

Random permanent link removal 10 % / 20 % / 30 %; burst outage 2 s / 5 s.

Metric thêm: peak error after fault, recovery time, min separation during failure, peak AoI,
network connectivity duration, traffic response.

Khi graph **vẫn connected**:
```
Safety   : SafeFail ≤ 5 %
Recovery : T_recovery(Causal-AoI) ≤ 1.25 × T_recovery(P20)
Peak     : E_max(Causal-AoI)      ≤ 1.25 × E_max(P10)
```

Nếu graph thực sự disconnected: **không dùng condition đó để kết luận policy fail**. Ghi riêng
vào connectivity impossibility region.

### 4.3 EXP08C — Node communication dropout

Blackout 1 node / 2 node, thời lượng 2 s / 5 s, khôi phục sau đó. `N ∈ {10, 20}`.

```
1-node Moderate  : SafeFail = 0
1-node Stressed  : SafeFail ≤ 5 %
Recovery         : T_recovery ≤ 5 s cho single-node blackout khi graph vẫn connected
2-node           : nếu làm graph disconnect thì phải DETECT và LABEL đúng
```

EXP08 kết thúc khi có thể phát biểu: *phương pháp không phụ thuộc vào một sparse-ring topology
cố định duy nhất, và suy giảm một cách có kiểm soát dưới lỗi kết nối tạm thời.*

---

## 5. EXP09 — Đưa communication policy trở lại vật lý UAV

### 5.1 EXP09A — Networked multi-UAV 6-DOF

Thay double integrator bằng:
```
formation policy → desired acceleration → cascaded quadrotor controller → 6-DOF dynamics
```

`N = 5` (bắt buộc), `N = 10` (nếu runtime hợp lý). 3 scenario × 4 method
(P10, P20, State-event, Causal-AoI).

Metric thêm: position RMSE, formation RMSE, roll/pitch peak, thrust saturation, torque
saturation, control effort, MinSep, AoI, communication cost.

```
Stability        : mọi drone ổn định, không NaN, không divergence
Clean + Moderate : SafeFail = 0
Stressed         : SafeFail ≤ 5 %
Saturation       : nominal < 1 %; Stressed < 5 %
Advantage        : Causal-AoI vẫn tốt hơn State-event
Consistency      : ranking với P10/P20 không bị đảo hoàn toàn (§2.6)
```

**Đây là major gate.** Nếu communication claim chỉ tồn tại trên double-integrator nhưng biến mất
với 6-DOF thì phải điều tra, không được bỏ qua.

### 5.2 EXP09B — Disturbance + model mismatch

Wind / external force; mass mismatch ±10 %; drag mismatch ±20 %; optional actuator lag 20–50 ms.
**Không tune controller theo từng mismatch.**

Ở mức perturbation trung bình:
```
RMSE_perturbed ≤ 1.25 × RMSE_nominal
SafeFail   ≤ 5 %
Saturation ≤ 5 %
Direction  : "network worsens → communication increases" vẫn phải tồn tại
```

### 5.3 EXP09C — Sensor noise + estimator latency + numerical sensitivity

**Đây là synthetic robustness study. KHÔNG được gọi là measured sensor model.**

Position noise σ ∈ {0, 0.01, 0.03, 0.05} m; velocity noise σ ∈ {0, 0.02, 0.05, 0.10} m/s;
estimator latency ∈ {0, 50, 100} ms.

Quan sát đặc biệt: **false triggering**, vì trigger phụ thuộc `Δp`, `Δv`.

Ở mức medium-noise:
```
SafeFail   ≤ 5 %
TxRate     tăng < 2× so với noiseless
```

Numerical convergence, `dt ∈ {0.01, 0.02, 0.04}` s. Giữa 0.01 và 0.02:
```
RMSE difference   ≤ 5 %
TxRate difference ≤ 5 %
```
`dt = 0.04` có thể degrade; mục đích là xác định boundary, không ép PASS.

---

## 6. EXP10 — Final scientific validation

**Không sửa thuật toán trong EXP10.**

### 6.1 EXP10A — Fair comparison protocol

Pre-generate `networkTrace(seed, link, k)` chứa loss outcome, delay, jitter. P10, P20,
State-event và Causal-AoI đều chạy trên **cùng một network realization**, tra theo **thời điểm**
(không theo số lần truyền) để CRN đúng nghĩa.

Periodic nhận **phase offset per-link** hợp lý — không để một method vô tình luôn transmit đúng
tại `t = 0`.

Selected operating points chạy **50 seeds**.

```
Trace integrity : trace ID/hash khớp 100 % giữa các method
Completeness    : missing runs = 0, NaN runs = 0
Claims          : main claim báo 95 % CI của paired difference
                  Stressed: RMSE(Causal) < RMSE(P10)
                  so sánh communication với P20 phải báo CI, không chỉ mean
```

**Nếu confidence interval cắt 0 thì claim đó bị downgrade và phải ghi rõ. Không được giấu.**

Cài đặt CRN dùng **flag additive** `cfg.net.trace` / `cfg.net.phaseOffset`, mặc định **tắt**,
kèm `tests/test_lock_regression.m` chứng minh EXP05C và EXP06A tái tạo **bit-identical** sau
khi sửa.

### 6.2 EXP10B — Unified final stress matrix

8 scenario: Nominal; Moderate loss/delay; Stressed loss/delay; Jitter/out-of-order; Link outage;
Node blackout; Sensor noise; Wind + network combined.

Method chính: `Periodic10`, `Periodic20`, `Conventional Event`, `Full-AoI-Causal`.
Ideal-feedback chỉ giữ làm upper/reference, **không phải proposed implementation cuối**.

Hai test suite: scalable swarm (`N ∈ {5, 20, 50}`, simplified dynamics) và physical realism
(`N = 5`, 6-DOF).

```
Safety      : SafeFail = 0 ở Nominal/Moderate; ≤ 5 % ở connected Stressed
Stability   : không divergence, không NaN
Pareto      : Causal-AoI non-dominated (§2.5) ở ≥ 75 % final connected scenario
Direction   : rate(Clean) < rate(Moderate) < rate(Stressed), nhất quán
Fairness    : conventional event phải được báo công bằng, KỂ CẢ condition nó thắng
```

### 6.3 EXP10C — Simulation freeze

Repository cuối phải có `results/`, `docs/`, `configs/`, `experiments/`, `reproduction/`, và một
master script `run_final_simulation_suite` (hoặc README với exact commands).

```
[ ] all protocol invariants PASS
[ ] all final runs persisted
[ ] all configs / version hashes persisted
[ ] all paper tables traceable to tidy.csv
[ ] all figures reproducible
[ ] 50-seed core statistics complete
[ ] no undocumented parameter retuning
[ ] clean-clone reproduction PASS
```

Sau đó tag `simulation-v1.0`.

---

## 7. Quy trình phối hợp

Mỗi experiment một branch: `exp07a-causal-ack`, `exp07b-ack-impairment`, `exp07c-cost-model`, …

1. Code + chạy **3 seeds** → push → báo commit hash.
2. Người dùng verify source + assumptions + metric + fairness + output.
3. Verdict: **PASS** (chạy final / sang EXP kế tiếp) / **FIX** (chỉ rõ file + logic) /
   **LOCK** (hoàn thành, không sửa nữa).
4. Chỉ khi PASS mới chạy **20 seeds** final.
5. Merge vào `main`, tag `<exp>-locked`.

---

## 8. Timeline

```
CURRENT
   │
   ▼
EXP07A  Explicit causal ACK
EXP07B  ACK loss / ACK delay
EXP07C  ACK + communication cost model
   │
   ▼
EXP08A  Multiple topologies
EXP08B  Link failures
EXP08C  Node communication dropout
   │
   ▼
EXP09A  Multi-UAV 6-DOF
EXP09B  Wind / model mismatch
EXP09C  Noise / estimator delay / dt
   │
   ▼
EXP10A  CRN + statistical fairness
EXP10B  Unified final stress test
EXP10C  Reproducibility + freeze
   │
   ▼
simulation-v1.0
```

---

## 9. Nhật ký thay đổi tài liệu này

Mọi thay đổi sau khi tag `prereg-exp07-exp10` phải được ghi ở đây, kèm lý do và commit hash.
Một pre-registration bị sửa mà không ghi nhật ký là một pre-registration vô giá trị.

| Ngày | Mục thay đổi | Lý do | Commit |
|---|---|---|---|
| 2026-08-21 | — | Bản chốt đầu tiên | (tag `prereg-exp07-exp10`) |
