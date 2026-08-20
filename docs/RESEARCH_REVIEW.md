# Rà soát nghiên cứu — SwarmDroneMATLAB

*Ngày rà soát: 2026-08-20. Toàn bộ nội dung dưới đây dựa trên việc đọc mã nguồn và chạy lại
thực nghiệm, không dựa trên tài liệu cũ.*

---

## 0. Tóm tắt điều hành

Bốn điều quan trọng nhất, xếp theo mức ảnh hưởng tới bài báo:

**1. Câu chuyện khoa học ĐÚNG, nhưng chỉ đúng theo một cách phát biểu cụ thể.**
Thực nghiệm mới `EXP05D` (quét toàn bộ frontier của cả ba họ policy) cho thấy:

- Nếu cho phép **tune lại theo từng điều kiện mạng**, một lịch periodic cố định chọn khéo
  **thắng** Full-AoI ở phần lớn dải hoạt động dưới Moderate/Stressed.
- Nếu bắt buộc dùng **một cấu hình duy nhất cho mọi điều kiện mạng** — đúng cách phương pháp
  được thiết kế để dùng — Full-AoI **thắng ở 4/4 điểm so sánh được** với periodic **và** 4/4
  với conventional event-trigger.

Nghĩa là luận điểm phải được phát biểu là *adaptivity*, không phải *efficiency thuần tuý*.
Chi tiết ở §1.

**2. Cơ chế đã được chứng minh trực tiếp.** Giữ nguyên cấu hình, khi mạng xấu đi từ Clean sang
Stressed: periodic giữ tỉ lệ 1.00 (hiển nhiên), conventional event-trigger **0.96–0.99** (thực
tế truyền *ít đi*), Full-AoI **1.57–2.78** (tăng 1.6–2.8 lần). Đây là bằng chứng sạch nhất cho
cơ chế và nên là một hình chính trong bài báo.

**3. Bug ACK feedback: đã đo, KHÔNG ảnh hưởng kết quả cũ.** `ackSyncMissCount = 0` trên
1.456.105 lần cập nhật accepted-state trong EXP05D và 193.129 trong EXP05C. Logic có lỗi tiềm
ẩn (§3, A2) nhưng nó chưa bao giờ kích hoạt. Kết quả Full-AoI cũ không bị nhiễm.

**4. Rủi ro lớn nhất còn lại vẫn là kênh ACK lý tưởng hoá** (§2, A1) — miễn phí, tức thời,
không mất gói, và phi nhân quả. Đây là điều reviewer sẽ tấn công trước tiên.

### Kiểm chứng hồi quy

EXP05C tái tạo **chính xác** các con số đã báo cáo trước đây, xác nhận việc vector hoá
`computeSwarmMetrics` và chuyển sang `parfor` không làm thay đổi kết quả:

| | Clean | Moderate | Stressed |
|---|---|---|---|
| A1→A2 (fixed AoI coupling) | +43.93 % | +32.74 % | +32.89 % |
| A2→A3 (adaptive threshold) | +15.04 % | +8.43 % | +9.05 % |
| A3→A4 (accepted-state feedback) | +0.00 % | +5.71 % | +16.07 % |

---

## 1. Kết quả mới: EXP05D — Pareto frontier

`EXP05B` so sánh ba policy tại **một điểm vận hành mỗi loại**. Điều đó không trả lời được câu
hỏi hiển nhiên của reviewer: *nếu tune lại baseline thì nó có đạt tới điểm đó không?*

`EXP05D` quét điểm vận hành của **mọi** policy — periodic theo tần số, hai policy event-trigger
theo `epsP` (với `epsV = 2·epsP`) — trên cả ba scenario, 20 seeds, seed ghép cặp. 1080 mô phỏng.

### 1.1 Mặt phẳng "tune lại theo từng mạng"

Với mỗi điểm Full-AoI, nội suy xem baseline đạt RMSE bao nhiêu **ở cùng tốc độ truyền**.
Margin dương nghĩa là Full-AoI tốt hơn ở cùng chi phí.

| Scenario | Thắng periodic | Thắng state-event |
|---|---|---|
| Clean | 4/6 | 5/6 |
| Moderate | 1/4 | 2/4 |
| Stressed | 1/3 | 2/3 |

