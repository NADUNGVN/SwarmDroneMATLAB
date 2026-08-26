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

`E_max` = `max e(t)` trên khoảng `[max(thời điểm lỗi bắt đầu, 8 s), hết run]`.

**Peak AoI dùng đúng cửa sổ này.**

*Sửa đổi 2026-08-22 (đo lường, không phải tuning).* Định nghĩa ban đầu lấy mốc là thời điểm lỗi
bắt đầu. Với **permanent fault**, lỗi bắt đầu tại `t = 0`, nên cửa sổ nuốt trọn transient khởi
động và `E_max` đo transient chứ không đo phản ứng với lỗi. Bằng chứng: trong cùng một seed,
`E_max` **trùng khít tới từng chữ số** giữa P10, P20 và Causal-v3 (`2.356607` cho cả ba tại
ring2 / Moderate / perm 20 %) — dấu hiệu của một đại lượng không phụ thuộc phương thức truyền
tin. Gate `E_max(Causal) ≤ 1.25 × E_max(P10)` vì thế pass một cách vô nghĩa ở 16/24 condition.

Mốc `8 s` là đầu evaluation window đã dùng cho **mọi** metric khác trong dự án, nên đây là việc
áp lại một quy ước sẵn có, không phải đưa ra một hằng số mới.

**Burst fault không đổi hành vi**: burst bắt đầu tại `t = 12 s > 8 s`, nên `max(tFault, 8) =
tFault`. Sửa đổi này chỉ tác động tới permanent fault và condition `none`.

Sửa đổi làm gate **khó hơn**, không dễ hơn: bỏ transient đi thì `E_max` mới thực sự phân biệt
được các phương thức, và một PASS trước đây có thể lật thành FAIL.

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
| reliable | 0 % | = delay DATA của scenario (kênh đối xứng), sàn `dt` |
| moderate | 10 % | = delay DATA của scenario, sàn `dt` |
| severe | 20 % | = 2 × delay DATA của scenario |

**`reliable` cũng chính là điểm vận hành của EXP07A.** Kênh ngược đi qua cùng một môi trường vật
lý với kênh xuôi, nên độ trễ đối xứng là giả định mặc định; EXP07A cô lập *tính nhân quả*, còn
EXP07B mới cô lập *suy giảm của kênh ACK*. Ở Stressed điều này cho RTT = 240 ms = 2 ×
`aoiThreshold`.

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

Ba gate và ba tỉ số **giữ nguyên**. Gate Safety là **tuyệt đối** và áp cho **mọi** connected
condition; **không** thêm điều kiện phụ kiểu "chỉ tại condition mà P20 cũng safe".

**Mẫu số của gate Safety** *(làm rõ 2026-08-22, không đổi gate)*. Với mỗi condition:

```
SafeFail = (số seed CONNECTED bị unsafe) / (số seed CONNECTED)  ≤  5 %
```

Mẫu số là **số seed connected của chính condition đó**, không phải số seed yêu cầu. Một seed có
đồ thị active đứt thuộc impossibility region nên bị loại khỏi **cả tử số lẫn mẫu số**: nó không
thể gây ra fail, và cũng không thể che một fail.

Điều này quan trọng khi một condition mất seed. Nếu **cả 20 seed đều connected**: `0/20` và
`1/20` PASS, `2/20` FAIL. Nếu chỉ còn **19 seed connected**: `1/19 = 5.26 %` đã **FAIL**. Không
được đọc luật này thành "luôn được phép một seed hỏng" — thứ bị chặn ở 5 % là **tỉ lệ**, không
phải số đếm.

**Khả năng đánh giá của gate Safety.** Ngưỡng 5 % chỉ phân giải được khi số seed đủ lớn. Ở 3
seeds, tỉ lệ khác 0 nhỏ nhất đo được là 1/3 ≈ 33 %, nên "≤ 5 %" thoái hoá thành "= 0" và mọi
verdict sẽ phản ánh số seed chứ không phản ánh phương thức. Vì vậy:

- **3 seeds** → gate Safety báo cáo là **DEFERRED / NOT EVALUABLE**. Số breach vẫn được in ra
  làm chẩn đoán, nhưng **không** được coi là PASS hay FAIL.
- **20 seeds** → gate Safety được đánh giá theo tỉ lệ ở trên.

**Báo cáo bắt buộc:** mỗi condition phải in `nConnected` và `nDisconnected`, để mẫu số của mọi
tỉ lệ đều kiểm chứng được từ log.

**Chẩn đoán bắt buộc kèm theo (không gate):**

- `minSepDuringFault` — khoảng cách nhỏ nhất **trong lúc lỗi đang hoạt động**. `minSeparationEval`
  trải trên cả evaluation window nên không nói được lần áp sát xảy ra trong hay sau outage.
- `traffic response` — số DATA/s **bên trong cửa sổ lỗi**, lấy từ log tích luỹ thụ động. Tổng cả
  run không phân giải được: một policy tăng vọt khi mất kết nối và một policy đi ngang có thể
  cho cùng một trung bình.
- **Số seed-condition có `E_max` trùng nhau giữa mọi method.** Follower mất sạch consensus
  in-link chỉ còn leader pin dẫn dắt, nên quỹ đạo của nó **trùng khít** dưới mọi policy; khi nó
  đồng thời là follower tệ nhất thì `E_max` không phân biệt được method và gate Peak không mang
  thông tin tại đúng những điểm đó. Ở bản 3 seeds: 13/69 connected seed-condition rơi vào trường
  hợp này, và **cả 13** đều có ≥ 1 isolated follower, trong khi **không** trường hợp nào có
  `isolated = 0` bị trùng. Đây là hiện tượng vật lý, không phải lỗi đo; ghi nhận chứ không sửa gate.
- **SafeFail theo từng method** trên các connected condition. Một breach mà *mọi* method đều mắc
  là tính chất của condition, không phải của policy; riêng gate không phân biệt được hai điều đó.

**Connectivity**: giữ nguyên phân loại λ₂ trên đồ thị đối xứng hoá ở §2.4. Báo cáo **kèm theo**
(không thay thế) `activeInDegreeMean` và `isolatedFollowers`, vì λ₂ có thể gần như mù với hỏng
hóc một chiều — ring2 giữ λ₂ = 0.4981 qua **mọi** mức fault, trong khi active consensus
in-degree đi 2.00 → 1.42.

