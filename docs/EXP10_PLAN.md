# EXP10 PLAN — 50-seed holdout validation, unified matrix, freeze

**Trạng thái: AUTHORIZED. Amended trước khi chạy. Không sửa sau khi thấy số.**

Tài liệu này chốt **các điểm được chọn**, **seed block**, **thống kê**, **gate** và **quy tắc rút
kết luận** cho vòng validation cuối, trước khi nhìn thêm bất kỳ số nào. Không có tham số nào được
tune, không có v4 protocol, không có controller retuning.

Bối cảnh: chuỗi EXP07–EXP09 đã kết thúc với **một hỗn hợp kết quả dương, một phần và âm**. EXP10
không được phép biến hỗn hợp đó thành một câu chuyện toàn thắng bằng cách chỉ chọn những ô thuận
lợi. §13 tồn tại để chặn đúng việc đó.

---

## 0. Trạng thái kế thừa — cái gì đã đúng, cái gì đã bị bác

| Experiment | Tag | Kết quả |
|---|---|---|
| EXP07A | `exp07a-locked` | Causal-v3 **9/9** |
| EXP07B | `exp07b-locked` | 5/5, nhưng là **saturation, không phải robustness** |
| EXP07C | `exp07c-locked-negative` | **ÂM**: Stressed ACK-inclusive Pareto superiority **bị bác** |
| EXP08A | `exp08a-locked-partial` | 4/5; safety-generalization bị bác |
| EXP08A-D | `exp08ad-locked-diagnostic` | quy kết cho unnormalized consensus gain |
| EXP08B | `exp08b-locked-partial` | 2/3; safety fail **dùng chung mọi method** |
| EXP08C | `exp08c-locked-partial` | 1/3; safety fail ở outage 5 s, dùng chung |
| EXP09A | `exp09a-locked` | **7/7** dưới 6-DOF |
| EXP09B | `exp09b-locked-partial` | 4/5; G2 fail do **giới hạn controller**, không phải communication |
| EXP09C | `exp09c-locked-partial` | 3/4; Clean C3 DATA-rate gate fail do **noise-driven hard triggers**; timestep RMSE stable nhưng **DATA-rate dt-invariance bị bác** |

**Năm phát biểu đã bị bác hoặc giới hạn, và EXP10 phải giữ nguyên chúng:**

1. Stressed ACK-inclusive Pareto superiority — **đã bác (EXP07C)**. EXP10 **không** đặt lại claim
   này và Stressed **không có** superiority gate.
2. Safety generalization qua topology — **partial (EXP08A)**.
3. Safety dưới link/node fault — **fail, nhưng dùng chung mọi method (EXP08B/C)**.
4. Robustness với plant mismatch — **fail vì controller thiếu integral action (EXP09B)**, không
   phải vì communication.
5. Clean-scenario false-trigger bandwidth + DATA-rate dt-sensitivity — **fail (EXP09C)**.

---

## 1. Holdout seed block

```
exp10Seeds = 25000001:25000050;
```

50 seeds, **không** reuse development seed. Trước khi bất cứ gì được simulate,
`utils/assertExp10Seeds.m` chạy và **raise** (không warn) nếu:

1. **BLOCKER** — một EXP10 seed xuất hiện trong bất kỳ seed family EXP01–EXP09. Danh sách family
   được transcribe từ chính expression trong mỗi experiment script (`utils/exp10SeedFamilies.m`),
   với index range lấy **rộng hơn** vòng lặp thực tế: over-enumeration chỉ làm test khắt khe hơn.
2. **BLOCKER** — hai trace type trong EXP10 dùng chung một stream seed, tức sáu master realization
   của một seed không độc lập.
3. **REPORTED** — một EXP10 stream seed trùng stream seed của một locked experiment **thuộc trace
   type khác**. Vô hại và được báo cáo, không gate: hai stream đó tiêu thụ draw không liên quan
   trong hai experiment không liên quan, và không có gì trong EXP10 được so với realization của
   experiment đó. Trùng **cùng** trace type mới là vấn đề, và check 1 đã chặn ở gốc vì trùng cùng
   type đòi hỏi base seed bằng nhau.