**Kết luận thẳng thắn:** dưới Moderate và Stressed, một lịch periodic cố định *được chọn đúng
cho điều kiện mạng đó* thắng Full-AoI ở cùng mức chi phí truyền. Full-AoI chỉ thắng periodic
một cách nhất quán dưới mạng Clean.

Nhưng phép so sánh này ngầm cho baseline một lợi thế không tồn tại trong thực tế: nó giả định
ta **biết trước** điều kiện mạng để chọn đúng tần số.

### 1.2 Mặt phẳng "một cấu hình cho mọi mạng" — phép thử đúng

Đây mới là cách phương pháp được dùng. Chi phí = tốc độ truyền trung bình trên các scenario;
rủi ro = RMSE **xấu nhất** trên các scenario (vì một cấu hình chỉ hữu ích nếu trường hợp xấu
nhất của nó chấp nhận được).

| Mean rate [Hz] | Full-AoI worst RMSE | Margin vs Periodic | Margin vs State-event |
|---|---|---|---|
| 15.93 | 0.1140 | **+0.0061** | **+0.0154** |
| 11.81 | 0.1307 | **+0.0067** | **+0.0168** |
| 8.25 | 0.1489 | **+0.0147** | **+0.0266** |
| 6.51 | 0.1628 | **+0.0263** | **+0.0379** |

**Full-AoI thắng 4/4 điểm so sánh được với periodic và 4/4 với state-event.** Biên độ thắng
tăng dần khi tốc độ truyền giảm — tức lợi thế càng rõ ở chế độ tiết kiệm băng thông.

Kết luận này bền vững: EXP05D được chạy hai lần với hai chuỗi RNG hoàn toàn khác nhau (trước và
sau khi vá lỗi generator ở B14), và cả hai lần đều cho 4/4 với biên độ gần như trùng nhau
(+0.0058/+0.0061/+0.0131/+0.0257 so với +0.0061/+0.0067/+0.0147/+0.0263).

### 1.3 Bằng chứng trực tiếp cho cơ chế

Giữ nguyên cấu hình, tỉ lệ tốc độ truyền Stressed / Clean:

| Policy | Tỉ lệ thích nghi |
|---|---|
| Periodic | 1.00 (theo định nghĩa) |
| Conventional state-event | **0.96 – 0.99** |
| Full AoI-aware | **1.57 – 2.78** |

Conventional event-trigger truyền **ít đi** khi mạng xấu — vì gói rơi nghĩa là receiver không
cập nhật, nhưng transmitter (không có ACK) vẫn tưởng đã truyền thành công và reset reference.
Đó chính xác là failure mode mà bài báo lập luận. Full-AoI đảo ngược hành vi đó.

**Đây là hình thuyết phục nhất bạn có.** Nó cho thấy cơ chế hoạt động đúng như thiết kế, độc
lập với việc so sánh RMSE.

### 1.4 Cách nên phát biểu luận điểm

Không nên viết: *"phương pháp đề xuất đạt formation tốt hơn với ít traffic hơn."*

Nên viết: *"với một bộ tham số duy nhất, phương pháp tự điều chỉnh tải truyền theo chất lượng
mạng (1.6–2.8×), và trên mặt phẳng chi phí-trung-bình / sai-số-xấu-nhất nó dominate cả periodic
cố định lẫn event-trigger thông thường. Một lịch periodic được tune riêng cho từng điều kiện
mạng vẫn có thể tốt hơn, nhưng đòi hỏi biết trước điều kiện mạng."*

Cách phát biểu thứ hai vừa đúng với dữ liệu, vừa mạnh hơn về mặt khoa học, và tự nó đã trả lời
câu hỏi khó nhất của reviewer.

---

## 2. Tầng 1 — Đe doạ luận điểm trung tâm

### A1. Kênh ACK miễn phí, tức thời, không mất gói — và phi nhân quả