Nếu graph thực sự disconnected: **không dùng condition đó để kết luận policy fail**. Ghi riêng
vào connectivity impossibility region.

### 4.3 EXP08C — Node communication dropout

Blackout 1 node / 2 node, thời lượng 2 s / 5 s, khôi phục sau đó. `N ∈ {10, 20}`,
topology ∈ {ring2, sparse4}, scenario ∈ {Moderate, Stressed}, method ∈ {P10, P20, State-event,
Causal-v3}. Blackout bắt đầu tại `t = 12 s`.

**Ngữ nghĩa fault (communication layer only).** Trong blackout, follower được chọn:
không gửi được DATA, không nhận được DATA, không gửi được ACK, không nhận được ACK.
Dynamics và controller **vẫn chạy bình thường**; `cfg.swarm.A` **không bị sửa**.

Khác với link failure của EXP08B ở một điểm ảnh hưởng tới kế toán traffic: ở đó sender không thể
biết link đã chết nên vẫn phát, gói vẫn được đếm rồi mới rớt. Ở đây **chính radio của node tắt**,
nên nó không phát và không có gì được đếm. Cả hai đều vật lý, chỉ là hai loại lỗi khác nhau.

**Không blackout leader** trong main experiment: mất leader là mất tham chiếu tuyệt đối duy nhất
của đội hình, đó là một thí nghiệm khác.

Node được chọn **pre-generated theo fault seed**, độc lập với method, để mọi policy gặp đúng
cùng những node tắt tại cùng thời điểm.

**Eligibility theo matched no-fault run.** Một seed chỉ được tính vào gate Safety nếu run
**no-fault tương ứng** (cùng method / scenario / topology / N / seed) đã **safe trước khi có
lỗi**. Nếu không, cấu hình đó vốn đã unsafe và blackout không phải nguyên nhân.

```
eligible          = matched no-fault run của cùng method/scenario/topology/N/seed đã safe
fault-induced SafeFail = nUnsafeAfterFault / nEligibleNoFaultSafe
```

**Gate chính (1-node blackout):**
```
Moderate : fault-induced SafeFail = 0 %
Stressed : fault-induced SafeFail ≤ 5 %
Recovery : T_recovery ≤ 5 s, chỉ áp khi graph reconnect/recoverable sau blackout
```

**Chẩn đoán so sánh (báo cáo cùng gate, không thay thế gate):**
```
Trec(Causal-v3) ≤ 1.25 × Trec(P20)
```

**2-node blackout là severe / characterization region.** **Không** dùng nó để thay đổi main
claim. Nếu báo target phụ thì giữ `≤ 10 %` và **phải ghi rõ là secondary**.

**Connectivity.** Node đang tắt bị cắt khỏi mạng **theo định nghĩa của can thiệp**, không phải
do bất khả thi. Nếu đưa nó vào đồ thị thì λ₂ = 0 ở **mọi** condition và phân loại không mang
thông tin gì. Vì vậy λ₂ được tính trên **đồ thị con cảm sinh bởi các node còn phát sóng**
(vẫn theo §2.4: đối xứng hoá, gộp cạnh leader-pin, connected ⟺ λ₂ > 1e-9). Câu hỏi đúng là:
*phần còn lại của đội hình có còn liên thông sau khi bỏ node tắt ra không.*

Realization nào **disconnected** phải được **detect và gán nhãn DISCONNECTED / impossibility
region**, và **không** được tính thành communication-policy failure.

**Metric bắt buộc:** RMSE; peak formation error during blackout; minSepDuringBlackout;
true/estimated/peak AoI; DATA/s và ACK/s ở **pre / during / post** blackout; outstanding
mean/max; maxSilence probes; recovery time; `nEligibleNoFaultSafe`; `nUnsafeAfterFault`;
fault-induced SafeFail rate; λ₂; active consensus in-degree mean/min; isolated follower count;
disconnected duration; và

```
trafficRatio = DATA_rate_during_blackout / nominal_DATA_rate
```

để kiểm tra phát hiện **implicit failure-responsive suppression** của EXP08B (Causal-v3 giảm
còn 0.59–0.90× trong outage, State-event tăng 3.5–4.6×) có lặp lại dưới node blackout không.

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

## 8bis. Kết quả EXP07A đã đóng băng

### Causal-AoI-v1 — commit `a554163`, 8/9 gate

Bộ nhớ đơn: innovation và freshness đều lấy từ trạng thái đã được ACK. Trong một
round-trip, innovation không bao giờ có vẻ nhỏ đi, nên sender liên tục gửi lại thông
tin đang bay trên đường.

Trượt gate **Rate ceiling**: 26.19 Hz / 20 Hz. Ở Stressed, hard position trigger chiếm
**97.6 %** số lần truyền và nhánh AoI sụp còn **0.3 %**.

### Causal-AoI-v2 — commit `28759f2`, 7/9 gate

Bộ nhớ kép (innovation theo trạng thái *đã phát*, freshness theo trạng thái *đã được
ACK*), seq thật nằm trong header gói tin, ACK cộng dồn. In-flight suppression hoạt động
đúng: `supprInFlight = 0.742` ở Stressed, `meanOutstanding = 2.64`.

Trượt hai gate:

```
Stressed: Causal < P10            0.1536 vs 0.1455
Rate ordering: Clean<Mod<Stress   8.41 < 9.07 < 9.07 Hz
```

**Nguyên nhân — ràng buộc chặn là `aoiMinInterTx`, một tham số ĐÃ KHOÁ.**

Suppression loại gần hết hard state trigger (posTrig 3.7 %), nên hầu như toàn bộ lưu
lượng chuyển sang nhánh AoI (aoiTrig 95.5 %). Nhưng nhánh AoI bị `aoiMinInterTx = 0.10 s`
chặn cứng ở **10 Hz**. Vì thế rate bão hoà ở 9.07 Hz tại **cả** Moderate lẫn Stressed:
phương pháp mất khả năng tăng tải khi mạng xấu đi, đúng cái tính chất mà nó tồn tại để
thể hiện.

v1 truyền quá nhiều (26.19 Hz, không suppression). v2 truyền quá ít (9.07 Hz, đụng trần
cooldown). Không phiên bản nào được tune; cả hai đều chạy đúng bộ tham số đã khoá.

