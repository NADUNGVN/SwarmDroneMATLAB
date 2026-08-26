# EXP10 PLAN — 50-seed final validation, unified matrix, freeze

**Trạng thái: PREREG DRAFT. Chưa authorize, chưa chạy.**

Tài liệu này chốt **các điểm được chọn** cho vòng validation cuối trước khi nhìn thêm bất kỳ số
nào. Không có tham số nào được tune, không có v4 protocol, không có controller retuning.

Bối cảnh: chuỗi EXP07–EXP09 đã kết thúc với **một hỗn hợp kết quả dương, một phần và âm**.
EXP10 không được phép biến hỗn hợp đó thành một câu chuyện toàn thắng bằng cách chỉ chọn những ô
thuận lợi.

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
| EXP09C | *(pending)* | xem §4 |

**Bốn phát biểu đã bị bác hoặc giới hạn, và EXP10 phải giữ nguyên chúng:**

1. Stressed ACK-inclusive Pareto superiority — **đã bác (EXP07C)**. EXP10A **không** được đặt lại
   claim này.
2. Safety generalization qua topology — **partial (EXP08A)**.
3. Safety dưới link/node fault — **fail, nhưng dùng chung mọi method (EXP08B/C)**.
4. Robustness với plant mismatch — **fail vì controller thiếu integral action (EXP09B)**, không
   phải vì communication.

---

## 1. EXP10A — Paired CRN + confidence intervals, 50 seeds

### 1.1 Điểm bắt buộc

**Nominal (bắt buộc đủ):**
```
N = 5, 6-DOF, ring2
scenario : Moderate, Stressed
method   : P10, P20, State-event, Causal-v3
```

**Một điểm fault/robustness đã chọn từ MỖI nhóm** (chọn trước, ghi ở đây):

| Nhóm | Điểm được chọn | Nguồn |
|---|---|---|
| ACK impairment | `moderate`: ACK loss 10 %, ACK delay = delay DATA | §2.7 / EXP07B |
| Topology / link fault | ring2 N=20, **permanent 20 %** | EXP08B |
| Node blackout | N=20 ring2, **1-node 5 s** | EXP08C |
| Physical mismatch | **B7 combined medium** | EXP09B |
| Synthetic estimator | **C3 combined medium** | EXP09C |

Mỗi điểm chạy đủ 4 method × {Moderate, Stressed} × 50 seeds.

Lý do chọn: mỗi điểm là **điểm đã lộ ra một giới hạn** trong experiment gốc của nó, không phải
điểm đẹp nhất. `permanent 20 %` và `1-node 5 s` là nơi safety gate đã fail; `B7` là nơi G2 fail;
`C3` là nơi G3 fail. Chọn điểm dễ sẽ khiến EXP10A xác nhận một thứ chưa từng bị nghi ngờ.

### 1.2 Thống kê paired — chốt trước

CRN cho phép ghép cặp: cùng seed ⇒ cùng realization kênh, cùng fault, cùng nhiễu. Vì vậy dùng
**paired difference**, không phải two-sample.

Với mỗi cặp method (A, B), mỗi scenario, mỗi điểm:

```
d_s   = metric_A(seed s) - metric_B(seed s),   s = 1..50
dbar  = mean(d_s)
CI95  = dbar ± t(0.975, 49) * std(d_s) / sqrt(50)
```

**Báo cáo `dbar` và CI95 cho mọi claim.** Nếu **CI cắt 0** thì claim bị **hạ cấp** và phải ghi rõ
là không phân biệt được ở mức 50 seeds — đây là quy tắc đã chốt từ §8 của roadmap gốc và không
được nới.

### 1.3 Key claims — chốt trước, đúng hai cái

```
K1  Stressed  RMSE(Causal - P10)        <  0
K2  Stressed  communication(Causal - P20)   [DATA count, báo cáo dbar + CI]
```

`K1` là claim hiệu năng. `K2` là claim chi phí và được báo cáo **có dấu**, không đặt sẵn hướng:
Causal-v3 ở Stressed truyền **nhiều hơn** P20 hay ít hơn là một dữ kiện, không phải một mục tiêu.

**KHÔNG yêu cầu Stressed Pareto superiority.** EXP07C đã bác nó và kết quả âm đó được giữ nguyên.

### 1.4 Gate EXP10A

```
Trace hash khớp 100 % giữa các method, cùng seed
0 missing, 0 NaN ngoài các run DIVERGED đã gán nhãn
Mọi key claim báo cáo dbar + CI95
CI cắt 0  =>  hạ cấp claim và ghi rõ, KHÔNG chạy thêm seed để đẩy nó qua
```

Dòng cuối là điều kiện chống p-hacking: thêm seed cho tới khi CI hết cắt 0 là chọn cỡ mẫu theo
kết quả.

---

## 2. EXP10B — Unified final matrix

Chạy **toàn bộ** các điểm ở §1.1 trong một bảng duy nhất, và **giữ nguyên kết quả âm**.

**Quy tắc bắt buộc:**

- Bảng phải chứa **mọi** ô đã chạy, kể cả ô mà Causal-v3 thua. Không được lọc.
- Mỗi kết quả âm hoặc partial ở §0 phải xuất hiện **nguyên văn** trong bảng cuối, kèm tag gốc.
- Với mỗi ô, ghi **method thắng** theo RMSE và theo cost. Nếu Causal-v3 không thắng, ghi ai thắng.
- Pareto dùng định nghĩa §2.5 (biên 1 %, cost model giữa ACK/DATA = 0.25). Báo cáo cả ba cost
  model như EXP07C.

**Phát biểu cuối được phép rút ra** chỉ có dạng: *Causal-AoI-v3 thích nghi được với chất lượng
mạng bằng một cấu hình duy nhất, tốt hơn State-event ở mọi điều kiện đã thử, và cạnh tranh với
periodic ở Moderate; nó không vượt trội về Pareto ở Stressed, và nó không sửa được các giới hạn
thuộc về controller hay hình học đội hình.*

---

## 3. EXP10C — Reproducibility + freeze

```
1. test_rotation, test_formation_error, test_setpoint_interface,
   test_causal_invariants, test_lock_regression, test_blackout_semantics,
   test_mismatch_semantics, test_estimator_semantics  -- toàn bộ PASS
2. Chạy lại từ clean clone: mọi giá trị LOCK tái tạo bit-identical
3. results/INDEX.md đầy đủ, mỗi run có console.log + tidy.csv + meta.json + source snapshot
4. docs/PREREGISTRATION.md §9 changelog đầy đủ, không có amendment nào thiếu lý do
5. Tag  simulation-v1.0
```

Freeze kết thúc ở `simulation-v1.0`.

---

## 4. Phụ thuộc còn mở

- EXP09C 20-seed final phải xong và được tag trước khi EXP10A bắt đầu; điểm C3 ở §1.1 lấy từ đó.
- Nếu EXP09C đổi điểm nào trong §1.1, phải ghi amendment vào §9 **trước** khi chạy EXP10A.

## 5. Những gì EXP10 **không** làm

- Không thiết kế v4 protocol.
- Không retune controller, threshold, cost model hay Pareto definition.
- Không cứu một gate âm bằng cách đổi điều kiện đo.
- Không thêm seed sau khi nhìn CI.
