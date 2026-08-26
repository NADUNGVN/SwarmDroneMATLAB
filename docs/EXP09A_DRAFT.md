# EXP09A — Networked multi-UAV 6-DOF — DRAFT

**Trạng thái: DRAFT, chưa authorize, chưa chạy.** Tài liệu này phải được bạn duyệt và
tag trước khi tồn tại bất kỳ kết quả EXP09A nào. Không có tham số controller hay network
nào được tune trong draft này.

Mục đích của EXP09A: kiểm tra communication claim có sống sót khi thay double integrator
bằng động lực học 6-DOF thật. Nếu claim chỉ tồn tại trên double-integrator thì **phải điều
tra**, không được bỏ qua — đây là major gate của roadmap.

---

## 1. Kiến trúc

```
formation policy  (đã khoá)
      │  accCmd_i(t_k)          outer, 50 Hz
      ▼
setpoint interface (ZOH trên gia tốc, pos/vel là tích phân giải tích)
      │  ref.pos / ref.vel / ref.acc / ref.yaw
      ▼
quadCascadedController            inner, 500 Hz, stateless
      │  u.thrust / u.torque
      ▼
quad6dofDynamics + RK4            inner, 500 Hz
```

Ba thành phần bên phải **đã tồn tại và không sửa**: `controllers/quadCascadedController.m`
(không có internal state, đã kiểm chứng), `models/quadrotor/quad6dofDynamics.m`,
`tests/test_rotation.m`.

### 1.1 Timing hierarchy

| Tầng | Bước | Tần số | Nội dung |
|---|---|---|---|
| Outer | `dt = 0.02` | 50 Hz | mạng, AoI, trigger, formation policy → `accCmd` |
| Inner | `dtIn = 0.002` | 500 Hz | controller + 6-DOF + RK4 |

Tỉ lệ đúng **10 : 1**, không có phần dư. **Toàn bộ timing của network policy giữ nguyên**:
`commPeriod`, `minInterTx`, `aoiMinInterTx`, `maxSilence`, delay, jitter đều tính trên đồng hồ
outer y hệt hiện nay. 6-DOF **không** được phép làm đổi nhịp truyền tin, nếu không thì so sánh
với double-integrator sẽ lẫn hai biến.

### 1.2 Setpoint interface — điểm dễ sai nhất

Thứ được ZOH là **gia tốc lệnh**, không phải vị trí. Trong khoảng `τ ∈ [0, dt)` sau mốc outer
`t_k`:

```
ref.acc = accCmd_i(t_k)                                  (giữ nguyên suốt khoảng)
ref.vel = v_i(t_k) + accCmd_i(t_k) · τ
ref.pos = p_i(t_k) + v_i(t_k) · τ + 0.5 · accCmd_i(t_k) · τ²
ref.yaw = 0
```

`ref.pos/ref.vel` là **tích phân giải tích của chính lệnh đó**, tức đúng quỹ đạo mà mô hình
double-integrator sẽ đi trong khoảng ấy.

**Tại sao không giữ nguyên `ref.pos = p_i(t_k)` suốt khoảng.** Nếu đóng băng vị trí tham chiếu,
drone bay ra khỏi nó trong 10 bước inner, `ep = ref.pos − p` trở thành âm của chính độ dịch
chuyển, và `KpPos·ep` sẽ **kéo ngược lại** chống đúng gia tốc vừa được lệnh. Vòng ngoài của quad
khi đó biến thành một bộ điều tiết thứ hai đấu với formation policy, và chênh lệch đo được so với
double-integrator sẽ là chênh lệch của một lỗi giao diện, không phải của động lực học 6-DOF.

Với định nghĩa ở trên, nếu bám hoàn hảo thì `ep = ev = 0` và vòng ngoài của quad **không thêm
một tầng position loop thứ hai**. Chênh lệch còn lại cô lập đúng phần *động học attitude + bão
hoà actuator*, không lẫn tuning mới.

### 1.3 RK4 / ZOH semantics

Trong mỗi bước inner:

1. Tính `ref` tại **thời điểm đầu bước** `t_k + m·dtIn`.
2. Gọi `u = quadCascadedController(x, ref, cfg)` **một lần**.
3. RK4 tích phân `quad6dofDynamics` với `u` **giữ nguyên** qua cả bốn stage.