**v2 được đóng băng làm negative result hợp lệ.** Đây là kết quả khoa học, không phải
thất bại kỹ thuật: nó xác định chính xác tham số nào đang giới hạn phương pháp dưới điều
kiện nhân quả, và tham số đó không được phép chỉnh trong phạm vi pre-registration hiện tại.

### Chuỗi ablation nhân quả — đóng góp thật của feedback

| Bước | Clean | Moderate | Stressed |
|---|---|---|---|
| A1 → A2c  AoI coupling | +43.93 % | +31.73 % | +33.46 % |
| A2c → A3c adaptive scale | +15.04 % | +6.07 % | +5.40 % |
| **A3c → A4c real feedback** | **+0.00 %** | **+4.92 %** | **+4.88 %** |

So với chuỗi ideal-feedback (0.00 / 5.71 / **16.07**): dưới ACK thật, đóng góp của
accepted-state feedback ở Stressed **giảm từ 16.07 % xuống 4.88 %**, tức bản ideal đã
phóng đại khoảng **3.3 lần**.

Ngược lại, `A1 → A2c` gần như không đổi (33.46 so với 32.89). **Cơ chế AoI coupling là
phần vững chắc nhất của phương pháp và không phụ thuộc vào oracle.** Đây là kết luận nên
mang vào bài báo.

---

## 8ter. Causal-AoI-v3 — Innovation-priority causal communication

Pre-register **trước khi chạy**. Không tham số nào thay đổi so với v1/v2.

### Chẩn đoán dẫn tới v3

v2 thất bại vì `aoiMinInterTx = 0.10 s` vô tình trở thành **trần cho thông tin mới**, chứ
không phải cho việc lặp lại. Sau khi in-flight suppression loại gần hết hard trigger, hầu
như toàn bộ lưu lượng đi qua nhánh AoI, mà nhánh đó bị cooldown chặn ở 10 Hz. Kết quả là
rate bão hoà 9.07 Hz ở cả Moderate lẫn Stressed.

v3 **không đổi giá trị** `aoiMinInterTx`. Nó chỉ trả tham số này về đúng vai trò: điều tiết
**refresh/retransmission**, không điều tiết **thông tin mới**.

```
new information  ≠  retransmission
```

### Bốn nhánh quyết định

Tại sender, với `lastSentPos/Vel` (bộ nhớ innovation) và `lastAckedGenTime` (bộ nhớ freshness):

```
dp    = norm(currentPos - lastSentPos)
dv    = norm(currentVel - lastSentVel)
aoiEst = tk - lastAckedGenTime + 0.5*dt
scale  = adaptiveScale(aoiEst)          % công thức hiện có, không đổi
```

**1. HARD NEW INFORMATION**
`dp >= epsP OR dv >= epsV`
→ truyền. Chỉ chịu `minInterTx = dt`.

**2. FRESHNESS-ADAPTIVE NEW INFORMATION**
`aoiEst >= aoiThreshold AND (dp >= scale*epsP OR dv >= scale*epsV)`
→ truyền. Chỉ chịu `minInterTx = dt`. **KHÔNG chịu `aoiMinInterTx`.**
Đây là điểm sửa cốt lõi: trạng thái đã thay đổi đủ so với gói đã phát gần nhất thì đó là
thông tin mới, không phải bản sao.

**3. REFRESH / RETRANSMISSION**
Stale nhưng innovation chưa đủ.
→ **chịu `aoiMinInterTx = 0.10 s`**, và
→ **không được gửi nếu vẫn còn packet outstanding/in-flight.**

**4. MAX-SILENCE**
`maxSilence = 0.50 s` là cơ chế recovery cuối cùng.

### Quy tắc bắt buộc của nhánh refresh

> Nhánh refresh **không được** phát nếu còn một packet outstanding chưa được ACK.

Nếu packet đó đã mất và không bao giờ được ACK, `maxSilence = 0.50 s` là cơ chế phục hồi.

**Không thêm RTO mới trong v3.** Không `RTT × 1.5`, không `outstandingThreshold`, không
window size. v3 tồn tại để kiểm tra xem **chỉ riêng việc sửa ngữ nghĩa** đã đủ hay chưa.

Ràng buộc nhân quả: quyết định refresh chỉ được nhìn *có hay không* packet outstanding.
Nó **không** được nhìn `rec.dropped` — sender thật không biết gói của mình có bị rơi hay
không. `dropped` chỉ dùng cho counter kiểm chứng.

### Ablation mở rộng: A5c

```
A1   State-event
A2c  + causal AoI coupling
A3c  + adaptive scale
A4c  + causal ACK / dual memory          = v2
A5c  + innovation/refresh separation     = v3
```

A4c → A5c trả lời đúng một câu hỏi cơ chế: **tách "thông tin trạng thái mới" khỏi "lưu
lượng refresh" mang lại bao nhiêu cải thiện?**

### Gate — giữ nguyên cả 9, không đổi vì v1/v2 trượt

```
[1] Causality invariants = 0
[2] Clean    : |Causal - Ideal| / Ideal <= 2 %
[3] Moderate : Causal RMSE <= 1.10 x P10
[4] Stressed : Causal RMSE <  P10
[5] Moderate : Causal RMSE <  State-event
[6] Stressed : Causal RMSE <  State-event
[7] Adaptive rate  : Clean < Moderate < Stressed
[8] Resource ceiling: Stressed DATA rate <= 20 Hz/channel
[9] Safety   : SafeFail = 0
```

### Invariant bổ sung (không phải performance gate)

```
newInfoBypassWithoutInnovation   = 0   nhánh 1/2 phát mà không có innovation thật
refreshWhileUsefulPacketInFlight = 0   nhánh 3 phát khi còn packet outstanding
senderRollbackCount              = 0
unknownSeqAckCount               = 0
ackForDroppedDataCount           = 0
futureGenTimeCount               = 0
seqGenTimeMismatchCount          = 0
staleAckAcceptedCount            = 0
ackBeforeAcceptCount             = 0
```

`aoiMinInterTx` phải **vẫn thực sự hoạt động** trong v3, và phải có counter
`refreshCooldownBlockedCount > 0` để chứng minh nó vẫn điều tiết refresh. Nếu counter này
bằng 0 thì tham số đã trở thành code chết và kết quả không hợp lệ.