`simulation/simSwarmAoIAware.m` → `syncAcceptedStateMemory` (L1359) đọc thẳng
`net.genTime(i,j)` — trạng thái thật của receiver — ngay trong cùng timestep. Không gói tin
ngược, không delay, không loss. `net.txCount` **không bao giờ** tăng cho ACK (chỉ tăng ở
L801/L1025 cho gói dữ liệu). Vòng lặp là
`deliver → sync → trigger → deliver → sync → control` (L247-321): transmitter được đồng bộ
**hai lần mỗi bước**.

Hai vấn đề tách biệt:

- **Chi phí.** Nếu mỗi gói được accept sinh một ACK, link budget thực bị báo thiếu tới **2×**.
  Baseline periodic và event-trigger **không có** kênh ngược nào để phải trả giá.
- **Nhân quả.** Với forward delay 80–120 ms, transmitter không thể biết tại thời điểm `t`
  receiver đang giữ gì. Mà `aoiThreshold = 0.12 s` **cùng bậc độ lớn** với delay → đây là sai
  số bậc nhất, không phải bậc hai. `receiverAoI` trong `network/aoiAwareTriggerPolicy.m` hiện
  là AoI **thật**, không phải ước lượng.

Điểm reviewer sẽ nhắm vào: EXP05C cho thấy feedback đóng góp 0 % ở Clean và 16.07 % ở Stressed
— **đóng góp lớn nhất dưới mạng xấu lại đến từ thành phần phi vật lý nhất**.

Một sắc thái đáng chú ý mà EXP05C làm rõ: A4 mua 16.07 % RMSE ở Stressed bằng cách **tăng tốc
độ truyền từ 8.95 lên 15.76 Hz (+76 %)**. Đó không phải là "cải thiện miễn phí" — và con số
+76 % này vẫn *chưa* tính traffic ACK.

*Hướng sửa (chưa làm):* kênh ACK ngược có delay/loss riêng; đếm `txCountAck` và báo cáo
`txCountTotal = txCountData + txCountAck`; transmitter dùng AoI **ước lượng** từ ACK trễ.
Sau đó chạy lại EXP05B/05C/05D/06A.

### A2. Bug tiềm ẩn trong `syncAcceptedStateMemory` — ĐÃ ĐO, KHÔNG ẢNH HƯỞNG

`simulation/simSwarmAoIAware.m:1434-1441` — khi hàng `pending` rỗng hoặc không có gói khớp
`receiverGenTime`, hàm tăng `ackSyncMissCount` rồi `continue` **mà không đẩy
`txState.ackGenTime(i,j)`**. Vì `receiverGenTime` chỉ tăng, nhánh đó vẫn đúng ở các bước sau →
`ackPos/ackVel` đứng yên, sai số state-change tăng dần, link trigger ở 50 Hz.

Trạng thái này **không vĩnh viễn** — nó tự phục hồi ở lần sync thành công tiếp theo. Và vì
`storePendingNeighborPacket` được gọi **trước** khi rút thăm mất gói (L801-820), mọi gói đã
phát đều nằm trong `pending`.

**Kết quả đo:**

| Thực nghiệm | Accepted-state updates | Sync misses |
|---|---|---|
| EXP05C | 193 129 | **0** |
| EXP05D | 1 456 105 | **0** |

Bug chưa bao giờ kích hoạt. Kết quả Full-AoI cũ **không** bị nhiễm. Vẫn nên vá phòng ngừa (đẩy
`ackGenTime` khi miss) nhưng không khẩn cấp. `ackSyncMissCount` nay được lưu vào `tidy.csv` và
in ra ở cuối EXP05B/05C/05D/06A, nên nếu tương lai nó khác 0 sẽ thấy ngay.

### A3. Kết luận O(N) một phần là do thiết kế topology

`swarm/applyScalableSwarmConfig.m:70-115` cố định degree = 2 và pin cứ một agent cách một agent
→ số channel = `2N + floor(N/2) = 2.5N` **chính xác theo công thức**. Vì vậy α ≈ 1 cho *tổng*
traffic gần như là hệ quả tất yếu của topology, không phải phát hiện thực nghiệm.

Khẳng định *không tầm thường* là: **tốc độ trên mỗi channel giữ gần như không đổi khi N tăng**.
Nên trình bày Hz/channel theo N làm kết quả chính. Và cần thêm ít nhất một topology có degree
tăng theo N (k-NN bán kính cố định, hoặc Delaunay) để chứng minh method không bùng nổ.