`u` là ZOH trên bước inner vì controller thật chỉ chạy ở nhịp lấy mẫu của nó. **Không** đánh giá
lại `ref` hay `u` tại các stage giữa của RK4: làm vậy sẽ mô phỏng một controller liên tục không
tồn tại, và sẽ cho kết quả *đẹp hơn thực tế*.

### 1.4 Leader

Leader giữ nguyên là **tham chiếu động học** (`leaderReference`), không phải 6-DOF, trong main
grid. Nếu leader cũng là 6-DOF thì bản thân tham chiếu đã mang sai số bám, và chênh lệch so với
double-integrator sẽ trộn hai nguồn. Đây là **lựa chọn mô hình có ý thức, phải ghi vào paper**,
không phải bỏ sót. Biến thể leader-6DOF có thể là EXP09A-L về sau nếu cần.

---

## 2. Grid

```
N          = 5   (bắt buộc);  N = 10 nếu runtime hợp lý
scenario   = Clean, Moderate, Stressed
method     = P10, P20, State-event, Causal-v3
seeds      = 3 debug  →  20 final
```

Tham số communication **giữ nguyên bản đã khoá**: `epsP = 0.05`, `epsV = 0.10`,
`aoiThreshold = 0.12`, `aoiMinInterTx = 0.10`, `maxSilence = 0.50`, `scaleBase = 0.50`,
`scaleMin = 0.20`, `adaptRange = 1.00`, `minInterTx = dt`. CRN bật, `phaseOffset` tắt.

Ước lượng chi phí: `K_outer = 1500` × 10 inner × 4 RK4 stage × 4 follower ≈ 240 k lần đánh giá
dynamics mỗi run; 3 scenario × 4 method × 20 seeds = 240 run. Với parfor, dự kiến vài phút.
N = 10 nhân đôi, vẫn trong tầm.

---

## 3. Metric — định nghĩa chốt trước

| Metric | Định nghĩa |
|---|---|
| `formationRMSE` | y hệt double-integrator: sai số vị trí so với offset mong muốn quanh leader, cửa sổ `t ≥ 8 s` |
| `positionRMSE` | RMS `‖p_i − p_leader − offset_i‖` trên mọi follower, cùng cửa sổ |
| `rollPeak`, `pitchPeak` | `max |φ|`, `max |θ|` trên `t ≥ 8 s`, đơn vị độ |
| `thrustSat` | tỉ lệ bước inner có `thrust ≤ 1e-6` **hoặc** `thrust ≥ maxThrust − 1e-6` |
| `torqueSat` | tỉ lệ bước inner có bất kỳ thành phần nào chạm `±maxTorque` trong `1e-6` |
| `saturation` | `max(thrustSat, torqueSat)` — đại lượng dùng cho gate |
| `controlEffort` | `mean(thrust²)/(m·g)² + mean(‖torque‖²)/‖maxTorque‖²` trên `t ≥ 8 s` |
| `minSeparationEval` | không đổi |
| `SafeFail` | `minSeparationEval < 0.25 m`, không đổi |
| AoI / communication | `meanAoI`, `peakAoI`, `txCount`, rate — không đổi |

**Divergence / NaN check.** Một run bị đánh dấu `DIVERGED` nếu bất kỳ điều nào sau đây xảy ra:

```
any NaN trong p, v, eul, omega
‖p_i − p_leader‖ > 50 m
|φ| > 80°  hoặc  |θ| > 80°
```

Run `DIVERGED` **không** được đưa vào trung bình của bất kỳ metric nào; nó được đếm riêng và báo
cáo. Trung bình hoá một run đã phân kỳ sẽ biến một thất bại thành một con số lớn nhưng hữu hạn,
và điều đó che mất chính thứ gate Stability cần bắt.

---

## 4. Gate đề xuất

```
Stability        : 0 run DIVERGED, 0 NaN, trên mọi cell
Clean            : SafeFail = 0
Moderate         : SafeFail = 0
Stressed         : SafeFail ≤ 5 %
Saturation       : nominal (Clean)  saturation < 1 %
                   Stressed         saturation < 5 %
Advantage        : RMSE(Causal-v3) < RMSE(State-event) ở cả 3 scenario
Consistency      : ranking so với P10/P20 không bị đảo hoàn toàn (§2.6)
```