### CRN thật, bắt buộc từ v3

`cfg.net.useTrace = true` cho **Periodic10, Periodic20, State-event, Causal-v3**, dùng chung
trace theo `scenario × seed × time × directed-link`. Method không phát ở một slot thì không
tiêu thụ outcome ở slot đó.

`phaseOffset` giữ **OFF** ở EXP07A-v3, để không đồng thời thay đổi thêm một yếu tố của
periodic baseline. Phase-offset fairness để dành cho EXP10A.

Ideal-AoI giữ đường legacy vì nó chỉ là reference; ở Clean không có RNG nào được tiêu thụ
(loss = 0, jitter = 0) nên gate [2] không bị ảnh hưởng.

### Tiêu chí thành công thực sự

Điều cần thấy không phải một con số rate cụ thể, mà là **cơ chế tự sinh ra**:

```
R_Clean < R_Moderate < R_Stressed <= 20 Hz     và     RMSE_Causal < RMSE_P10 ở Stressed
```

Nếu đạt được mà **không đổi một threshold nào**, thì v1 và v2 trở thành hai failed design
ablation dẫn tới protocol v3 — chứ không phải hai lần tune hỏng.

---

## 8quater. Causal-AoI-v3 — kết quả final 20 seeds, EXP07A LOCKED

Final pass 20 seeds, CRN thật, không đổi tham số nào so với debug pass.
**Toàn bộ 9 gate PASS.**

```
[PASS] Causality: 8 invariants = 0                0
[PASS] Clean    : |Causal-Ideal|/Ideal            1.515 %
[PASS] Moderate : Causal <= 1.10 x P10            0.0875 vs 0.0956  (0.915)
[PASS] Stressed : Causal <  P10                   0.1170 vs 0.1462
[PASS] Moderate : Causal <  State-event           0.0875 vs 0.1670
[PASS] Stressed : Causal <  State-event           0.1170 vs 0.2581
[PASS] Rate ordering                              8.44 < 13.35 < 18.24 Hz
[PASS] Rate ceiling <= 20 Hz                      18.24 Hz
[PASS] Safety: SafeFail = 0                       0.00
```

### Ba phiên bản trên cùng một bộ tham số khoá

| | rate Clean / Moderate / Stressed | Stressed RMSE | Gate |
|---|---|---|---|
| v1 | 8.41 / 15.86 / **26.19** | 0.1049 | 8/9 — vỡ trần tài nguyên |
| v2 | 8.41 / **9.07 / 9.07** | 0.1536 | 7/9 — mất khả năng thích nghi |
| **v3** | **8.44 / 13.35 / 18.24** | **0.1170** | **9/9** |

v1 và v2 là hai **failed design ablation**, không phải hai lần tune hỏng: cả ba dùng đúng
`epsP=0.05, epsV=0.10, aoiThreshold=0.12, aoiMinInterTx=0.10, maxSilence=0.50`.

### Ablation A1 → A5c (20 seeds)

| Bước | Clean | Moderate | Stressed |
|---|---|---|---|
| A1 → A2c AoI coupling | +43.93 % | +32.02 % | +33.38 % |
| A2c → A3c adaptive scale | +15.04 % | +6.70 % | +6.24 % |
| A3c → A4c real feedback | +0.00 % | +4.63 % | +4.14 % |
| **A4c → A5c innovation split** | −1.52 % | **+13.41 %** | **+24.29 %** |

Tách "thông tin mới" khỏi "refresh traffic" là bước đóng góp lớn thứ hai của cả chuỗi, chỉ
sau AoI coupling. Ở Clean nó hơi âm (−1.52 %) vì không có delay nên phân biệt này gần như
không có ý nghĩa — ghi nhận đúng như vậy.

### Đóng góp thật của feedback, đo dưới điều kiện nhân quả

`A3c → A4c` cho **+4.63 % / +4.14 %** (Moderate / Stressed), so với **+5.71 % / +16.07 %**
của chuỗi ideal-feedback. Ở Stressed, bản oracle đã phóng đại đóng góp của accepted-state
feedback khoảng **3.9 lần**.

### Điểm cần nêu trong bài báo

`A5c` là phương án duy nhất đạt `FormFail = 0` ở Moderate (0.0875 < ngưỡng 0.10); `A4c` còn
0.85 và `A2c/A3c` còn 1.00. Ở Stressed không phương án nào đạt ngưỡng 0.10 — kể cả P20 —
nên ngưỡng đó đơn giản là quá chặt cho điều kiện mạng ấy, và điều này phải nói rõ thay vì
chỉ báo cáo `FormFail = 1`.

`A1 State-event` vẫn có `SafeFail = 0.05` ở Stressed; A5c là 0.

### Chi phí ACK

A5c ở Stressed: DATA 18.24 Hz + ACK 10.94 Hz. Dưới cost model giữa (`w = 0.25`) tổng là
20.98 Hz-equivalent, tức nhỉnh hơn P20 (20 Hz) khoảng 5 % nhưng RMSE tốt hơn 6 %. Đánh giá
Pareto đầy đủ thuộc về EXP07C.

**EXP07A LOCKED.**

---

## 8quinquies. EXP07B — kết quả final 20 seeds

Reverse-channel CRN bật (`cfg.ack.useTrace`), forward CRN bật, policy và grid không đổi.
**Cả 5 gate PASS.**

```
[PASS] Protocol: invariants = 0 trong 24 cell      0
[PASS] Protocol: no deadlock                       0.120 s vs maxSilence 0.50 s
[PASS] Moderate degradation <= 10 %                0.00 %
[PASS] Severe   degradation <= 25 %                0.00 %
[PASS] Moderate SafeFail <= 5 %                    0.00
```

### Cảnh báo bắt buộc khi trích dẫn: 0.00 % là BÃO HOÀ, không phải robustness

`adaptiveScale` bị ghim ở sàn 0.20 trong **11/12 cell Stressed** và **4/12 cell Moderate**.
Ở Stressed, `estAoI` chạy từ 0.310 tới 0.454 s qua các cell nhưng RMSE và rate **giống hệt
nhau tới bốn chữ số** (0.1173 / 18.24 Hz). Khi scale đã ở sàn, trigger không phân biệt được
mức độ cũ của thông tin, nên suy giảm ACK không đổi được bất kỳ quyết định nào.