**Seed count không đổi nếu CI không đẹp.** Thêm seed sau khi nhìn CI là chọn cỡ mẫu theo kết quả.

### 1.1 AMENDMENT — seed convention

EXP07–EXP09 nhét scenario / topology / N index vào `cfg.net.seed`, nên mỗi cell có realization
riêng. EXP10 **không**:

```
cfg.net.seed = exp10Seeds(s);     % nguyên vẹn, không offset
```

Seed một mình quyết định cả sáu master realization, đúng yêu cầu §4. Hai hệ quả, đều có chủ ý:

- Clean / Moderate / Stressed ở cùng seed **dùng chung một bộ channel uniform**. Scenario đổi
  **threshold** áp lên uniform đó (loss probability, delay), không đổi draw. Đây là CRN ngang
  scenario, và nó làm một chênh lệch scenario-to-scenario quy được cho chất lượng mạng thay vì
  cho may mắn của draw. Adaptivity criterion §11 dựa vào chính tính chất này.
- Forward và reverse trace có shape `(K x N x N)`, nên hash của chúng **khác nhau giữa các điểm
  N = 5 / 20 / 50 ở cùng seed**. Vì vậy hash equality là yêu cầu **trong một (point, scenario)
  ngang các method**, và **vô nghĩa** ngang các điểm khác N. Bảng registry được key theo cả N.

---

## 2. Final matrix — khóa chính xác plant / N / topology

Matrix nằm trong code, dưới dạng data: `utils/exp10Points.m`. EXP10A chạy nó, EXP10B aggregate
dataset EXP10A sinh ra, và `run_simulation_v1_validation` re-derive từ cùng file đó, nên không
stage nào có thể lặng lẽ chạy một matrix khác stage khác.

**Main nominal:**

```
N = 5, plant = 6-DOF followers, topology = ring2, controller = original
scenarios = Clean / Moderate / Stressed
methods   = P10 / P20 / State-event / Causal-v3
```

Clean được thêm lại vì final adaptivity criterion (§11) cần ba chất lượng mạng để order DATA.

**Selected robustness / scalability points:**

| id | N | plant | topology | perturbation | scenarios | nguồn |
|---|---|---|---|---|---|---|
| `NOMINAL` | 5 | 6-DOF | ring2 | — | Clean/Mod/Str | EXP09A `exp09a-locked` |
| `ACK` | 5 | 6-DOF | ring2 | ACK loss 10 %, ACK delay = DATA forward delay, ACK jitter 0 | Mod/Str | EXP07B `exp07b-locked` |
| `MISMATCH` | 5 | 6-DOF | ring2 | **B7**: external-force proxy 0.5 m/s² + true mass +10 % + true drag +20 % + no actuator lag | Mod/Str | EXP09B `exp09b-locked-partial` |
| `ESTIMATOR` | 5 | 6-DOF | ring2 | **C3**: σP 0.03 m, σV 0.05 m/s, latency 50 ms | Mod/Str | EXP09C `exp09c-locked-partial` |
| `LINK` | 20 | double-integrator | ring2 | permanent directed-link removal 20 %, original controller | Mod/Str | EXP08B `exp08b-locked-partial` |
| `NODE` | 20 | double-integrator | ring2 | 1 follower communication blackout, duration 5 s, start 12 s | Mod/Str | EXP08C `exp08c-locked-partial` |
| `N20REF` | 20 | double-integrator | ring2 | — (**denominator bắt buộc**, xem §2.1) | Mod/Str | EXP08C `exp08c-locked-partial` |
| `SCALE` | 50 | double-integrator | ring2 (EXP08 graph convention) | không fault | Mod/Str | EXP06A (untagged) |

**17 cell × 4 method × 50 seed = 3400 run.**