---

## 3. Tầng 2 — Những gì hiện KHÔNG so sánh được với nhau

### A4. EXP05B từng dùng ngưỡng baseline khác EXP05C/06A — ĐÃ SỬA

`exp05b_aoi_aware.m` viết *"State-change thresholds are FIXED to the EXP05A baseline"*, nhưng
thực tế baseline dùng `0.04 / 0.08` còn method đề xuất dùng `0.05 / 0.10`. Method được ngưỡng
cứng **thô hơn** cộng thêm sàn thích nghi `0.2 × 0.05 = 0.01 m`. So sánh bị confound: không thể
quy chênh lệch cho cơ chế AoI. EXP05C/06A dùng `0.05/0.10` cho **cả hai**, nên
"conventional event-trigger baseline" trong EXP05B **không phải cùng một policy** với trong
EXP05C/06A.

Đã đưa về `0.05 / 0.10` cho cả hai và sửa lại comment.

Ghi chú thêm: `nAoI = 1` — khung sweep AoI threshold vẫn còn trong code nhưng không quét gì cả.
`aoiMinInterTx = 0.02` là code chết (bị ghi đè bởi `aoiCooldowns(iA) = 0.10`).

### A5. EXP05B từng dùng seed không ghép cặp — ĐÃ SỬA

| Nguồn | Công thức seed cũ | Ghép cặp? |
|---|---|---|
| `exp05b` periodic | `500000 + 10000·iS + 1000·iP + s` | **Không** |
| `exp05b` event | `600000 + 10000·iS + s` | **Không** |
| `exp05b` AoI-aware | `700000 + 10000·iS + 1000·iA + s` | **Không** |
| `exp05c` | `900000 + 10000·iS + s` | Có |
| `exp06a` | `1100000 + 100000·iS + 10000·iN + s` | Có |

Ba họ seed khác nhau → không có common random numbers, phương sai lớn hơn, và **mọi paired
test trên kết quả EXP05B cũ đều không hợp lệ**. Đã hợp nhất về `800000 + 10000·iS + s`.

**Cảnh báo còn lại (chưa sửa):** ngay cả khi seed trùng, mỗi method gọi `rand` số lần khác nhau
nên chuỗi RNG lệch pha ngay lập tức. Seed trùng mua được *tính tái lập*, **không** mua được CRN
thật. CRN đúng cần một tensor loss/jitter sinh sẵn theo chỉ số `(i, j, k)` mà mọi method cùng
tra vào. Đây là thay đổi rẻ và sẽ làm error bar chặt hơn đáng kể.

### A6. EXP03A chạy trên engine mạng khác phần còn lại của họ EXP03 — CHƯA SỬA

`exp03a_packet_loss.m:36` gọi `simSwarmNetwork` (Gen-1): **không có mô hình delay**, AoI theo
bộ đếm reset khi nhận, `nextCommTime` khởi tạo ở 0 thay vì `commPeriod`. EXP03B/C/D dùng
`simSwarmNetworkQueued` (Gen-2: AoI theo `genTime`, có delay/jitter/reorder). Hai định nghĩa
AoI chỉ trùng nhau khi delay = 0.

→ **Không được đặt bảng EXP03A cạnh EXP03B/C/D** trong bài báo mà không nói rõ điều này.

### A7. `PDR` là hai đại lượng khác nhau dưới cùng một tên — CHƯA SỬA

```
simSwarmNetwork.m:162        PDR = rxCount / txCount            % Gen-1 (EXP03A)
simSwarmNetworkQueued.m:184  PDR = 1 - dropCount / txCount      % Gen-2
                             arrivalRatio = rxCount / txCount
```

`PDR` của Gen-2 theo định nghĩa ≈ `1 − packetLoss` và gần như **không mang thông tin gì** — nó
chỉ đọc lại tham số đầu vào. Đại lượng có ý nghĩa là `arrivalRatio` / `effectiveUpdateRatio`.
`PDR` của Gen-1 chính là `arrivalRatio` của Gen-2.