Vì vậy phải phát biểu là: *protocol không hỏng dưới suy giảm ACK — không deadlock, không vi
phạm nhân quả, không mất an toàn — nhưng ở Stressed nó cũng không còn phân giải được mức độ
suy giảm.* Phần robustness **chỉ được chứng minh ở Moderate**.

Nguyên nhân cơ chế: `aoiAdaptRange = 1.00` khiến scale bão hoà ở 2 × `aoiThreshold` = 0.24 s.
Với RTT ≥ 0.24 s ở Stressed, ước lượng AoI vượt ngưỡng đó ngay lập tức. Đây là tham số khoá,
không được chỉnh trong phạm vi pre-registration hiện tại.

### Ở Moderate cơ chế thật sự hoạt động — nhưng trả bằng băng thông

| ACK cell | scale | rate [Hz] | RMSE | degradation |
|---|---|---|---|---|
| reliable | 0.283 | 13.38 | 0.0877 | 0.00 % |
| L10 D0 (moderate) | 0.278 | 13.87 | 0.0862 | −1.71 % |
| L20 D=fwd (severe) | 0.202 | 18.34 | 0.0772 | **−11.97 %** |

Degradation **âm**: ACK xấu đi → `estAoI` tăng → scale giảm → nhạy hơn → truyền nhiều hơn
(13.38 → 18.34 Hz, **+37 %**) → RMSE tốt lên. Phương pháp **đổi suy giảm ACK lấy băng thông**.
Gate chỉ ràng buộc RMSE nên nó pass dễ dàng; cái giá 37 % băng thông không nằm trong gate nào
và phải được nêu khi báo cáo.

### Kiểm chứng phụ

- **Baseline invariance**: P10/P20 có RMSE spread = `0.000e+00` qua cả 12 ACK cell ở cả hai
  scenario — cấu hình ACK không rò rỉ sang method không có kênh ngược.
- **Reordering được test thật**: 2777 stale ACK bị loại dưới jitter (503/1039 ở Moderate,
  392/844 ở Stressed). Với jitter = 0 kênh ngược là FIFO nên stale = 0, đúng như dự kiến.
- **Liveness**: khoảng lặng lớn nhất trên mọi link là 0.120 s, so với `maxSilence` 0.50 s.

**EXP07B LOCKED.**

---

## 8sexies. EXP07C — kết quả final 20 seeds: GATE KHOA HỌC KHÔNG ĐẠT

Accounting-only. Không đổi policy, threshold, ACK, CRN, cost model, định nghĩa Pareto hay
accounting. Logic y hệt commit `14701ff`; chỉ mở rộng phần báo cáo.

```
[PASS] Accounting invariants                        0 failure(s)
[FAIL] packet-w: non-dominated in >= 2/3 variants   1 of 3
[FAIL] Stressed conclusion holds in >= 2/3 families 0 of 3
```

**Implementation PASS, gate khoa học FAIL. Không tune gì.**

### Chi phí đo được

| Scenario | Method | RMSE | std | DATA/s | ACK/s | BCAST/s |
|---|---|---|---|---|---|---|
| Stressed | P10 | 0.1456 | 0.0022 | 120.00 | 0 | 60.00 |
| Stressed | **P20** | **0.1103** | 0.0008 | 240.00 | 0 | 120.00 |
| Stressed | State-event | 0.2571 | 0.0071 | 50.59 | 0 | 25.30 |
| Stressed | **Causal-v3** | **0.1170** | 0.0010 | 218.86 | **130.70** | 109.43 |

### Ma trận dominance

| Cost variant | Clean | Moderate | Stressed |
|---|---|---|---|
| packet-w 0.10 | non-dom | non-dom | **non-dom** |
| packet-w 0.25 | dom by P10 | non-dom | **dom by P20** |
| packet-w 0.50 | dom by P10 | non-dom | **dom by P20** |
| airtime | dom by P10 | non-dom | **dom by P20** |
| broadcast | dom by P20 | dom by P20 | **dom by P20** |

### Biên độ dominance ở Stressed, so với P20

| Cost variant | RMSE P20 tốt hơn | Chi phí P20 thấp hơn | Verdict |
|---|---|---|---|
| packet-w 0.10 | 5.75 % | **−3.48 %** | non-dom |
| packet-w 0.25 | 5.75 % | 4.58 % | DOMINATED |
| packet-w 0.50 | 5.75 % | 15.55 % | DOMINATED |
| airtime | 5.75 % | 15.55 % | DOMINATED |
| broadcast | 5.75 % | **50.03 %** | DOMINATED |

Biên độ này là thông tin quan trọng nhất của bảng: **RMSE của P20 tốt hơn 5.75 % ở mọi
variant** — con số đó không phụ thuộc cost model. Điều duy nhất thay đổi là chi phí. Ở
`packet-w 0.10`, Causal-v3 thoát dominance **chỉ nhờ rẻ hơn 3.48 %**; chỉ cần định giá ACK
nhỉnh hơn 1/10 gói dữ liệu là biên đó đảo dấu.

Nói cách khác: Causal-v3 ở Stressed **không** thua vì chi phí. Nó thua vì **RMSE vốn đã kém
P20 5.75 %**, và chi phí chỉ quyết định xem điều đó có thành dominance hay không.

### Broadcast là model khắc nghiệt nhất

Tỉ lệ dedup: periodic và state-event đạt **chính xác 0.500** vì mọi link từ cùng một sender
bắn đồng thời. Causal-v3 chỉ đạt **0.853** ở Moderate vì mỗi link giữ `ackGenTime` riêng nên
bắn lệch pha. Dưới broadcast, Causal-v3 bị dominate ở **cả ba** scenario, với biên chi phí
50.03 % ở Stressed.

Đây đúng là rủi ro mà `docs/RESEARCH_REVIEW.md` §A14 nêu từ phiên rà soát đầu tiên: mô hình
unicast-per-link đang tâng bốc phương pháp đề xuất.

### Kiểm chứng accounting

