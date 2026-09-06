# EXP12 — Shared-medium infrastructure plan

**Status:** completed infrastructure diagnostic. Protocol locked before the
matrix; the recorded run is
`results/exp12_shared_medium_diagnostic/2026-08-29_104600`. EXP12 không tạo
headline performance claim và không được dùng để tune Causal-Broadcast.

## 1. Mục tiêu

Xây một network kernel có thể biểu diễn broadcast reception, finite node queue,
frame airtime, contention/collision và aggregated ACK. Gate của EXP12 kiểm tra
semantics và accounting, không kiểm tra policy nào tốt hơn.

## 2. Interfaces cố định

### End-to-end simulator contract

`simSwarmSharedMedium(cfg, method)` is the only public bridge from formation
control to the EXP12 kernel. `method` is a closed variant with exactly three
development values: `periodic`, `state-event`, and `causal-broadcast`.
Unknown values raise an error; the simulator does not infer a policy from
threshold fields. DATA/ACK delivery is applied at the MAC event time, while
control consumes the resulting cache at the next outer sample.

The returned struct always contains the same four groups:

- trajectories and control commands (`t`, `P`, `V`, `A`);
- true and sender-confirmed age logs (`trueAoI`, `estimatedAoI`);
- cumulative MAC/accounting state (`netStats`, `netLogs`);
- provenance and passive diagnostics (`traceHashExact`, queue/counter logs,
  network runtime and invariant count).

`computeSharedMediumMetrics(out,cfg)` is the only aggregation boundary. It
keeps formation, physical frame, logical recipient, airtime, confirmed-age,
fairness and energy-proxy quantities under distinct names.

### `initSharedMediumState(cfg, topology)`

Trả về:

- một transmit queue hữu hạn cho mỗi node;
- receiver table `acceptedSeq(receiver,sender)` và `acceptedGenTime`;
- sender belief `ackedSeq(receiver,sender)` và `ackedGenTime`;
- MAC/backoff state, fixed-size history rings và counters.

### `enqueueBroadcastState(net, sender, payload, tk, cfg)`

Enqueue một frame duy nhất, với receiver mask lấy từ out-neighbors. Nếu queue đã
có state DATA cũ chưa phát của cùng sender, replacement policy giữ frame mới
nhất và tăng `supersededBeforeServiceCount`.

### `enqueueAckSummary(net, receiver, ackEntries, tk, cfg)`

Merge cumulative ACK entries vào ACK summary đang chờ của node. Không tạo hai
entry cho cùng sender; sequence lớn nhất thắng.

### `advanceSharedMedium(net, t0, t1, cfg, trace)`

Chạy MAC event từ `t0` tới `t1`; trả về delivered DATA/ACK events và counters.
Kết quả chỉ phụ thuộc vào input state và pre-drawn trace, không phụ thuộc số lần
random generator đã được gọi bởi policy.

### `applySharedMediumDeliveries(net, events, tk, cfg)`

Áp dụng newest-generation-wins, tạo/merge ACK obligation, cập nhật causal belief
chỉ khi ACK event đến.

## 3. Primary MAC abstraction

- `slotTime`: 1 ms ở infrastructure tests; experiment value được chọn ở EXP13
  từ PHY/frame calibration.
- `queueCapacity`: số frame hữu hạn theo node; ACK summary và DATA có logical
  priority riêng nhưng không preempt một frame đang phát.
- p-persistent CSMA: node có frame cảm nhận medium, backoff theo pre-drawn trace,
  và phát khi counter về 0.
- Hai frame overlap tại một receiver gây collision, trừ khi conflict graph cho
  biết receiver chỉ nghe một sender.
- Sau collision outcome, mỗi intended receiver còn chịu residual link PER từ
  trace; các receiver của cùng broadcast có thể có outcome khác nhau.
- TDMA và slotted ALOHA dùng cùng frame/delivery interface để tách policy effect
  khỏi MAC effect.

Không mô phỏng SINR, modulation/coding, capture effect hoặc một IEEE standard cụ
thể trong EXP12.

## 4. Deterministic acceptance gates

1. **One-to-many delivery:** một DATA frame, ba intended receivers, ba success
   tạo `frameTx=1`, `recipientSuccess=3`, không tạo ba DATA transmissions.
2. **Partial broadcast reception:** một frame có receiver outcomes success/loss/
   success; chỉ hai receiver advance generation time.
3. **Collision:** hai senders overlap tại một receiver; không receiver nào
   accept và collision counters tăng đúng một event/mỗi affected frame.
4. **No collision under serialization:** cùng hai frames nhưng non-overlap đều
   được deliver.
5. **Queue replacement:** ba state updates chờ service từ một sender chỉ giữ
   update mới nhất; counter superseded bằng hai.
6. **Finite queue:** overflow đi theo declared priority/drop rule và memory không
   vượt capacity.
7. **Cumulative ACK merge:** nhiều acceptance của cùng sender trước service tạo
   một ACK entry với sequence mới nhất.
8. **Piggyback:** pending ACK entries gắn vào DATA frame kế tiếp và không đồng
   thời tạo standalone ACK.
9. **ACK deadline:** khi node không phát DATA, đúng một standalone summary được
   tạo tại deadline.
10. **Causality:** DATA drop/collision không tạo ACK; ACK drop không update sender;
    stale ACK không rollback; future/unknown sequence bị reject.
11. **Bounded history:** ACK outage dài hơn `W` không làm allocation tăng; late
    expired ACK được count và không corrupt belief.
12. **Trace determinism:** hai policies có action sequence giống nhau trên cùng
    trace phải có bit-identical delivery/accounting.
13. **Accounting identity:** total occupied airtime bằng tổng duration của các
    non-overlapped busy intervals; bytes/frame/recipient counters không bị trộn.
14. **Zero-load limit:** khi chỉ một sender và PER=0, CSMA/ALOHA/TDMA đều deliver
    cùng payload/sequence order; chỉ access delay có thể khác theo specification.

Tất cả 14 gates phải pass trước EXP13.

## 5. Logged metrics contract

- `dataFramesGenerated`, `dataFramesAttempted`, `dataFramesDeliveredAny`;
- `recipientAttempts`, `recipientSuccess`, `recipientLoss`;
- `ackFramesStandalone`, `ackEntriesPiggybacked`, `ackEntriesDelivered`;
- `collisionFrames`, `retryFrames`, `queueDrops`, `supersededBeforeService`;
- `busyTime`, `dataAirtime`, `ackAirtime`, `piggybackOverheadAirtime`;
- mean/p95/p99 access delay, one-way delay, ACK RTT, true AoI and estimated AoI;
- maximum queue depth, history depth and per-step network runtime.

Control-layer metric names giữ tương thích với Study 1, nhưng logical DATA rate,
frame rate, recipient-delivery rate và airtime không được dùng thay nhau.

## 6. EXP12 outputs

- shared-medium kernel và deterministic tests;
- một infrastructure-only trace figure minh họa queue/access/delivery/ACK;
- machine-readable configuration và test report;
- không có bảng “Causal-Broadcast vs baseline”, không có holdout seeds, không có
  claim superiority.

## 7. Completion record

Implementation and diagnostic evidence are recorded in
`docs/EXP12_SHARED_MEDIUM_RESULTS.md`. The final matrix contains 108
development runs and passed 14/14 declared infrastructure gates. The result
does **not** select a winning policy or change the analytical primary
`pAccess=0.2` for EXP13.