### A8. `AoIP95` cũng là hai đại lượng khác nhau dưới cùng một tên — CHƯA SỬA

- `exp03d:241`, `exp04a:203`, `exp05a:440`: `prctile(out.meanAoI(idxEval), 95)` — phân vị của
  chuỗi **trung bình toàn mạng**.
- `exp05b` + `collectLinkAoI` (L1868): `prctile` trên mẫu **từng link gộp lại** — mới là tail
  metric trung thực.

Chuỗi trung bình của 12 link có đuôi mỏng hơn hẳn phân phối link gộp. Tệ hơn: link-level P95
**chỉ tính được cho method đề xuất** — `out.neighborAoI` không tồn tại trên output của
`simSwarmNetworkQueued` / `simSwarmEventTriggered`. **Con số tail-AoI headline của method đề
xuất hiện không có baseline nào để so.** Thêm log per-link AoI vào hai simulator baseline là
việc rẻ và mở ra một hình so sánh tốt.

### A9. Baseline periodic đồng bộ tuyệt đối — CHƯA SỬA

`network/simSwarmNetworkQueued.m:33,39` dùng một đồng hồ `nextCommTime` toàn cục → mọi channel
phát cùng một khoảnh khắc, mãi mãi. Hệ thống periodic thực tế có phase offset giữa các node.
Đồng bộ cứng làm AoI của baseline xấu hơn mức cần thiết (mọi link cùng lúc stale). Thêm phase
offset ngẫu nhiên cho từng link sẽ là baseline công bằng hơn — và vì §1.1 cho thấy periodic
vốn đã cạnh tranh tốt, việc này **có thể làm baseline mạnh lên nữa**. Cần biết trước khi nộp
bài, chứ không phải để reviewer phát hiện.

### A11. Bất đối xứng refractory — CHƯA SỬA

Policy AoI có `minInterTx` (`aoiAwareTriggerPolicy.m:422`), baseline `eventTriggerPolicy.m`
không có. Thêm nữa `minInterTx` được kiểm tra **sau cùng và ghi đè `maxSilence`** → tính chất
"guaranteed maximum silence" mà comment EXP05A/B khẳng định **không được đảm bảo bằng cấu
trúc**. Hiện vô hại vì mọi caller đặt `minInterTx = dt`, nhưng là latent liveness bug.

### A12. Không có kiểm định thống kê nào — HẠ TẦNG ĐÃ SẴN SÀNG

20 seeds, in mean ± std, không CI, không paired test, không effect size. Con số "cải thiện
9.4 %" cần Wilcoxon signed-rank hoặc paired t-test kèm khoảng tin cậy.

`tidy.csv` nay chứa giá trị **thô theo từng seed** cho mọi thực nghiệm Monte-Carlo, nên toàn bộ
phần thống kê có thể tính lại **mà không cần chạy lại mô phỏng**. Ví dụ đã kiểm chứng, tính
hoàn toàn từ `tidy.csv` (ghép cặp theo cột `seed`, Wilcoxon signed-rank, CI 95 % trên hiệu):

*EXP05C, A3 (adaptive) → A4 (accepted-state feedback):*

| Scenario | A3 RMSE | A4 RMSE | Δ | CI 95 % | p |
|---|---|---|---|---|---|
| Clean | 0.0377 | 0.0377 | +0.0000 | [0, 0] | — (khác biệt đúng bằng 0) |
| Moderate | 0.1035 | 0.0976 | +0.0059 | [+0.0055, +0.0063] | 8.9 × 10⁻⁵ |
| Stressed | 0.1556 | 0.1306 | +0.0250 | [+0.0234, +0.0266] | 8.9 × 10⁻⁵ |

*EXP05D, Full-AoI so với State-event ở cùng `epsP`, mạng Stressed:*

| epsP | Full-AoI | State-event | Δ | p |
|---|---|---|---|---|
| 0.030 | 0.1140 | 0.1886 | +0.0746 | 8.9 × 10⁻⁵ |
| 0.050 | 0.1307 | 0.2573 | +0.1265 | 8.9 × 10⁻⁵ |
| 0.080 | 0.1489 | 0.3511 | +0.2022 | 8.9 × 10⁻⁵ |