```
ok  broadcast <= unicast ở mọi nơi
ok  broadcast >= unicast / maxFanout (2)
ok  baseline không phát ACK nào
ok  periodic broadcast chính xác: P10 1800, P20 3600 (6 payload class)
```

Con số periodic khớp dạng đóng `ticks × payload classes`, là bằng chứng mạnh nhất rằng counter
đúng.

### Ý nghĩa

EXP07C **không** phủ nhận EXP07A/07B. Nó xác định rằng luận điểm chỉ đứng vững ở **Moderate**
(non-dominated 4/5 variant). Ở **Stressed** — nơi bài báo muốn tuyên bố mạnh nhất — nó không
đứng vững khi tính đủ chi phí ACK.

Không đề xuất thay đổi nào. v4 / piggyback / aggregation chưa được thiết kế.

---

## 8septies. EXP08A — kết quả final 20 seeds

Protocol Causal-AoI-v3 đông cứng. Chỉ thêm topology generator và helper đo λ₂.

```
[PASS] Pre-check: 12/12 graph connected
[PASS] Causality invariants = 0
[FAIL] SafeFail <= 5 % ở nơi P20 cũng safe    1 / 23 điều kiện
[PASS] Stressed advantage >= 80 %             100.0 % (12/12)
[PASS] Leave-one-topology-out >= 80 %         worst 100.0 %
```

Kết quả 20 seeds **trùng khớp hoàn toàn** với 3 seeds. Không cell nào lật.

### Kết quả tích cực: cái ring KHÔNG gánh kết luận

Causal-v3 thắng P10 về RMSE **hoặc** thắng P20 về chi phí ở **toàn bộ 12/12** điều kiện
connected ở Stressed. Bỏ bất kỳ topology nào ra vẫn còn **100 %**.

Đây là bác bỏ trực tiếp mối lo A3 trong `docs/RESEARCH_REVIEW.md`: kết luận không phụ thuộc
vào topology degree-2 mà phương pháp được phát triển trên đó. Bốn topology có mean degree từ
2.60 tới 6.84 và λ₂ từ 0.450 tới 4.382.

### Gate an toàn thất bại: Stressed / sparse6 / N=20

| Method | RMSE | sd | minSep | sd | SafeFail |
|---|---|---|---|---|---|
| P10 | 0.4317 | 0.0012 | **0.1664** | 0.0038 | 1.00 |
| P20 | 0.3329 | 0.0005 | 0.2667 | 0.0017 | 0.00 |
| State-event | 0.7450 | 0.0058 | **0.0302** | 0.0101 | 1.00 |
| **Causal-v3** | 0.3541 | 0.0011 | **0.2446** | 0.0026 | 1.00 |

Causal-v3 hụt ngưỡng 0.25 khoảng **2 %**, và là phương án **tốt thứ hai**; P10 và State-event
hỏng nặng hơn nhiều. Nhưng **0/20 seed** vượt ngưỡng, sd chỉ 0.0026 — đây là thất bại **hệ
thống**, không phải xui xẻo thống kê. Không được diễn giải theo hướng "sát ngưỡng nên bỏ qua".

### Nguyên nhân là CONTROLLER, không phải communication policy

P10 truyền cố định 10 Hz nên communication **giống hệt nhau** trên mọi topology. RMSE của nó
vẫn tăng đơn điệu theo mean degree:

| Stressed | ring2 | sparse4 | sparse6 | geometric |
|---|---|---|---|---|
| N=10 (deg 2.60/4.60/6.20/2.80) | 0.2290 | 0.2603 | 0.2769 | 0.1535 |
| N=20 (2.80/4.80/6.60/3.50) | 0.2681 | 0.3824 | 0.4317 | 0.2562 |
| N=50 (2.92/4.92/6.84/4.12) | 0.2886 | 0.4550 | **0.5540** | 0.3738 |

`swarm/distributedFormationPolicy.m` cộng các số hạng consensus trên các neighbour **mà không
chuẩn hoá theo degree**, nên với **consensus in-degree** `d_i = nnz(A(i,:))` — trên `sparse6`
đúng bằng **6** — loop gain gấp **3.0 lần** mức mà
`Kp = 1.8, Kv = 2.2` được tune cho degree 2. Mọi method đều suy giảm; chỉ P20 (tần suất cập
nhật cao nhất) giữ được khoảng cách an toàn.

**Đính chính:** bản ghi đầu tiên viết "degree ~7, gấp 3.4 lần", lấy nhầm **structural degree**
6.84 (đã đối xứng hoá và gộp cạnh leader-pin). Đại lượng nhân vào gain là **consensus
in-degree**, trên `sparse6` đúng bằng **6**, cho hệ số **3.0 lần**. Sai sót trong comment,
không ảnh hưởng số liệu hay gate; không chạy lại.

**Đây là giới hạn thiết kế controller do EXP08A phơi bày, không phải phát hiện về
communication.** Không tune. Nếu muốn gate an toàn này nói được điều gì về communication thì
phải tách khỏi hiệu ứng degree-gain — nhưng đó là quyết định pre-registration mới.

### Thay đổi cấu hình cần ghi nhận

`A(1,:) = 0`: leader nhận các in-link mà nó không bao giờ đọc (vấn đề B4). Ở EXP06A đó là 17 %
lãng phí cố định nên vô hại; ở đây tỉ lệ lãng phí **khác nhau giữa các topology có degree khác
nhau** và sẽ bóp méo đúng phép so sánh chi phí mà gate advantage dựa vào.

→ **Số liệu EXP08A không so trực tiếp được với EXP06A/EXP07.**

---

## 8octies. EXP08A-D — chẩn đoán degree normalization (pre-register trước khi chạy)

### Vị thế của EXP08A

EXP08A được khoá tại `dce0170`, tag `exp08a-locked-partial`, là **partial result**:

- **Chấp nhận:** relative advantage 12/12 ở Stressed, leave-one-topology-out 100 %.
- **Bác bỏ:** claim về safety generalization — một điều kiện so sánh được thất bại một cách
  hệ thống (Stressed / sparse6 / N=20, **0/20 seed** vượt ngưỡng).

Cách phát biểu bắt buộc trong bài báo: thất bại an toàn được mô tả là
**"consistent with degree-dependent unnormalized consensus gain"** — **KHÔNG** được mô tả là
đã chứng minh nguyên nhân do controller. Bằng chứng hiện tại là tương quan đơn điệu qua P10,
không phải can thiệp có đối chứng.