Lý do chọn điểm: mỗi điểm robustness là **điểm đã lộ ra một giới hạn** trong experiment gốc, không
phải điểm đẹp nhất. `permanent 20 %` và `1-node 5 s` là nơi safety gate đã fail; `B7` là nơi G2
fail; `C3` là nơi G3 fail. Chọn điểm dễ sẽ khiến EXP10A xác nhận một thứ chưa từng bị nghi ngờ.

Final coverage:

```
N = 5   : physical realism (6-DOF)
N = 20  : connectivity faults
N = 50  : scalability anchor
```

**Không so absolute traffic của N=50 ngược với EXP06A.** EXP06A dùng `applyScalableSwarmConfig`
(giữ in-link vào leader); EXP10 dùng `applyTopologyConfig` như toàn bộ EXP08–09 (bỏ in-link vào
leader vì leader đọc reference trực tiếp). Hai convention có channel count khác nhau ở cùng N. Chỉ
tỉ số giữa các method **trong** EXP10 là so được, vì mọi method ở đây chạy trên cùng graph.

### 2.1 AMENDMENT — thêm điểm `N20REF`

`N20REF` **không phải một kết quả thêm**, nó là **denominator bắt buộc**. §6 giữ nguyên eligibility
rule của experiment nguồn, và rule của EXP08C là **matched no-fault eligibility**: một seed chỉ
được tính nếu **cùng method / scenario / topology / N / seed đã safe khi KHÔNG có fault**. Không có
`N20REF`, rule đó không evaluable, và failure rate của `NODE` sẽ quy một vấn đề hình học có từ
trước cho communication fault. `N20REF` đồng thời là reference mà classification connectivity của
`LINK` được đọc ngược lại.

Đây là amendment **trước khi chạy**, không phải sau khi thấy số, và nó **mở rộng** denominator chứ
không thu hẹp nó.

### 2.2 `ACK` point và ba baseline

Chỉ Causal-v3 có ACK channel. P10 / P20 / State-event không đọc `cfg.ack.*` gì cả, nên run của
chúng ở `ACK` point phải **bit-identical** với run `NOMINAL` cùng seed cùng scenario. Điều đó
không được giả định: nó là **protocol invariant G4** trong §7, và là leak detector — nếu
`cfg.ack.loss` đến được một baseline qua đường nào đó, đây là nơi nó hiện ra.

---

## 3. Periodic phase fairness

Historical locked results **phase OFF** và giữ nguyên như vậy.

EXP10 dùng:

```
cfg.net.phaseOffsetEnabled = true;
```

Phase **không** random theo directed link. Draw là một uniform cho mỗi
`(physical sender, payload class)`:

```
phaseU(seed, physicalSender, payloadClass) ∈ [0,1)
phaseOffset = phaseU * period
```

- `u(1:N)` — neighbour-state payload của physical sender j
- `u(N+1)` — leader payload (physical sender là node 1, nhưng payload còn chở acceleration nên nó
  là payload class riêng trên cùng radio)

Ba tính chất, mỗi cái sẽ mất nếu draw theo link:

1. **Cùng sender + payload class có cùng phase tới mọi receiver.** Một radio phát một lần là tới
   mọi listener cùng lúc. Phase theo directed link sẽ phá broadcast synchronization — ý nghĩa vật
   lý của một periodic radio — và **chế tạo ra một lợi thế cho event-triggered method từ thuần
   accounting**.
2. **P10 và P20 dùng cùng `phaseU`**, scale theo period riêng. `u` không phụ thuộc
   `cfg.net.commPeriod`.
3. `u` không phụ thuộc method, không phụ thuộc lượng traffic, không phụ thuộc outer step.

**State-event / Causal-v3 không dùng phase offset** — chúng không có periodic clock. Phase phải để
chúng bit-identical; đó là check trong `tests/test_exp10_infrastructure.m`.

Phase trace là pre-generated, reproducible và hashable (`utils/generatePhaseTrace.m`).