`p = 8.9 × 10⁻⁵` là giá trị nhỏ nhất mà signrank có thể trả về với n = 20, tức mọi seed đều
cùng chiều. Lưu ý kỹ thuật: phải ghép cặp theo cột `seed`, **không** được sort riêng hai vector
giá trị — làm vậy sẽ phá vỡ tính ghép cặp và làm hẹp CI một cách giả tạo.

---

## 4. Tầng 3 — Bug và code chết

| # | Vấn đề | Vị trí | Trạng thái |
|---|---|---|---|
| B1 | `exp03_packet_loss_sweep.m` là code chết: gọi `simSwarm(cfg)` vốn **không có mô hình mạng** (bỏ qua hoàn toàn `cfg.net.packetLoss`), rồi đọc `out.metrics.PDR/.meanAoI/.leaderTrackingRMSE/.collisionOccurred` — không trường nào tồn tại; còn set `cfg.seed` thay vì `cfg.net.seed`. `run_all.m` gọi nó ở bước 3/3 nên **`run_all` cũng hỏng**. Trớ trêu: đây là script **duy nhất** từng ghi file kết quả. | `exp03_packet_loss_sweep.m`, `run_all.m` | ✅ đã deprecate + viết lại `run_all` |
| B2 | `cfg.event.*` **không có default ở đâu cả** — `simSwarmEventTriggered(defaultConfig())` sẽ lỗi (khác `simSwarmAoIAware.m:42-80` và `simSwarmAoIAblation.m:49-96` đều tự default). | `configs/defaultConfig.m` | ⏸ |
| B3 | `defaultConfig.m` định nghĩa khối swarm+net **hai lần** (L26-61 rồi L67-134). Nguy hiểm: L44-55 định nghĩa `adjacency` là **ring + leader nối tất cả**, L94 định nghĩa `A` là **ring thuần**. Người đọc L44-55 sẽ hiểu sai topology. Rác: `kp/kv/leaderKp/leaderKv`, `adjacency`, `net.rateHz/delaySec/maxAoI`. | `configs/defaultConfig.m` | ⏸ |
| B4 | Leader nhận gói **không bao giờ dùng**: `A(1,2)=A(1,5)=1` nên agent 1 nhận 2/12 channel ở N=5, nhưng controller hardcode `accCmd(1,:) = leader.acc'`. → **≈17 % số lần truyền được đếm ở N=5 là lãng phí thuần**, và `nChannels` (mẫu số chuẩn hoá ở khắp nơi) bao gồm chúng. Tỉ lệ co lại theo N (17 % ở N=5 → 1.6 % ở N=50). | `distributedFormationPolicy.m:23` | ⏸ |
| B5 | `MINSEP` cấp phát nhưng **không bao giờ ghi** → cột "MinFull" in ra luôn bằng 0.0000. | `exp03a_packet_loss.m` | ✅ đã sửa |
| B6 | `test_formation_error.m` hỏng hẳn: nó dùng index cột `offsets(:,i)` trên ma trận 5×3, nên **báo lỗi out-of-bounds** mỗi lần chạy — không phải chỉ vô nghĩa mà là không chạy được. Kể cả khi sửa index thì nó vẫn so `offsets` với chính nó nên không thể fail. | `tests/test_formation_error.m` | ✅ viết lại thành 4 ca kiểm thử đối chiếu với đáp án giải tích |
| B7 | Min-separation O(K·N²) → ở N=50 là ~1.8 triệu lần `norm()` mỗi run × 640 run trong EXP06A. | `computeSwarmMetrics.m` | ✅ đã vector hoá (nhanh hơn 6–11×, khớp bit-for-bit) |
| B8 | `ablationTriggerPolicy` (`simSwarmAoIAblation.m:782-978`) là bản sao gần nguyên văn của `aoiAwareTriggerPolicy` và **đã thiếu clamp `scaleMin`**. Hôm nay số vẫn trùng nhưng hai bản chỉ cách nhau một lần sửa là lệch. Thêm nữa **default AoI của hai sim khác nhau**: `AoIAware` là `0.04/0.08/0.16`, `AoIAblation` là `0.05/0.10/0.12`. | | ⏸ |
| B9 | `net.valid` / `net.leaderValid` được ghi nhưng **không bao giờ đọc**. Vô hại hôm nay chỉ vì init gieo sẵn trạng thái thật tại t=0 → **mọi link khởi đầu với AoI=0 và thông tin hoàn hảo miễn phí**. Cửa sổ đánh giá t≥8 s che được, nhưng nên khẳng định chứ đừng giả định. | `initQueuedNetworkState.m` | ⏸ |
| B10 | Jitter là Gaussian bị cắt (`max(delay,0)`) → **lệch trung bình delay lên trên**. Với `delay=0` thì delay hiệu dụng là half-normal trung bình `jitterStd·√(2/π)`, không phải 0. Ảnh hưởng cách đọc đường cong EXP03D. | `enqueueNetworkPackets.m` | ⏸ |
| B11 | Con số headline là biến cục bộ bị ghi đè trong vòng lặp: `savingVs10`/`savingVs20`/`eventRateChange` (EXP05B), `gainA2..A4`/`rateA2..A4` (EXP05C) — chỉ scenario **cuối cùng** sống sót. | `exp05b`, `exp05c` | ✅ đã chuyển thành mảng theo scenario |
| B12 | `run_all.m`, `PROJECT_TREE.txt`, `README.md` chỉ mô tả 3/17 experiment. | root | ✅ đã cập nhật |
| B13 | **Không phải git repository.** 15 nghìn dòng code nghiên cứu không có lịch sử phiên bản. | root | ✅ đã `git init` |
| B14 | **`parfor` âm thầm đổi kết quả.** Worker của parallel pool mặc định dùng generator ngẫu nhiên **khác** client, nên `rng(seed)` gieo một chuỗi khác. Đo được: `max|ΔRMSE|` tới 1.8e-2 và `max|ΔtxCount|` tới 121 gói giữa serial và parallel. | mọi simulator | ✅ đã ghim `rng(seed,'twister')`; nay khớp **bit-for-bit** |