EXP08A-D tồn tại để biến tương quan đó thành can thiệp. **Nó không được phép thay đổi hồi tố
bất kỳ gate nào của EXP08A.**

### Can thiệp

Chuẩn hoá **chỉ ở controller**: nhân tổng consensus vị trí và vận tốc của các neighbour với

```
2 / d_i        d_i = số neighbour mà follower i tiêu thụ = nnz(A(i,:))
```

- Ở `d_i = 2` — degree mà `Kp = 1.8, Kv = 2.2` được tune trên đó — hệ số bằng **đúng 1**, nên
  hành vi trên ring không đổi. Đây là lý do chọn `2/d_i` thay vì `1/d_i`.
- Ở `d_i = 6`, hệ số bằng 1/3.

**Số hạng leader pinning (`KpLeader`, `KvLeader`, feed-forward `leaderAcc`) KHÔNG đổi.**

Cả hai controller được giữ lại. Cài bằng flag additive `cfg.swarm.normalizeConsensusDegree`,
mặc định `false`, kèm regression chứng minh EXP07/EXP08A tái tạo nguyên vẹn khi tắt.

### Thống kê in-degree phải tách khỏi λ₂ / degree cấu trúc

`graphConnectivity` báo degree **cấu trúc** trên đồ thị đã đối xứng hoá và **đã gộp cạnh leader
pin**. Đó không phải đại lượng mà controller nhìn thấy.

Từ EXP08A-D trở đi phải báo cáo **riêng**:

- **structural**: `numEdges`, `meanDegree`, `minDegree`, `λ₂` — thuộc tính đồ thị
- **consensus in-degree**: `d_i = nnz(A(i,:))` chỉ trên follower `i ≥ 2`, báo mean/min/max —
  đại lượng thực sự nhân vào gain

Ví dụ tại ring2 N=10: structural meanDegree = 2.60 (có pin), nhưng consensus in-degree = 2.00
đúng bằng nhau ở mọi follower. Trộn hai thứ này lại sẽ làm sai lệch chính hệ số chuẩn hoá đang
được kiểm tra.

### Điều cần quan sát

1. Dưới controller đã chuẩn hoá, RMSE của **P10** có còn tăng đơn điệu theo consensus in-degree
   không? P10 truyền cố định 10 Hz nên communication giống hệt trên mọi topology; nếu xu hướng
   biến mất thì degree gain là nguyên nhân, nếu vẫn còn thì không phải.
2. Điều kiện Stressed / sparse6 / N=20 có còn vi phạm an toàn không?

### Phạm vi

Chỉ **3 seeds**, dừng để review. Đây là **chẩn đoán**, không phải experiment có gate.
Nó không sinh ra claim mới cho bài báo, và không sửa Causal-AoI-v3.

---

## 8nonies. EXP08A-D — verdict: LOCKED DIAGNOSTIC (tag `exp08ad-locked-diagnostic`)

Can thiệp có đối chứng **đủ** để quy phần lớn suy giảm ở degree cao của EXP08A cho
**degree-dependent amplification của các số hạng neighbour-consensus không chuẩn hoá**.

**Không** thay đổi hồi tố EXP08A; EXP08A vẫn khoá ở `exp08a-locked-partial`.

### `2/d_i` là REFERENCE-DEGREE normalization, KHÔNG phải giải pháp phổ quát

Phải mô tả đúng như vậy trong bài báo. Hệ số lấy `d = 2` làm degree tham chiếu:

| | hiệu ứng |
|---|---|
| `d_i > 2` | giảm gain, có lợi — sparse6 N=50: **−47.5 %** |
| `d_i = 2` | không đổi gì — ring2: **0.0 %** ở mọi size |
| `d_i < 2` | **tăng gain, có hại** |

**Phản ví dụ phải giữ lại:** `geometric N=10` **xấu đi +8.3 %** (0.1536 → 0.1664). Đồ thị này
có consensus in-degree **min = 1**, và tại `d_i = 1` hệ số `2/1 = 2` **nhân đôi** gain. Không
được lược bỏ ca này, vì nó xác định đúng phạm vi áp dụng của hệ số.

---

## 9. Nhật ký thay đổi tài liệu này

Mọi thay đổi sau khi tag `prereg-exp07-exp10` phải được ghi ở đây, kèm lý do và commit hash.
Một pre-registration bị sửa mà không ghi nhật ký là một pre-registration vô giá trị.