`§2.6` giữ nguyên định nghĩa đã chốt: đặt `r = sign(RMSE_Causal − RMSE_P10)` và
`s = sign(RMSE_Causal − RMSE_P20)`; so `r`, `s` của 6-DOF với chính chúng ở double-integrator,
cùng scenario. Gate: `r` khớp ở ≥ 2/3 scenario **và** `s` khớp ở ≥ 2/3 scenario. Đảo cả `r` lẫn
`s` ở cả 3 scenario = FAIL.

**Số tham chiếu double-integrator** để so `r`, `s` phải lấy từ **cùng một run EXP09A**, chạy
song song ở chế độ double-integrator với đúng seed set — không lấy số lưu từ experiment khác.
Đây là quy tắc chung đã chốt ở §1 và nó đặc biệt quan trọng ở đây, vì `r`/`s` là dấu của một
hiệu số nhỏ và rất nhạy với việc đổi seed.

**Khả năng đánh giá.** Gate `SafeFail ≤ 5 %` chỉ đánh giá ở 20 seeds, theo đúng quy tắc đã áp
cho EXP08B/§4.2: mẫu số là số seed hợp lệ (không DIVERGED) của chính cell đó, và ở 3 seeds gate
được báo cáo **DEFERRED**.

---

## 5. Kế hoạch implementation

**File mới:**

| File | Vai trò |
|---|---|
| `simulation/simSwarm6DOF.m` | vòng outer/inner, gọi lại nguyên vẹn network + policy hiện có |
| `swarm/setpointFromAccel.m` | giao diện §1.2, thuần hàm, dễ test riêng |
| `metrics/compute6DOFMetrics.m` | attitude peak, saturation, control effort, divergence flag |
| `experiments/exp09a_multiuav_6dof.m` | grid + gate |
| `tests/test_setpoint_interface.m` | §1.2 và §1.3 |

**Dùng lại nguyên vẹn, không sửa:** toàn bộ `network/`, `aoiAwareTriggerPolicy`,
`causalInnovationTriggerPolicy`, `distributedFormationPolicy`, `quadCascadedController`,
`quad6dofDynamics`, `computeSwarmMetrics`, `utils/`.

**Không chạm:** mọi simulator và experiment đã LOCK.

`simSwarm6DOF` được viết bằng cách **sao chép cấu trúc vòng ngoài của `simSwarmAoICausal`**
và chỉ thay khối tích phân follower: thay vì
`V += dt*accCmd; P += dt*V`, chạy 10 bước inner qua controller + RK4. Mọi thứ khác — thứ tự
STEP, xử lý ACK đầu bước, trigger, hàng đợi — giữ nguyên vị trí, để `simSwarm6DOF` với
`cfg.sixdof.enable = false` phải cho kết quả **bit-identical** với `simSwarmAoICausal`.

### 5.1 Kiểm chứng bắt buộc trước khi tin bất kỳ số nào

1. `test_setpoint_interface`: với `accCmd` hằng và không nhiễu, quỹ đạo 6-DOF bám quỹ đạo
   double-integrator trong sai số nhỏ; và `ep`, `ev` tại mốc outer phải ≈ 0. Nếu `ep` tăng dần
   theo `τ` thì giao diện đã đóng băng nhầm vị trí (§1.2).
2. `simSwarm6DOF` ở chế độ double-integrator tái tạo **bit-identical** `simSwarmAoICausal`.
   Nếu không, khác biệt nằm ở vòng ngoài chứ không phải ở 6-DOF.
3. `test_lock_regression` và `test_causal_invariants` vẫn PASS.
4. Ở Clean với mạng lý tưởng, `formationRMSE` của 6-DOF phải hội tụ về gần giá trị
   double-integrator. **Lệch lớn ở Clean là lỗi giao diện, không phải phát hiện khoa học.**
5. `txCount` và rate ở 6-DOF phải khớp double-integrator trong sai số nhỏ ở cùng seed — nếu lệch
   nhiều thì 6-DOF đã làm đổi nhịp trigger, tức §1.1 bị vi phạm.

---

## 6. Những gì draft này **không** làm

- Không tune `cfg.ctrl.*`, `cfg.quad.*`, hay bất kỳ tham số communication nào.
- Không đổi gate của EXP07/EXP08.
- Không chạy EXP09A.
- Không quyết định N = 10 có nằm trong scope hay không; điều đó phụ thuộc runtime đo được ở
  N = 5.