---

## 5. Tầng 4 — Giới hạn phạm vi cần nêu rõ trong bài báo

### A13. Mô hình 6-DOF hoàn toàn tách rời khỏi EXP02–06

Có **hai lớp vật lý không hề chạm nhau**:

| Lớp | Tích phân | dt | Dùng ở |
|---|---|---|---|
| Quadrotor 6-DOF, 12 trạng thái | RK4 | 0.002 s (500 Hz) | chỉ EXP01x |
| Double integrator | Euler nửa ẩn | 0.02 s (50 Hz) | **toàn bộ** EXP02–06 |

Leader thậm chí không được tích phân — nó bị *dịch chuyển tức thời* lên reference mỗi bước
(`P(1,:) = leader.pos'`), nên leader **chính là** reference chứ không phải một phương tiện.
`cfg.swarm.maxSpeed`, `safetyRadius`, `connectivityRange` đều là code chết — không giới hạn tốc
độ, không tránh va chạm, không duy trì liên thông. Chỉ có bão hoà gia tốc.

Ngoài ra, controller của EXP01 được gọi **bên trong** các stage RK4, tức nó được mô hình hoá
như controller liên tục, không phải zero-order hold — không nên mô tả nó là "digital controller
50/500 Hz".

*Mức tối thiểu:* nêu rõ đây là abstraction có chủ ý.
*Mức mạnh:* một experiment xác nhận với follower là quadrotor 6-DOF, formation policy làm vòng
ngoài và `quadCascadedController` làm vòng trong. Chỉ N=5 tại ba điều kiện mạng cũng đủ trả lời
"câu chuyện AoI có sống sót qua động học attitude thật không?" — và đây chính là cây cầu tự
nhiên sang giai đoạn hardware.

### A14. Chi phí truyền là unicast theo từng directed link, không phải broadcast

`enqueueNetworkPackets.m:14-30` — mỗi cạnh có hướng `(i,j)` là một lần truyền riêng với một lần
rút thăm mất gói **độc lập**. Trong 802.11 / ESP-NOW / BLE, một lần broadcast được **tất cả**
neighbor nghe. Dưới mô hình broadcast, baseline periodic rẻ đi theo bậc của degree, còn method
đề xuất — vốn ra quyết định *theo từng link* — mất một phần lợi thế.