| Ngày | Mục thay đổi | Lý do | Commit |
|---|---|---|---|
| 2026-08-21 | — | Bản chốt đầu tiên | (tag `prereg-exp07-exp10`) |
| 2026-08-22 | §2.3: `E_max` (và peak AoI) đổi mốc từ `thời điểm lỗi bắt đầu` sang `max(thời điểm lỗi bắt đầu, 8 s)` | **Sửa lỗi đo lường, không phải tuning.** Permanent fault bắt đầu tại `t = 0` nên cửa sổ cũ đo transient khởi động: trong cùng seed, `E_max` trùng khít giữa P10/P20/Causal-v3 (2.356607 tại ring2/Moderate/perm 20 %), tức đại lượng không phụ thuộc phương thức, khiến gate pass vô nghĩa ở 16/24 condition. Mốc 8 s là evaluation window đã dùng cho mọi metric khác. Burst (bắt đầu 12 s) **không đổi**. Sửa đổi làm gate **khó hơn**. Không đổi Causal-v3, controller, threshold, fault grid, CRN, fault realization hay tỉ số gate. | (branch `exp08b-link-failure`) |
| 2026-08-22 | §4.2: gate Safety giữ nguyên tuyệt đối ≤ 5 %, nhưng chỉ **đánh giá ở 20 seeds**; ở 3 seeds báo cáo DEFERRED | Ở 3 seeds tỉ lệ khác 0 nhỏ nhất là 1/3, nên "≤ 5 %" thoái hoá thành "= 0" và verdict sẽ đo số seed chứ không đo phương thức. Ở 20 seeds: 0/20 và 1/20 PASS, ≥ 2/20 FAIL — đúng ngưỡng 5 % đã chốt. **Không** thêm điều kiện phụ "P20 cũng safe". | (branch `exp08b-link-failure`) |
| 2026-08-22 | §4.3 EXP08C: pre-register đầy đủ **trước khi chạy** — ngữ nghĩa fault communication-layer, matched no-fault eligibility, gate chính 1-node, 2-node là secondary/characterization, connectivity trên đồ thị con của các node còn phát, danh sách metric bắt buộc | Bản chốt đầu chỉ có 4 dòng gate và để ngỏ ba chỗ có thể diễn giải lại sau khi nhìn số: (1) mẫu số của SafeFail — nay chốt là **matched no-fault eligible seeds**, để không tính vào blackout những cấu hình vốn đã unsafe; (2) vai trò của 2-node — nay chốt là **secondary**, không được dùng để đổi main claim; (3) λ₂ khi node tắt — node tắt luôn làm λ₂ = 0 nếu đưa vào đồ thị, khiến mọi condition bị loại, nên phân loại chuyển sang **đồ thị con cảm sinh bởi các node còn phát sóng**, tiêu chuẩn §2.4 giữ nguyên. Ghi trước khi tồn tại bất kỳ kết quả EXP08C nào. | (branch `exp08c-node-blackout`) |
| 2026-08-22 | §4.2: nói rõ mẫu số gate Safety là **số seed connected của từng condition** (`unsafe connected / connected ≤ 5 %`) | **Làm rõ, không đổi gate.** Code đã tính đúng như vậy từ đầu (trung bình `SAFEFAIL` chỉ trên seed connected), nhưng cả §4.2 lẫn comment đều không nói ra, nên câu "0/20 và 1/20 PASS" dễ bị đọc thành "luôn được phép một seed hỏng". Câu đó chỉ đúng khi **cả 20 seed đều connected**; với 19 seed connected thì `1/19 = 5.26 %` **FAIL**. Thứ bị chặn ở 5 % là tỉ lệ, không phải số đếm. Bắt buộc in `nConnected`/`nDisconnected` cho mọi condition. | (branch `exp08b-link-failure`) |
| 2026-08-22 | §2.4 áp dụng: phân loại connectivity tính **trên realization thực sự được mô phỏng** (theo từng seed), thay vì một seed đại diện | **Sửa lỗi đo lường.** Bản chạy đầu phân loại bằng `cfg.net.seed = 1800000`, không phải seed nào trong tập chạy, và kết luận "connected, isolated = 0" cho mọi condition. Realization thật lại có λ₂ = 0 (ring2 / perm 30 % và cả hai burst / Moderate / seed 1) và tới 3 isolated follower. Exclusion vì thế đã áp cho sai đồ thị. **Tiêu chuẩn phân loại không đổi** (§2.4, đồ thị đối xứng hoá, λ₂ > 1e-9); chỉ đối tượng được phân loại là đúng lại. Loại trừ nay theo từng seed; condition không còn seed connected nào thì loại toàn bộ. | (branch `exp08b-link-failure`) |
| 2026-08-22 | §4.2: thêm chẩn đoán thụ động `minSepDuringFault`, DATA/s trong cửa sổ lỗi, và SafeFail theo từng method | §4.2 vốn đã yêu cầu "min separation during failure" và "traffic response"; bản chạy đầu chưa đo đúng cửa sổ. Cả ba đều **chỉ báo cáo, không gate**. Thêm log truyền tin tích luỹ thụ động vào ba simulator (ghi nhưng không bao giờ đọc trong sim); `test_lock_regression` chứng minh mọi giá trị LOCK tái tạo nguyên vẹn. | (branch `exp08b-link-failure`) |
| 2026-08-21 | Đính chính comment: "degree 7 → 3.4 lần" nhầm structural degree 6.84 thành consensus in-degree; đúng là 6 → 3.0 lần | Structural degree đã đối xứng hoá và gộp cạnh leader-pin, không phải đại lượng nhân vào gain. Sai sót comment, không ảnh hưởng số liệu hay gate. Không chạy lại. | (branch `exp08b-link-failure`) |
| 2026-08-21 | Thêm §8ter: pre-register Causal-AoI-v3 (innovation-priority) + ablation A5c + invariant mới | v2 bị đóng băng ở 7/9 vì `aoiMinInterTx` vô tình trở thành trần cho thông tin mới. v3 **không đổi giá trị** tham số nào; nó chỉ tách ngữ nghĩa "thông tin mới" khỏi "refresh", và cooldown chỉ áp cho refresh. Chín gate giữ nguyên. Pre-register trước khi chạy. | (branch `exp07a-causal-v3`) |
| 2026-08-21 | §3.1 trần 20 Hz: **giữ nguyên**, chỉ đính chính phần lý do | Lý do ban đầu ("trên 20 Hz thì P20 dominate hoàn toàn") đã bị dữ liệu v1 **bác bỏ**: ở 26.19 Hz, Causal-AoI-v1 có RMSE 0.1049 tốt hơn P20 (0.1102), nên P20 không dominate. **Ngưỡng KHÔNG đổi.** Nó vẫn đứng vững với vai trò ràng buộc tài nguyên chống brute-force: nếu không có trần, một phiên bản chỉ cần truyền thật nhiều là pass mọi gate còn lại. Gate v1 không bị sửa hồi tố; commit a554163 giữ nguyên là thất bại 8/9 hợp lệ. | (branch `exp07a-causal-ack`) |
| 2026-08-21 | §2.7 mức `reliable`: ACK delay đổi từ "tối thiểu (1 timestep)" sang "= delay DATA của scenario" | Bản chốt đầu tiên **không pin** ACK delay cho EXP07A; §2.7 chỉ định nghĩa thang cho EXP07B. Đây là lấp một chỗ chưa xác định, không phải đổi một ngưỡng đã chốt. Kênh ngược dùng cùng môi trường vật lý nên độ trễ đối xứng là giả định trung thực hơn. **Thay đổi này làm gate KHÓ hơn, không dễ hơn**: RTT ở Stressed tăng từ 140 ms lên 240 ms, khiến ước lượng AoI của sender cũ hơn, method truyền nhiều hơn, nên cả trần 20 Hz lẫn gate `RMSE < P10` đều khó đạt hơn. Ghi nhận trước khi tồn tại bất kỳ kết quả nào. | (branch `exp07a-causal-ack`) |