**Quantization, được báo cáo không che:** offset là liên tục, nhưng một transmission vẫn xảy ra
trên một outer step, nên phase **thực tế** bị quantize về `cfg.swarm.dt`. Ở dt = 0.02 s so với
period 0.05 s đó là một lưới thô. Điểm của thay đổi này là sender **thôi phát đồng loạt**, không
phải phase được resolve tới độ chính xác tùy ý.

### 3.1 RECORDED FINDING — flag `cfg.net.phaseOffset` cũ chưa bao giờ có tác dụng

`network/simSwarmNetworkQueued.m` từng tính một `linkPhase` matrix khi `cfg.net.phaseOffset` bật,
**nhưng không có gì đọc nó**: transmission decision chỉ dùng một `nextCommTime` toàn cục. Vì vậy
mọi locked result đã chạy trên **một global clock bất kể flag**, và nhãn "phase OFF" của chúng là
đúng.

Điều này được **ghi lại thay vì lặng lẽ sửa**. Flag cũ và default của nó được giữ (mọi script
EXP07–09 set nó explicit, và `test_lock_regression` check nó default off); dead code tính
`linkPhase` bị xóa vì nó không đổi số nào và để lại sẽ khiến người đọc tin rằng phase đã được
model. Flag thật là `cfg.net.phaseOffsetEnabled`, default OFF, additive.

---

## 4. CRN final — sáu master realization mỗi seed

Mỗi seed có **một** bộ realization bất biến:

```
forward network trace       generateNetworkTrace     offset 20240001
reverse ACK trace           generateAckTrace         offset 30240001
phase trace                 generatePhaseTrace       offset 90240001
link-fault realization      generateFaultRealization offset 50240001
node-blackout realization   generateBlackoutRealization offset 60240001
wind / external-force trace generateExternalForceTrace  offset 70240001
estimator noise trace       generateNoiseTrace       offset 80240001
```

`utils/exp10Registry.m` tính hash của cả bảy, **một lần cho mỗi (N, seed), trước khi có simulation
nào**. Thứ tự đó quan trọng: check là so với một giá trị đã chốt trước, không phải so với một giá
trị được re-derive từ cùng code trong cùng vòng lặp — cái sau chỉ chứng minh code deterministic.

Nếu một selected point không dùng một trace type, realization đó **vẫn tồn tại** nhưng không ảnh
hưởng RNG của phần khác: mỗi generator draw từ RandStream riêng seeded bằng `cfg.net.seed` cộng
offset riêng, và §1 check 2 chứng minh bảy stream rời nhau.

**Assertions:**

```
same seed + same point:   trace hash identical across methods
                          (forward: cả 4 method; reverse: Causal, baseline = NaN;
                           phase: P10 = P20, event-driven = NaN)
different seed:           realization differs (continuous type)
packet/event count:       does NOT consume/advance underlying random realization
```

Assertion thứ ba là thứ đắt nhất nếu sai và dễ nhất để kiểm: bốn method phát số packet rất khác
nhau ở cùng seed, và cả bốn phải report **cùng** forward hash. Nếu realization bị tiêu thụ theo
transmission thay vì index theo `(link, timestep)`, method ồn hơn sẽ gặp channel khác và **mọi**
paired statistic trong EXP10 mất cơ sở.

**Discrete realization được report, không gate.** Link nào down và node nào dark là draw từ một tập
hữu hạn nhỏ — ở N = 5 ring graph có 8 directed link và removal 20 % down đúng 2 cái, tức chỉ có 28
realization khả dĩ. Hai seed trùng pattern là tính chất của intervention, không phải collision, và
nó không duplicate gì: hai seed đó vẫn gặp channel, phase và noise khác nhau. Cardinality được in
ra để một con số nhỏ đáng ngờ hiện lên, thay vì bị gate ở phía sai.

---

## 5. Key claims — chốt trước, đúng ba cái

```
K1   Nominal Stressed, paired RMSE(Causal - P10)
     directional hypothesis: < 0

K2a  Nominal Stressed, paired DATA(Causal - P20)
     NO directional gate

K2b  Nominal Stressed, paired TotalCost_w025(Causal - P20)
     TotalCost_w025 = DATA + 0.25 * ACK
     NO directional gate
```