Queue cũng không giới hạn dung lượng, không có MAC, không tranh chấp băng thông, không nhiễu
giữa các link, không mô hình clock skew (staleness rejection ngầm giả định đồng hồ toàn cục
hoàn hảo). Mất gói là Bernoulli i.i.d. — không burst, không Gilbert-Elliott, không phụ thuộc
khoảng cách/SNR.

### A15. Chưa có nhiễu cảm biến / sai số ước lượng

Mọi agent biết **chính xác** trạng thái của mình, và trạng thái truyền đi là chính xác. Thực tế
thứ được truyền là một **ước lượng**, và event-trigger trên tín hiệu nhiễu gây chattering /
false trigger — vấn đề kinh điển của event-triggered control và là câu hỏi reviewer chắc chắn
hỏi. Roadmap L3 đã liệt kê.

### A16. Hằng số hardcode, nhiều bản sao

- Cửa sổ đánh giá `t >= 8.0` ở `computeSwarmMetrics.m` **và** được suy lại thành `out.t >= 8`
  trong **mọi** experiment driver.
- `formationThreshold = 0.10` / `safetyThreshold = 0.25`: **năm** bản sao độc lập.
- `scaleBase / scaleMin / adaptRange`: **bốn** bản sao.
- `leaderReference.m` không nhận `cfg` — quỹ đạo leader hoàn toàn hardcode.

Với T=30 s và leader bay tròn ω = 0.2 rad/s (chu kỳ 31.4 s), cửa sổ đánh giá 8–30 s **chưa tròn
một vòng**. Chấp nhận được nhưng phải nêu trong bài.

### A17. `velocityDisagreement` tính trên cả N agent kể cả leader

`computeSwarmMetrics.m` — trong khi `formationError` loại leader ra. Leader là reference nên
gộp nó vào làm phồng disagreement mỗi khi follower bị trễ. Hai metric đang dùng hai tập agent
khác nhau.

### A18. Độ phân giải thời gian

`dt = 0.02` vừa là bước tích phân vừa là chu kỳ ra quyết định truyền → trigger không bao giờ
nhanh hơn 50 Hz, và AoI chỉ có độ phân giải 20 ms trong khi ngưỡng AoI là 120 ms (6 mẫu). Nên
có một kiểm tra độ nhạy theo dt (dt = 0.01) để chứng minh kết quả không phải hiện vật của rời
rạc hoá.

---

## 6. Thứ tự ưu tiên đề xuất cho bước tiếp theo

Xếp theo mức cải thiện kỳ vọng đối với chất lượng bài báo, không theo chi phí thực thi.

1. **ACK thật (A1).** Kênh ngược có delay/loss riêng, đếm vào tổng chi phí, transmitter dùng
   AoI ước lượng. Đây là lỗ hổng lớn nhất và cũng là thứ duy nhất có thể lật ngược kết luận
   §1.2. Phải làm trước khi viết manuscript.
2. **Broadcast so với unicast (A14).** Quyết định mô hình chi phí nào bạn đang bảo vệ, và đo cả
   hai nếu có thể.
3. **Topology robustness (A3).** Ít nhất một họ topology có degree tăng theo N, cộng với mất
   link/node. Chuyển kết quả scalability chính sang Hz/channel.
4. **Baseline periodic có phase offset (A9)** và **CRN thật (A5)**. Cả hai đều rẻ và cùng làm
   cho so sánh trở nên không thể bắt bẻ.
5. **Kiểm định thống kê (A12).** Dữ liệu đã sẵn trong `tidy.csv`.
6. **Xác nhận bằng 6-DOF (A13).** Cầu nối sang hardware.
7. Nhiễu cảm biến (A15), quét dt (A18), dọn dẹp code (B2, B3, B4, B6, B8, B9, B10).

TinyGNN / MARL vẫn nên để lại cho bài sau. Bài này đã là một communication-control paper đủ độc
lập; thêm AI lúc này sẽ làm loãng đóng góp.