K2 tách hai vì **EXP07C đã chứng minh ACK-inclusive cost có thể đảo conclusion của DATA-only**.
Báo cáo một DATA saving trong khi ACK-inclusive total tăng là đúng cái lỗi EXP07C ghi lại. Vì vậy
cả hai được report cạnh nhau và **không** cái nào có hướng.

K2a và K2b đều report **mean paired difference + 95 % CI**, ở cả đơn vị packet và Hz.

**Không claim communication saving nếu chỉ DATA giảm nhưng ACK-inclusive total tăng.** EXP10A in
ra kết luận đó explicit khi nó xảy ra.

EXP10B report thêm: `w = .10 / .25 / .50`, airtime proxy (DATA 48 B, ACK 24 B), broadcast
accounting proxy — cả ba y như EXP07C.

---

## 6. Paired statistics

CRN cho phép ghép cặp: cùng seed ⇒ cùng realization kênh, cùng fault, cùng nhiễu. Dùng **paired
difference**, không phải two-sample.

```
d      = metricA(seed) - metricB(seed)
meanD  = mean(d)
CI95   = meanD + [-1 1] * tinv(0.975, nPairs-1) * std(d)/sqrt(nPairs)
```

Với sample đủ, `nPairs = 50` và `tinv(0.975,49)`.

**K1 PASS-support chỉ khi `upper CI < 0`.**

Nếu CI chứa 0 ⇒ **INCONCLUSIVE AT 50 SEEDS**. Không thêm seed.

**nPairs không được bỏ im lặng.** Nếu một cặp có arm diverged, cặp đó không dùng được. `pairedCI`
report `nRequested`, `nPairs`, `nDropped`, `complete`. Nếu `complete = false`, claim bị **hạ cấp**
và không được trích như một 50-seed paired CI.

**Safety binary metric không bị ép vào t-CI.** Một failure rate là proportion trên một denominator
đã lọc theo eligibility; bọc nó trong t interval vừa sai phân phối vừa che đúng cái denominator mà
rule nói về. Giữ **raw paired count / rate** và **eligibility rule gốc của experiment nguồn**:

- `LINK` — EXP08B: denominator là các seed mà active graph vẫn connected.
- `NODE` — EXP08C: matched no-fault eligibility (xem §2.1).
- các điểm không fault — mọi seed là evidence.

---

## 7. EXP10A gate — infrastructure, không phải khoa học

EXP10A PASS infrastructure nếu:

```
G1  100 % matching trace hashes where traces should match
G2  0 missing result rows, và cả 50 holdout seed dùng đúng một lần
    cho mỗi method / point / scenario
G3  0 unlabeled NaN  (NaN chỉ được phép ở nơi DIVERGED được set)
G4  all protocol invariants = 0
      causal invariant violations = 0
      baseline ACK traffic = 0
      ACK-point baseline runs bit-identical với NOMINAL (§2.2)
G5  mọi K1/K2 output có paired statistics
```

Divergence labelling completeness được **report**: `MAXDEV` (khoảng cách xa nhất một follower đạt
tới so với leader) được lưu mỗi run, và số run vượt quả cầu 50 m mà **không** mang nhãn DIVERGED
được in ra. Không dựng thêm criterion divergence mới sau khi đã thấy số; nhưng một run như vậy
phải nhìn thấy được.

**Scientific K1 có thể PASS / FAIL / INCONCLUSIVE; đó không phải lý do sửa run.**

---

## 8. EXP10B không chạy một stochastic dataset thứ hai

EXP10A sinh toàn bộ 50-seed dataset. **EXP10B chỉ aggregate / analyze chính dataset đó**, đọc
`results/exp10a_final_validation/<LATEST>/tidy.csv`. Nếu file không có, EXP10B **dừng**; nó không
fallback sang tự chạy sweep.

Sinh một dataset stochastic thứ hai cho "unified matrix" sẽ khiến bảng headline mô tả một
realization khác với các paired CI, và hai cái có thể mâu thuẫn mà không cái nào sai.

Mọi passive counter EXP10B cần đã được log trong EXP10A: `txCount`, `ackTxCount`,
`broadcastCount`, `rxCount`, `dropCount`, `staleDiscardCount`, `meanAoI`, `estimatedAoI`, branch
ratio, saturation, effort, connectivity classification, và cả bảy realization hash.

EXP10B **re-verify hash từ file đã persist**, bằng một script khác — đó là điều khiến dataset
auditable thay vì self-certified.

---

## 9. Unified table — cột bắt buộc

```
Point | Plant | N | Topology | Scenario | Method
RMSE mean/std | minSep | SafeFail (count / eligible / rate / rule)
DATA | ACK | Total_w010 | Total_w025 | Total_w050 | airtime | broadcast proxy
AoI | estimated AoI
saturation | effort | estimator error
diverged | evaluable count | connected count
dominance under each cost model
source locked experiment / tag
```

**Quy tắc bắt buộc:**

- Bảng chứa **mọi** ô đã chạy, kể cả ô Causal-v3 thua. Không lọc.
- Mỗi kết quả âm hoặc partial ở §0 phải xuất hiện trong §13, kèm tag gốc.
- Với mỗi ô, ghi **method thắng** theo RMSE và theo cost. Nếu Causal-v3 không thắng, ghi ai thắng
  và in NOTE.

---

## 10. Pareto final — scenario stratified

Dominance dùng **pre-registered 1 % rule** của EXP07C, không đổi: method M bị **dominated** nếu tồn
tại M' có **cả** `RMSE(M') ≤ 0.99·RMSE(M)` **và** `cost(M') ≤ 0.99·cost(M)`.

Một cell **evaluable** chỉ khi mọi method trong nó có mean RMSE và cost hữu hạn. Cell không
evaluable được **đếm và nêu tên**, không drop im lặng — denominator co lại chính là cách một
fraction bị làm đẹp.

**Moderate:**

```
report fraction of evaluable selected point-families where Causal is non-dominated
reference criterion: >= 75 % under w = 0.25
also report: w = .10 / .50 / airtime / broadcast
```

Nếu Moderate < 75 % ⇒ final Moderate Pareto claim **bị hạ cấp**, và không được phát biểu
"competitive with periodic in Moderate".

**Stressed:**

```
NO superiority gate.
Report dominance / non-dominance honestly, under all five cost models.
```

Gate "Stressed Pareto superiority" **không được phục hồi**; EXP07C đã bác nó.

---

## 11. Final adaptivity criterion

Trên nominal N=5 6-DOF, Causal-v3:

```
DATA:  Clean < Moderate < Stressed
```

Không yêu cầu khớp rate historical, vì phase và holdout seed đều mới.

Báo cùng lúc **DATA Hz**, **ACK Hz** và **Total_w025**, để thấy adaptation đổi *actual total
communication* thế nào — DATA một mình không nói điều đó, và EXP07C đã cho thấy ACK-inclusive cost
có thể đi hướng khác.

---

## 12. Quy tắc rút phát biểu — không preregister sẵn kết luận

Draft trước ghi sẵn câu kết luận theo kiểu outcome đã biết. Thay bằng **rule** tạo ra kết luận:

```
Nếu  mean RMSE(Causal) < mean RMSE(State-event)  trong MỌI cell của final matrix:
     cho phép phát biểu "lower RMSE than State-event throughout the final matrix"
Ngược lại:
     enumerate exceptions explicitly, và phát biểu unconditional KHÔNG được dùng
```

Tương tự, "competitive with periodic in Moderate" chỉ được phép nếu Moderate criterion §10 đạt.

**Không khóa conclusion trước data; khóa rule để tạo conclusion.**

---

## 13. Negative-result preservation

EXP10B final report phải có một section cố định:

```
LOCKED LIMITATIONS — NOT RE-TESTED AWAY
```

và giữ nguyên:

| Nguồn | Giới hạn được giữ |
|---|---|
| EXP07C | Stressed ACK-inclusive Pareto superiority **rejected** |
| EXP08A | topology safety generalization **partial** |
| EXP08B | link-fault absolute safety **failed** (dùng chung mọi method) |
| EXP08C | 5-s node-blackout safety **failed** (dùng chung mọi method) |
| EXP09B | absolute mismatch-RMSE robustness **failed**; mass mismatch bộc lộ steady offset / thiếu disturbance rejection |
| EXP09C | Clean noise gây false-trigger traffic **> 2×**; communication rate **phụ thuộc materially vào outer dt** |

**Không cho kết quả EXP10 favorable ghi đè các kết luận này.** EXP10 chạy **một** selected point
cho mỗi giới hạn, trên seed mới; một điểm không retract được một sweep. Ở nơi EXP10 **không có
evidence** — topology khác ring2, estimator point ở Clean, dt khác 0.02 s — điều đó được nói ra
explicit thay vì để im lặng đọc thành đã sửa.

---

## 14. EXP10C — reproducibility / freeze

Master entry point: `experiments/run_simulation_v1_validation.m`. Một command phải:

```
1  run tests                      tests/run_all_tests.m, toàn bộ 9 file
2  validate tags/config           10 locked tag hiện diện + SHA; config hash
3  run/reload EXP10 dataset        reload nếu có; v1ForceRun = true để chạy lại
4  rebuild final tables            gọi exp10b_unified_matrix trên dataset đã persist
5  rebuild final figures
6  verify hashes                   registry vẽ lại trong session này, so với dataset
7  serial vs parallel determinism  một seed, 4 method
8  environment manifest
```

Blocker: 1, 2, 6, 7 fail ⇒ **không freeze**. Kết quả khoa học xấu **không** phải blocker.

**Environment manifest** (`manifest.json` trong run dir):

```
git SHA + branch + clean/dirty
locked tag -> SHA map
MATLAB version / release / date
toolbox + version list
OS / platform / arch / core count
parallel pool configuration + worker-cap note
seed list
config hash (defaultConfig + từng point)
trace hash fold (per type) + trace_hashes.csv (một row mỗi (N, seed))
experiment timestamp
dataset run id (EXP10A, EXP10B) + row count + completeness
```

**Deterministic check:** một seed đã chọn, `NOMINAL / Stressed`, cả 4 method, **serial execution
trong client vs parallel execution trên pool worker**. So sánh **bit-identical**: RMSE, minSep,
DATA, ACK, broadcast, rx, drop, forward hash, reverse hash, invariant count, **và toàn bộ
trajectory**.

**Không nới tolerance.** Mọi stochastic input là realization pre-drawn indexed theo
`(link, timestep)` hoặc theo physical time, và cả hai simulator pin generator explicit với
`rng(seed,'twister')` vì pool worker default sang generator khác client. Không có nguồn khác biệt
hợp lệ nào giữa serial và parallel; một tolerance chỉ che nó. Nếu bit-identity fail, việc phải làm
là tìm nguyên nhân.

**Clean-clone test:**

```
clone fresh
checkout final candidate
run test suite
run lock regression
run one EXP10 smoke seed
rebuild final summary from persisted tidy files
```

`results/*.mat` và `*.fig` không nằm trong version control, nhưng `console.log`, `tidy.csv`,
`meta.json` và PNG thì có — nên rebuild-from-persisted là chạy được trên một clone sạch.

`results/INDEX.md` phải map: experiment → tag → commit → result directory → status
positive/partial/negative.

`docs/FINAL_CLAIMS.md` ba nhóm: **SUPPORTED** / **LIMITED — CONDITIONAL** / **REJECTED**. Mỗi
claim trỏ về experiment / tag / result.

Sau tất cả: tag `simulation-v1.0`. **Không tag nếu tests / regression / hash / reproduction fail.**

---

## 15. Execution policy

Đây là final batch. Không report giữa EXP10A và EXP10B.

**STOP** chỉ khi có:

```
CRN / phase realization mismatch
locked regression failure
passive accounting altering decisions
fault / noise / mismatch semantics changed
missing / duplicate seed
paired-data construction ambiguity
serial-vs-parallel reproducibility problem
```

**KHÔNG STOP, KHÔNG TUNE, KHÔNG ĐỔI MATRIX** khi:

```
scientific result xấu
K1 fail hoặc inconclusive
Moderate Pareto < 75 %
State-event có counterexample
safety fail
```

Hoàn tất 50 seed và freeze đúng kết quả.

---

## 16. Những gì EXP10 **không** làm

- Không thiết kế v4 protocol.
- Không retune controller, threshold, cost model hay Pareto definition.
- Không cứu một gate âm bằng cách đổi điều kiện đo.
- Không thêm seed sau khi nhìn CI.
- Không mở rộng scope ra topology, dt hay arm mà EXP10 không chạy.

---

## 17. Amendment log

Ghi lại mọi thay đổi so với draft trước, kèm lý do. Tất cả **trước** khi chạy.

| # | Amendment | Lý do |
|---|---|---|
| A1 | EXP09C status: `pending` → `exp09c-locked-partial`, 3/4 | EXP09C đã xong và tag. |
| A2 | Seed block `25000001:25000050`, cộng automated holdout assertion | §1. Development seed không phải independent evidence. |
| A3 | Seed **không** nhét scenario/topology/N index (khác EXP07–09) | §1.1. Seed một mình quyết định sáu master realization, đúng §4; và cho CRN ngang scenario, cần cho §11. |
| A4 | Thêm điểm `SCALE` (N=50) | Final coverage không được mất scalability anchor. |
| A5 | Thêm điểm `N20REF` (N=20 no-fault) | §2.1. Matched no-fault eligibility của EXP08C không evaluable nếu thiếu. Mở rộng denominator, không thu hẹp. |
| A6 | Thêm lại Clean vào `NOMINAL` | §11 cần ba chất lượng mạng. |
| A7 | Phase ON qua flag mới `phaseOffsetEnabled`, per sender + payload class | §3. Flag cũ là no-op (§3.1); phase theo directed link sẽ chế tạo lợi thế giả cho event-triggered. |
| A8 | `K2` → `K2a` (DATA) + `K2b` (DATA + 0.25·ACK), cả hai không hướng | §5. EXP07C đã chứng minh ACK-inclusive cost đảo được conclusion DATA-only. |
| A9 | `pairedCI` report `nPairs` / `complete`; claim hạ cấp nếu thiếu cặp | §6. Drop cặp im lặng rồi vẫn gọi là 50-seed CI là overstate. |
| A10 | Safety binary giữ raw count/rate + eligibility rule gốc, không t-CI | §6. |
| A11 | `realizationHash` mới cho logical/discrete realization | Formula `localHash` của trace generator collapse mọi logical input về 0, nên hash check của link-fault / blackout sẽ pass trên realization không khớp. Formula cũ **không** đổi (nó nằm trong locked result table). |
| A12 | Discrete fault realization: report cardinality, không gate distinctness | §4. Tập realization hữu hạn nhỏ; trùng pattern là tính chất intervention. |
| A13 | Statement Causal-vs-State-event: rule thay vì conclusion | §12. |
| A14 | `MAXDEV` column + report far-but-unlabelled | §7. Divergence labelling completeness nhìn thấy được, không dựng criterion mới sau khi thấy số. |
| A15 | Worker cap theo N (16 / 12 / 8) | Memory ở N=50; chỉ ảnh hưởng scheduling, và §14 bước 7 verify kết quả độc lập với nó. |
| A16 | Smoke hook `exp10SmokeSeeds` | Debug infrastructure. Không thể giả dạng final run: seed list vào console.log, vào mọi row tidy.csv, và G2 check lại. Tiền lệ: EXP08B 3-seed debug run. |
