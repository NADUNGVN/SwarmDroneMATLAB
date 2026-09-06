# Chương trình nghiên cứu kế tiếp: Causal Semantic Freshness trên shared medium

## 1. Hướng nghiên cứu trung tâm

Study 1 đã trả lời một câu hỏi hẹp nhưng có giá trị: một sender có thể dùng ACK
nhân quả để thay đổi communication effort theo chất lượng mạng mà không biết
regime hay không? Kết quả frozen cho thấy **có**, nhưng đồng thời cho thấy thiết
kế per-directed-link và ACK riêng làm lợi thế biến mất dưới broadcast
accounting.

Study 2 không nhằm “làm Causal-v3 thắng bằng tuning”. Câu hỏi mới là:

> Có thể duy trì receiver-confirmed semantic freshness trong UAV formation,
> đồng thời khai thác một DATA broadcast cho nhiều neighbor và tránh feedback
> implosion trên shared wireless medium hay không?

Tên làm việc của phương pháp mới là **Causal-Broadcast**. Đây là một nghiên cứu
mới vì biến quyết định không còn chỉ là “khi nào một directed link gửi”, mà là
đồng thiết kế ba lớp:

1. semantic event generation tại sender;
2. aggregation theo nhiều receiver có freshness khác nhau;
3. contention, queueing và aggregated feedback trên shared medium.

Study 1 và toàn bộ frozen result không bị ghi đè. Causal-v3 trở thành legacy
mechanism baseline của Study 2.

## 2. Câu chuyện khoa học nối từ literature tới contribution

Các dòng nghiên cứu hiện tại đã giải quyết những phần khác nhau:

- Event-triggered multi-agent control xác định khi state innovation đáng gửi và
  có stability/Zeno results, kể cả UAV experiments, nhưng thường không biết một
  receiver cụ thể đã nhận gì.
- AoI-aware control và AoI scheduling xác định khi receiver information đã cũ,
  nhưng thường đặt decision maker ở scheduler hoặc common receiver.
- AoII/AoCI/VoI đưa content relevance vào freshness; vì vậy age-plus-content
  không phải novelty riêng của dự án.
- ACK/two-way-delay work giải partial observability của receiver age, nhưng chủ
  yếu cho source--destination hoặc nhiều sensor tới một common receiver.
- WiSwarm và random-access work giải một phần shared-medium implementation,
  collision và stale-packet handling, nhưng không có per-neighbor formation
  semantics của Study 1.

Khoảng trống tiếp theo nằm ở giao điểm: **broadcast state có giá trị chung cho
nhiều neighbor, nhưng knowledge về việc neighbor nào đã nhận lại là riêng từng
receiver**. Nếu giữ per-link action như Study 1 thì không khai thác được
broadcast; nếu bỏ receiver-specific feedback thì mất tính causal. Study 2 giải
quyết đúng xung đột này.

## 3. Phương pháp Causal-Broadcast

### 3.1 Trạng thái sender

Mỗi sender `j` giữ một state broadcast chung và một belief tối thiểu cho từng
out-neighbor `i`:

- `lastBroadcastState(j)`, `lastBroadcastSeq(j)`, `lastBroadcastTime(j)`;
- `ackedSeq(i,j)`, `ackedGenTime(i,j)`;
- `latestUnconfirmed(i,j)` cho biết receiver đó chưa xác nhận broadcast mới nhất;
- một history ring có kích thước cố định `W`, không dùng outstanding list tăng
  không giới hạn.

Innovation được tính một lần theo sender:

\[
I_j(t)=\max\left\{
\frac{\|p_j(t)-p_j^{\mathrm{bcast}}\|}{\epsilon_p},
\frac{\|v_j(t)-v_j^{\mathrm{bcast}}\|}{\epsilon_v}
\right\}.
\]

Receiver-confirmed age vẫn riêng theo link:

\[
\widehat A_{ij}(t)=t-g^{\mathrm{ack}}_{ij}(t).
\]

Primary aggregation dùng worst-neighbor risk để không âm thầm bỏ một neighbor:

\[
R_j(t)=\max_{i\in\mathcal N_j^{out}}
I_j(t)\,f(\widehat A_{ij}(t)).
\]

`f` dùng đúng dạng bounded monotone của v3 ở version đầu; không thêm learned
component. Quantile/control-weighted aggregation chỉ là ablation sau khi
worst-neighbor version đã được đánh giá.

### 3.2 Branch semantics

- **Hard new information:** sender innovation vượt hard threshold; tạo đúng một
  DATA broadcast.
- **Freshness-adaptive new information:** ít nhất một receiver stale và
  aggregated semantic risk vượt ngưỡng; tạo đúng một broadcast.
- **Refresh:** receiver-specific feedback cho thấy ít nhất một neighbor stale,
  nhưng không có state mới; chỉ tạo broadcast khi không có broadcast hữu ích mới
  hơn đang chờ confirmation và refresh cooldown đã hết.
- **Max silence:** recovery backstop, tạo một broadcast chung.

Một broadcast mang một sequence number của sender và có thể được mỗi neighbor
accept/drop độc lập. Traffic không còn nhân với directed degree tại enqueue.

### 3.3 Aggregated causal feedback

Mỗi receiver giữ cumulative accepted sequence cho từng sender. Feedback dùng hai
cơ chế cùng semantics:

1. piggyback một ACK vector đã merge vào DATA broadcast tiếp theo của receiver;
2. nếu không có DATA trước `ackDeadline`, gửi một standalone aggregated ACK.

ACK vector xác nhận sequence/generation time mới nhất của nhiều sender trong một
frame. ACK cũ không rollback state; ACK tương lai hoặc sequence lớn hơn sequence
đã gửi bị loại. Silence không bao giờ được diễn giải thành success, nên causality
không bị đổi để lấy lợi thế traffic.

History và ACK vector đều có kích thước chặn theo graph degree và `W`. Queue áp
dụng latest-generated-wins cho state DATA và merge-in-place cho ACK summary.

## 4. Shared-medium model

Study 2 dùng một discrete-event MAC kernel chạy giữa hai outer control ticks:

- queue hữu hạn theo node, không còn queue riêng vô hạn theo directed link;
- frame airtime từ payload/header bytes và PHY rate;
- collision-free TDMA làm information upper reference;
- p-persistent CSMA làm primary abstract shared-medium model;
- slotted ALOHA làm contention stress reference;
- collision tại receiver, retry/backoff, queue replacement/drop và channel busy
  time được log tách biệt;
- forward reception vẫn có residual link PER sau khi MAC outcome đã xác định;
- hidden-terminal conflict graph là một OOD arm, không bật trong development
  primary cell.

Đây là MAC abstraction, không được gọi là IEEE 802.11 simulation. Trace-driven
hoặc ns-3/HIL sẽ là validation riêng.

## 5. Baseline programme

Mọi adaptive baseline dùng cùng plant, topology, MAC trace, information
constraint và tuning budget.

1. Periodic broadcast frontier: P5, P10, P12.5, P20, P25.
2. State-event broadcast frontier: threshold sweep, một broadcast mỗi sender
   event.
3. Causal AoI-only broadcast: delayed ACK receiver-age belief, không đọc state
   innovation; đây là baseline gần với ACK/AoI scheduling.
4. Causal AoCI-inspired broadcast: age nhân content-change score, nhưng không có
   new-information/refresh split.
5. Delayed-ACK belief baseline adapted from Tahir et al.: particle belief trên
   receiver AoI, chọn broadcast theo worst expected age; ghi rõ đây là adaptation
   sang multi-receiver broadcast, không phải reproduction nguyên trạng.
6. Legacy Causal-v3: per-directed-link DATA và cumulative ACK hiện tại.
7. Oracle receiver-state reference: dùng true accepted state nhưng cùng
   broadcast/MAC action space; không phải performance bound.

Frontier được so theo RMSE, safety, airtime và energy proxy. Không chọn một
single baseline point sau khi thấy holdout.

## 6. Chuỗi experiment

### EXP12 — Shared-medium infrastructure validation

Không có method claim. Xây MAC/data/ACK kernel, deterministic micro-cases,
limit-equivalence, CRN trace và accounting. Chi tiết ở
`docs/EXP12_SHARED_MEDIUM_PLAN.md`.

**Completed:** run `2026-08-29_104600` passed 14/14 infrastructure gates over
108 development runs. The executable evidence and boundary findings are in
`docs/EXP12_SHARED_MEDIUM_RESULTS.md`. No policy point was selected and no
superiority claim was opened.

### EXP13 — Development và mechanism ablation

- Chỉ dùng development seeds.
- So sánh unicast v3, broadcast DATA only, broadcast + standalone ACK,
  piggyback ACK, và full Causal-Broadcast.
- Xây frontier cho từng baseline với cùng số evaluation points.
- Screening parameter bằng Morris/Latin-hypercube; không dùng holdout.
- Kết thúc bằng một config + một primary MAC cell được freeze và commit.

**Completed:** run `2026-08-29_111747` passed 14/14 gates over 531 development
runs and selected the original default trigger design 0. The proposed frontier
is not Pareto in Clean/Moderate and has two Pareto points in Stressed; broadcast
aggregation nevertheless roughly halves physical offered airtime relative to
the unicast ablation at comparable RMSE. Post-run EXP13B
`2026-08-29_131048` passed 6/6 gates and showed that the one-slot PHY makes
CSMA and ALOHA degenerate, while four-slot DATA restores the intended MAC
distinction. Details are in `docs/EXP13_DEVELOPMENT_RESULTS.md`. EXP14 remains
closed until burst/time-varying loss, reverse asymmetry and a multi-slot primary
are preregistered.

### EXP14 — Preregistered holdout

- 100 seeds hoàn toàn mới, paired common random traces.
- Primary: N=5, 6-DOF followers, ring2, time-varying network, p-persistent CSMA.
- Secondary/OOD: N=10 và 20, ring/degree variants, background load, burst loss,
  hidden terminal, reverse asymmetry và estimator noise.
- Báo toàn bộ negative cells; không thay config sau khi mở holdout.

**Completed:** EXP14A run `2026-08-29_155023` contains 10,500 primary rows and
passes 11/11 integrity gates; EXP14B run `2026-08-29_230917` contains 4,800 OOD
rows and passes 9/9. Broadcast hybrid removes the unicast cost reversal at the
Moderate mechanism contrast (−59.05% offered utilization and −3.50% RMSE), but
the frozen default is dominated by a delayed-belief point in all three primary
regimes. Piggyback-only dominates hybrid at the preregistered Moderate
mechanism contrast, while ALOHA reverses that result. The fixed `p=0.2` design
collapses at N=20 with 100/100 hybrid safety failures. Full results and the
next MAC-aware feedback direction are in `docs/EXP14_HOLDOUT_RESULTS.md`.

### EXP14C — Post-holdout MAC-aware development

**Completed:** run `2026-08-30_080346` contains 288 development rows and passes
12/12 integrity gates. The registered full-v2 candidate passes its 4/4
development eligibility criteria, but mechanism attribution shows that
`p=min(p_configured,1/N)` is the principal N20 repair. Access scaling alone has
0/8 N20 safety failures, while full-v2 has 5/8 and trades 18.56% higher RMSE
for 4.36% lower offered utilization. Because the matrix omitted adaptive ACK
plus scaled access without the load guard, no new holdout is opened until a
separately seeded factorial-closure study isolates this confound. Full results
are in `docs/EXP14C_MAC_AWARE_DEVELOPMENT_RESULTS.md`.

### EXP14D — Complete MAC-aware factorial closure

**Completed:** run `2026-08-30_183739` contains 384 development rows and passes
15/15 integrity gates after the operational runtime-column amendment documented
in `docs/EXP14D_AMENDMENTS.md`; no simulation was rerun. Only access-only and
adaptive-ACK/no-guard/scaled-access have zero failures in all four cells and
N20 offered utilization below 1.2. The frozen minimax rule selects the latter
(`a1-g0-s1`). At N20 it improves RMSE, AoI and offered load relative to
access-only with 0/12 failures, whereas enabling the fixed guard produces 6/12
failures. The next holdout must retain the negative ALOHA boundary and cannot
claim universal MAC superiority. Full results are in
`docs/EXP14D_FACTORIAL_CLOSURE_RESULTS.md`.

### EXP14E — Preregistered selected-candidate holdout

**Completed:** run `2026-08-30_213957` contains all 2,800 frozen rows, passes
14/14 integrity gates with zero divergences and zero protocol violations, and
supports all 6/6 Holm-adjusted co-primary tests across 3/3 CSMA cells. Relative
to access-only hybrid ACK, selected adaptive/no-guard/scaled access reduces
RMSE by 6.09%, 7.27% and 5.40%, and offered utilization by 2.31%, 13.11% and
1.00% at N5/N10/N20. The claim is deliberately bounded: piggyback-only is
better on continuous error/load outcomes at N5 and N10, and no population
safety or universal-MAC claim is permitted. Full results are in
`docs/EXP14E_PREREGISTERED_HOLDOUT_RESULTS.md`.

**Mathematical closure after EXP14E:** the exact marginal-value identity now
separates DATA airtime saved from direct standalone-ACK cost. The post-hoc audit
shows only 49.1% cost recovery at N5 CSMA, adverse DATA change at N10, near-zero
standalone use at N20, and 247.4% cost recovery at N5 ALOHA. A unique-lead
transmit/discard certificate has been derived and implemented. EXP14G later
identifies the focal ACK's local counterfactual under a shared pre-decision
history, while also showing that positive lead is not a benefit certificate.
See
`docs/STANDALONE_ACK_VALUE_ANALYSIS.md` and Section 7 of
`docs/STUDY2_MATHEMATICAL_FOUNDATION.md`.

### EXP14F — Paired-shadow ACK-value mechanism study

**Completed:** run `2026-08-30_230947` contains all 160 development runs and
9,694 accepted standalone-confirmation events, and passes 12/12 integrity gates
with no divergence or protocol violation. Positive generation-matched policy
lead occurs for 83.67% of N5 CSMA events, 78.53% at N10, 100% of the 20 sparse
N20 events, and 96.53% under ALOHA. Yet piggyback remains better on RMSE, true
AoI and airtime at N5/N10, while ACK assistance remains beneficial under ALOHA.
Therefore positive lead is common but not sufficient for positive value.

The two policies run independently from (t=0), so EXP14F does not identify a
per-decision causal effect after prior actions have separated their histories.
No threshold is tuned. Full results are in
`docs/EXP14F_PAIRED_SHADOW_RESULTS.md`.

### EXP14G — Branch-at-decision causal ACK replay

**Completed with support-limited verdict:** run `2026-08-30_235146` completed
240 pilots, locked 64 outcome-blind events and completed every admit/suppress
pair. Thirteen of fourteen gates pass; N5, N10 and ALOHA each have 20 distinct
parent seeds, while N20 has only four against the frozen minimum of 12.
Pre-decision network and plant/controller hashes are identical and the focal
intervention is exact.

Positive causal confirmation lead is common, but it is not sufficient for
receiver benefit. N5 has a significantly adverse 0.75 s true-AoI integral
effect and N10 has a significantly adverse integrated formation-loss effect.
ALOHA has favorable mean resource/AoI/control signs but heterogeneous
intervals crossing zero. No predictor is fitted and no confirmatory claim is
permitted. Full results are in
`docs/EXP14G_BRANCH_AT_DECISION_RESULTS.md`.

### EXP14H — N20 causal-support closure

**Completed at the frozen preflight stop:** run `2026-08-31_001447` completes
240 disjoint N20 pilots but finds only seven distinct eligible parent seeds,
below the unchanged minimum of 12. The experiment therefore generates no
replay outcome. Across EXP14G and EXP14H, only 11/300 N20 seeds contain an
eligible post-transient event (3.67%; Wilson 95% interval [2.06%, 6.45%]).

This is a practical event-support/positivity failure for the registered N20
per-decision estimand, not an ACK-effect estimate. N20 remains a sparse
boundary. The resulting categorical MAC-selective mapping—piggyback-only for
CSMA and adaptive standalone feedback for ALOHA—was passed forward to EXP14I.
Fine-grained predictor fitting and repeated N20 seed expansion are stopped.
Full results are in
`docs/EXP14H_N20_SUPPORT_CLOSURE_RESULTS.md`.

### EXP14I — Preregistered MAC-selective validation

**Completed and supported:** run `2026-08-31_004619` contains all 1,600 frozen
rows, passes 15/15 integrity gates and has exact candidate/reference aliasing
with maximum outcome difference zero. The candidate maps CSMA to
piggyback-only and ALOHA to adaptive standalone feedback using only the
configured MAC type.

All 6/6 Holm-adjusted primary hypotheses and all 3/3 observed safety guards
pass on 100 fully disjoint seeds per cell. Relative to the opposite fixed
route, candidate reduces RMSE/offered utilization by 0.97%/2.94% at N5 CSMA,
1.22%/2.64% at N10 CSMA and 11.84%/4.51% at N5 ALOHA. N20 remains descriptive:
adaptive averages only 0.77 standalone attempts per run and its continuous
differences from candidate/piggyback cross zero.

The validated contribution is the cross-MAC route selector, not novelty of
either component. No N20 causal/equivalence, population safety, universal-MAC
or hardware claim is permitted. Full results are in
`docs/EXP14I_MAC_SELECTIVE_VALIDATION_RESULTS.md`.

### EXP16 — Preregistered feedback-route-by-MAC interaction

**Completed and supported:** run `2026-08-31_104551` contains all 600 frozen
rows and passes 14/14 integrity gates with zero divergence and protocol
violations. Unlike EXP14I's separate directional contrasts, EXP16 uses one
matched 2-by-2 design and computes the route-by-MAC interaction within each of
100 new seeds before inference. A fixed-deadline hybrid ACK route is retained
as a secondary practical baseline.

All 6/6 Holm-adjusted tests pass. The RMSE interaction is −0.009268 m with 95%
CI [−0.012319, −0.006218], and the offered-utilization interaction is
−0.052961 with CI [−0.062447, −0.043475]. Piggyback lowers RMSE/load relative
to adaptive by 0.98%/2.61% under CSMA; adaptive lowers them by 9.92%/5.60%
under ALOHA. Every arm has 0/100 observed failures, with Wilson upper bound
3.70%.

The claim remains limited to the matched N5 Moderate abstract cell. It is not
a named-standard or general-MAC result. Full results are in
`docs/EXP16_FACTORIAL_INTERACTION_RESULTS.md`. The next pre-hardware gate is a
frozen operating-envelope robustness study; no policy retuning is permitted.

### EXP17 — Preregistered operating-envelope robustness

**Completed with a negative continuation verdict:** run `2026-08-31_110505`
contains all 4,000 frozen simulations and passes 14/14 integrity gates with
zero divergence and protocol violations. The core family spans N5/N10,
Moderate/Stressed and background 0/0.30; reverse-asymmetric and hidden-terminal
contexts are descriptive boundaries.

Only 11/48 globally Holm-adjusted tests reject and only the original N5
Moderate bg0 cell satisfies its full six-test interaction/simple-effect rule.
The frozen 6/8 continuation threshold is therefore missed by a wide margin.
High-load ALOHA/N10 contexts also expose 83--100 observed safety failures per
100 runs. Reverse asymmetry makes the CSMA RMSE route sign adverse and separates
ALOHA RMSE benefit from offered-airtime cost.

The formal base-cell result remains valid, but configured MAC type alone is
rejected as a general selector over the declared envelope. The frozen verdict
is `DO_NOT_PROCEED_WITH_GENERAL_SELECTOR`; hardware procurement and automatic
policy-sensitivity expansion stop here. Full results are in
`docs/EXP17_OPERATING_ENVELOPE_RESULTS.md`.

### EXP18A--A4 — Context-aware method development

**Completed with one preregistration-eligible construction:** EXP18A v1 fails
2/6 development gates because its busy-based feasibility proxy never blocks
and its N10 ALOHA collision-rate gate misses. EXP18A2 replaces that proxy with
an analytical per-node service screen and passes its formal gate, but still
emits excessive standalone ACK under feasible CSMA. EXP18A3 adds a
parameter-free freshness-headroom term and fails the required exact piggyback
route. No further score coefficient or threshold is fitted.

EXP18A4 removes the failed marginal-value heuristic. It uses a closed mapping:
screen-negative cells and feasible CSMA use piggyback-only; feasible ALOHA uses
the existing adaptive route. Run `2026-08-31_125544` completes 400/400 rows,
passes 14/14 integrity and 6/6 development gates, and exactly aliases its
declared fixed route on all 400 rows and 17 registered fields. This permits a
fresh-seed preregistration only. It does not establish route optimality: in the
feasible N5 Moderate ALOHA development cell, frame-aware piggyback remains
better than the selected adaptive route on mean RMSE and offered utilization.
Full results are in `docs/EXP18A4_CAPACITY_GATED_SELECTOR_RESULTS.md`.

### EXP18B — Capacity-screen and abstention holdout

**Completed within its registered scope, but the candidate is not promoted:**
run `2026-08-31_152137` contains all 8,000 frozen simulations, passes 21/21
integrity gates with zero divergence/protocol violations and exact 2,000/2,000
candidate/reference route aliases. All 9/9 Holm-adjusted tests pass: five
screen-positive mean-service tests, two N5 Stressed bg0 ALOHA abstention tests,
and two bundled N10 ALOHA candidate-versus-legacy resource tests.

The mandatory post-holdout scientific audit nevertheless stops the method as a
submission candidate. Frame-aware piggyback dominates adaptive standalone
feedback in all 3/3 feasible ALOHA contexts, so the candidate chooses the wrong
resolved route there. The registered N10 contrast also changes both access and
feedback route; clean access isolation is only descriptive. The capacity
screen is retained as a sufficient gate with zero cell-mean false positives
and one conservative false negative. Full interpretation is in
`docs/POST_EXP18B_SCIENTIFIC_AUDIT.md`.

### EXP19 — Service-aware semantic admission/scheduling

**EXP19A completed with a negative semantic-promotion verdict:** run
`2026-08-31_175039` contains all 1,620 development trajectories and passes
18/18 integrity gates with zero protocol violations. Both oracles improve the
N5 Stressed boundary and differ materially from FIFO, but neither satisfies
the N10 failure-repair gate without a mean offered-load increase. Periodic TDMA
12.5 Hz also dominates the urgency oracle at the registered boundary. The
frozen result is `NO_SERVICE_SCHEDULING_HEADROOM` (3/5); EXP19B is prohibited.

The post-hoc mechanism audit refines, but does not rewrite, that result.
Collision-free round robin produces large control gains and removes all 17/30
and 30/30 N10 failures; semantic priority adds only smaller incremental gains
and does not clear the periodic frontier. Scheduled access is retained, while
receiver-truth semantic max-weight is retired as the primary novelty. Full
results are in `docs/EXP19A_ORACLE_SERVICE_RESULTS.md`. No manuscript or
policy-hardware claim is permitted.

### EXP20 — Prior-art baseline closure

**EXP20A completed and stops the Causal-trigger candidate branch.** The valid
canonical artifact is
`results/exp20a_native_protocol_correction/2026-09-01_005821`; it combines the
unchanged 2,520-row formation panel with a corrected 1,800-row native DELTA
panel. Parent integrity is 13/13 and correction integrity is 7/7. The verdict
is `PRIOR_ART_EXPLAINS_FRONTIER`, so EXP20B, manuscript promotion and policy
hardware promotion are prohibited.

Periodic TDMA 8.333 and 10 Hz dominate the current frame-piggyback method at
the N5-Stressed boundary and remove all N10-Moderate safety failures while
using less charged utilization. The native panel separately supports a
typical paired penalty from delayed/lossy private feedback in 6/6 registered
cells, but public DELTA has a rare hot-start/collision-resolution heavy tail;
median, tail and paired-direction results must accompany any mean result.

The next research pivot is robust distributed scheduled access under explicit
reservation overhead, hidden terminals, topology change and clock error—not a
new ACK/AoI trigger. Full interpretation and the native supersession rule are
in `docs/EXP20A_RESULTS_AND_DECISION_2026-09-01.md`.

### EXP21 — Distributed scheduling reality check

**EXP21A completed with a fragile-path verdict.** The canonical run is
`results/exp21a_distributed_scheduling_reality_check/2026-09-01_030941`:
1,680 retained trajectories and 15/15 integrity gates.  The registered
Aydin-inspired distributed-reservation projection dominates the current method
in both nominal cells and stays within the registered ideal-TDMA gap, so the
EXP20 scheduling result is not merely a nominal centralized-scheduler artifact.

The approach is not promotable: it retains safety and mean RMSE in only 1/5
single-fault cells, nominal convergence is 0.833 rather than 0.90, and churn
recovery is 0.333 rather than 0.90.  Clock, hidden-control and churn mechanisms
must be repaired and re-falsified in a new development study before fresh-seed
confirmation.  EXP21A authorizes neither hardware procurement nor a manuscript
claim.  Full results and model boundaries are in
`docs/EXP21A_DISTRIBUTED_SCHEDULING_RESULTS_2026-09-01.md`.

### EXP21B — Continuous-time timing-model validity

**Completed and valid for integration:** run `2026-09-01_040346` contains all
1,600 frozen timing rows and passes 11/11 gates.  The exact local-clock
equation, physical 3.072-ms DATA airtime, half-open collision geometry and
finite-horizon guard certificate close numerically.  All 800 rows at or above
the sufficient guard are collision-free; below-bound arms provide collision
witnesses.  The maximum clock-equation residual is `1.78e-15 s`.

This result replaces the EXP21A 1-ms phase-quantized clock abstraction for all
future scheduling work.  It is strictly a timing-model certificate, not a
formation or protocol-performance claim.  Full results are in
`docs/EXP21B_CONTINUOUS_TIME_MAC_VALIDITY_RESULTS_2026-09-01.md`.

### EXP21C — Closed-loop timing integration

**Completed and valid for reservation integration:** run
`2026-09-01_044850` contains all 240 trajectories and passes 15/15 gates.  The
continuous safe-guard arm has zero collisions and zero failures in N5 Stressed
and N10 Moderate, with mean RMSE 0.082905 m and 0.102838 m.  The paired
unguarded-clock arm activates 99,752 collision frames and fails 60/60 runs.

The clock failure is therefore repairable when a valid common assignment
exists.  The active research bottleneck is no longer the continuous timing
kernel: it is causal distributed schedule acquisition, consistency, collision
repair and fast rejoin when control messages themselves contend and may be
hidden or lost.  Full results are in
`docs/EXP21C_CLOSED_LOOP_TIMING_INTEGRATION_RESULTS_2026-09-01.md`.

### Post-EXP21 scheduling-mechanism audit

The primary-source update through 2026-09-01 identifies D-ART/D-STR as the
nearest periodic peer-broadcast baseline and a 2026 control-certified UAV
allocation preprint as a direct boundary on broad novelty wording.  The next
step is therefore not a new scheduler search.  EXP21D must first implement and
falsify native prior-art control mechanisms with their frames contending on
the continuous event timeline.

The remaining scoped question is leader-free schedule acquisition, validity,
fallback and recovery under lossy/hidden control, bounded local-clock error,
and non-rigid topology, evaluated by closed-loop formation and charged
airtime.  Individual primitives such as NACK, reception records, sequence
numbers, relocation, dynamic frames, AoI/VoI priority and guard intervals are
not novel.  Full audit and mechanism matrix are in
`docs/POST_EXP21_SCHEDULING_MECHANISM_AUDIT_2026-09-01.md` and
`docs/POST_EXP21_SCHEDULING_MECHANISM_MATRIX.csv`.

### EXP21D-K — D-STR kernel conformance

**Completed and valid for closed-loop baseline integration:** accepted v3 run
`2026-09-01_070545` contains all 800 fresh-seed rows and passes 17/17 gates.
All 200 source-native rows acquire a Resolved, physically valid schedule by
frame 200 and converge without a globally unused slot by frame 1000. Two
invalid development runs remain retained and are not rescored.

The boundary projections are deliberately negative: 5% DATA-beacon erasure
leaves only 48/100 (`N=5`) and 32/100 (`N=10`) terminal rows physically valid;
local-only management reach gives zero frame agreement and zero convergence
at both sizes. Native local state-loss/rejoin recovers in all rows. These are
mechanism projections outside the D-STR source assumptions, not attributed
claims about the published protocol.

The next authorized study is EXP21D-CL: compose D-STR acquisition and all five
management slots with the EXP21B/C continuous timing layer and actual
closed-loop estimator/controller deliveries under common-PHY accounting. A
new scheduler is still not authorized. Full results are in
`docs/EXP21D_DSTR_KERNEL_CONFORMANCE_RESULTS_2026-09-01.md`.

### EXP21D-CL — D-STR closed-loop integration

**Completed and valid for boundary continuation:** accepted v3 run
`2026-09-01_080135` contains all 180 paired trajectories and passes 17/17
integration gates. Kernel and event engine share the exact pin-augmented
physical graph, every DATA/control attempt is consumed causally, all collision
witnesses and recipient/airtime accounts close, and no row skips a D-STR
opportunity or violates a protocol invariant.

Native D-STR improves RMSE by 41.35% (N5) and 45.46% (N10) against periodic
static TDMA at 8.333 Hz, but total offered utilization is 3.78 and 3.64 times
the periodic reference. Relative to an oracle-warm D-STR coloring, native N10
is 8.21% worse in RMSE, 12.83% worse in AoI and 20.47% higher in offered load.
Mean management-only utilization is 0.066 at N5 and 0.299 at N10; three N10
rows exceed offered utilization one although mean busy-union utilization is
0.600. This is a cost/freshness scaling boundary, not a superiority claim.

The next authorized step is the frozen EXP21D Stage-C boundary continuation
under DATA-beacon erasure, restricted management visibility and state-loss/
rejoin. A new method remains closed until the failure mechanism is identified.
Full results and the retained invalid v1/v2 histories are in
`docs/EXP21D_CLOSED_LOOP_INTEGRATION_RESULTS_2026-09-01.md`.

### EXP21D-B — D-STR boundary continuation

**Completed and valid for clock composition:** accepted run
`2026-09-01_104515` contains all 360 fresh-seed trajectories and passes 16/16
integrity gates. At 5% DATA-beacon erasure, native D-STR retains terminal
resolution in only 17/30 N5 and 13/30 N10 runs. Relative to an oracle-warm
schedule under the same erasures, native RMSE/AoI penalties are 10.72%/20.35%
at N5 and 31.60%/46.30% at N10.

Restricted management reach produces zero physically composable rows: local
frame lengths disagree in all 60 runs, with approximately 1,332 false-Resolved
node-frames per cell. Those controller outcomes are retained but excluded from
performance inference. In contrast, local state-loss/rejoin recovers in every
run within at most five frames at N5 and nine at N10, so rejoin is not the
dominant gap.

Reporting Amendment 03 corrected warm-reference terminal bookkeeping without
rerunning simulation or changing any effect, safety, composability or verdict.
The next authorized test composes native D-STR with the certified bounded
local-clock model. If the finite-horizon guard closes that boundary, a new
candidate may target explicit schedule validity/version, evidence repair and
safe fallback rather than generic rejoin logic. Full results are in
`docs/EXP21D_BOUNDARY_RESULTS_2026-09-01.md`.

### EXP21D-C — D-STR affine-clock composition

**Completed and valid for candidate design:** accepted run
`2026-09-01_114737` contains all 180 fresh-seed trajectories and passes 17/17
gates. A single affine clock epoch over the full 12-second mission is protected
by the exact finite-horizon guard `1.460058 ms`; no unmodelled periodic
synchronization is assumed. All schedule equations, logical-opportunity hashes,
physical outcome masks and airtime accounts close, with zero skipped attempts,
cross-plane overlaps, invariant violations or safety failures.

Relative to mission-guard zero clock, affine clock changes offered load and
goodput by exactly zero. RMSE changes only +0.0073% at N5 and +0.0318% at N10.
Clock skew increases busy-union utilization but does not change the service
outcome. The timing boundary is therefore closed under the stated sufficient
guard.

The conservative mission guard costs roughly 20% offered load/goodput capacity
relative to the uncertified short guard and increases RMSE by 8.81% at N5 and
10.54% at N10. This cost must remain visible; a shorter reset horizon is valid
only if its synchronization traffic and failure semantics are explicitly
modelled.

Candidate design is now authorized strictly for the residual EXP21D-B gap:
explicit schedule epoch/version consistency, receiver-verifiable evidence
repair, and safe fallback when a common certificate cannot be established.
Method promotion and submission claims remain closed. Full results are in
`docs/EXP21D_CLOCK_COMPOSITION_RESULTS_2026-09-01.md`.

### EXP22D — retained invalid continuous integration

EXP22D run `2026-09-01_173320` completed all 120 paired trajectories but is
retained invalid at 14/17 gates. Lease safety, clock composition, management
accounting, cross-plane separation and closed-loop invariants all passed. The
failure is narrower: 46 empty-queue skips are exactly 23 logical cases,
duplicated across clock arms, where one invalid node is selected in both
fallback minislots before a new latest state exists. Precomputed saturated-
kernel collision masks are then no longer the physical event outcomes.

No gate is relaxed and no performance inference is promoted. EXP22E freezes a
single structural repair: at most one fallback attempt per node per ELCS
frame, using the first eligible frozen draw. It must pass the complete kernel
matrix and then a disjoint fresh-seed closed-loop rerun before robustness is
opened. Full diagnosis is in
`docs/EXP22D_INVALID_CLOSED_LOOP_RESULTS_2026-09-01.md`.

### EXP22E — queue-compatible fallback repair

The structural repair passes both required fresh-seed stages. Kernel run
`2026-09-01_174154` contains 1,400/1,400 rows and passes 17/17 gates, including
an observed maximum of one fallback attempt per node/frame. All certification,
GRANT-loss, state-loss and forced-reconfiguration gates remain intact; 400
uncertified boundary terminals and 23,262 fallback collision frames remain
visible.

Closed-loop run `2026-09-01_175319` contains 120/120 rows and passes 17/17
unchanged integration gates: zero skips, exact outcome/collision replay, zero
cross-plane overlap and exact control/DATA airtime accounting. Offered load is
0.351 at N5 and 0.377 at N10, of which management alone is 0.081 and 0.092.
This is a valid operating point, not a superiority result.

The next authorized study is a direct common-PHY feasibility comparison
against a full-mission guarded periodic static-TDMA rate frontier and native
D-STR on paired seeds. If any periodic point dominates ELCS-F in both RMSE and
offered utilization, the current candidate must return to design rather than
proceed to robustness/holdout. Full results are in
`docs/EXP22E_ELCS_FALLBACK_REPAIR_KERNEL_RESULTS_2026-09-01.md` and
`docs/EXP22E_ELCS_CLOSED_LOOP_REPAIR_RESULTS_2026-09-01.md`.

### EXP22F/EXP22G — direct feasibility and targeted closure

EXP22F run `2026-09-01_180435` passes 14/14 integrity gates over 600 rows and
finds no two-axis 1% periodic dominance on its coarse rate grid. It also shows
that D-STR is more accurate but costs 9.62% more at N5 and 101% more at N10.
The coarse grid leaves an interpolation gap, so robustness is not opened.

EXP22G run `2026-09-01_182938` closes that gap with analytically cost-matched
rates on 180 disjoint fresh-seed rows and passes 10/10 integrity gates. Its
2%-below-cost periodic arm confidence-supported epsilon-dominates ELCS-F in
both cells; N5 also meets strict two-axis 1% dominance. The current candidate
returns to design. Full results are in
`docs/EXP22F_DIRECT_FEASIBILITY_RESULTS_2026-09-01.md` and
`docs/EXP22G_TARGETED_FRONTIER_RESULTS_2026-09-01.md`.

EXP22H is the only authorized continuation: separate sparse discovery beacons
from explicit event-driven renewal requests, and prohibit GRANT emission from
discovery-only STATUS. It retains every lease/fence/fallback safety rule and
must pass the complete kernel matrix plus an analytical control-attempt bound
before any new closed-loop comparison.

EXP22H run `2026-09-01_191307` is retained invalid at 19/20 gates. Its only
failure is a reconfiguration-specific STATUS accounting/order defect; all
safety, recovery and analytical overhead gates pass. EXP22I repairs the
emission order and must repeat the complete matrix on disjoint seeds. Details
are in `docs/EXP22H_INVALID_EVENT_DRIVEN_RESULTS_2026-09-01.md`.

### EXP22-K/EXP22B/EXP22C — Edge-leased certification kernel

The working candidate is **ELCS-F**, an edge-leased schedule-validity layer
with deterministic edge ownership, client-side activation, lease fencing and
a disjoint contention fallback. Its mathematical invariant and bounded-
fallback model are in `docs/EXP22_EDGE_LEASE_CANDIDATE_DESIGN.md`.

Two invalid studies are retained. EXP22-K v1 (`2026-09-01_122201`, 13/15
gates) exposed zero-loss lease-refresh outages caused by random control-slot
collisions and a missing cascading recolor. EXP22B (`2026-09-01_165537`, 15/16
gates) closed both protocol defects but used a reconfiguration stimulus that
activated recolor only in N5, not N10; its activation gate was not relaxed.

**Kernel accepted for continuous integration:** EXP22C run
`2026-09-01_170847` contains all 1,400 disjoint fresh-seed rows and passes
16/16 gates. It has zero scheduled collisions, false-valid edge-frames and
owner-lock violations; 200/200 zero-loss rows certify, 200/200 state-loss rows
recover, and 200/200 forced color conflicts repair after their fence with 600
automatic recolors. DATA erasure leaves schedule-state hashes unchanged.

Permanent directed-GRANT loss and missing conflict-edge management visibility
correctly leave 400 terminal rows uncertified. Their fallback produces 26,694
collision frames, so closed-loop adequacy remains unproven. The next authorized
step is exact common-PHY continuous integration of STATUS, GRANT, fallback and
scheduled DATA with the full-mission clock guard. Direct D-STR, D-ART and
6P/MSF-inspired comparisons remain mandatory before promotion. Full results
are in `docs/EXP22C_ELCS_KERNEL_RESULTS_2026-09-01.md`.

### EXP15 — Trace/HIL validation (deferred by EXP17 gate)

- Nếu một policy mới vượt independent envelope gate, replay measured
  PDR/RTT/channel-busy traces trước.
- Sau đó mới thực hiện hai-node radio test đo frame size, airtime, ACK
  aggregation và energy.
- Chỉ mở rộng tới 3--5 node sau khi trace replay giữ được qualitative
  mechanism; flight không phải gate gần nhất.
- Hardware mặc định, BOM theo giai đoạn và procurement gates nằm tại
  `docs/STUDY2_HARDWARE_BOM.md`; chưa khóa onboard packaging trước radio-bench
  gate.

**Software boundary completed:** `docs/EXP15_TRACE_REPLAY_CONTRACT.md` defines
schema `MEASURED-SHARED-MEDIUM-v1` and the additive interfaces
`buildMeasuredSharedMediumTrace` / `validateMeasuredSharedMediumTrace`. The
contract requires absolute-time, policy-independent DATA/ACK loss-probability
tensors and external occupancy; it explicitly rejects replaying a
policy-conditioned packet log as a counterfactual channel. Contract tests
cover deterministic replay, DATA/ACK path separation, piggyback semantics,
measured busy override, legacy-trace inertness and hash tamper detection.
Actual EXP15 evidence remains pending measured input; no synthetic test is
reported as hardware validation. Sau verdict EXP17
`DO_NOT_PROCEED_WITH_GENERAL_SELECTOR`, interface này được giữ lại nhưng không
tự động kích hoạt procurement hay measurement cho MAC-only selector hiện tại.

## 7. Track lý thuyết cho TCNS

Track lý thuyết dùng double-integrator formation subsystem, không cố chứng minh
trực tiếp cho toàn bộ 6-DOF implementation.

Notation, assumptions, theorem candidates, proofs và code-level certificate
được duy trì tại `docs/STUDY2_MATHEMATICAL_FOUNDATION.md`; bản LaTeX độc lập ở
`paper/study2/study2_theory_draft.tex`.

1. **Causal conservatism:** với ACK chỉ phát sau accepted DATA và không rollback,
   chứng minh `ackedGenTime <= receiverGenTime`, do đó
   `estimatedAoI >= trueAoI` tại mọi thời điểm.
2. **Probabilistic age tail:** dưới max-silence, bounded service delay và success
   probability có lower bound, suy ra tail bound của inter-success time/AoI.
   Không tuyên bố deterministic AoI bound dưới i.i.d. loss vì chuỗi loss có thể
   dài tùy ý.
3. **State-error bound:** với bounded state derivative, nối receiver AoI tới
   neighbor-state error.
4. **Formation ISS/practical bound:** xem stale neighbor state là disturbance
   của nominal exponentially stable formation dynamics; suy ra ultimate
   formation-error bound theo age/state-error bound.
5. **Protocol boundedness:** chứng minh memory `O(|E|+NW)` và transmission
   opportunity bị chặn bởi MAC/refractory construction.

Với primary `N=5` fully-conflicting bound, p-persistent access mặc định cho
EXP13 là giá trị giải tích `p=1/5`, không chọn sau khi nhìn performance. Các
giá trị khác quanh nó là sensitivity arms, không thay primary sau holdout.

Simulation kiểm tra bound tightness nhưng không được dùng thay proof.

## 8. Success criteria của Study 2

Study 2 thành công về khoa học nếu trả lời được các câu sau, kể cả khi đáp án là
negative:

- Broadcast aggregation có loại được cost reversal của v3 khi tính airtime thật
  và collision hay không?
- Piggyback/aggregated ACK giảm feedback load tới mức nào và đổi receiver-age
  uncertainty ra sao?
- Worst-neighbor semantic aggregation có gây “straggler domination” không?
- Region offered-load nào giữ closed-loop safe; ở đâu congestion collapse xuất
  hiện?
- Lợi ích còn tồn tại trước tuned periodic, AoI-only, AoCI-inspired và delayed-
  ACK belief frontiers hay không?
- Conservative AoI/formation bound dự đoán được failure boundary quan sát hay
  chỉ quá lỏng?

Không định nghĩa thành công là “Causal-Broadcast phải thắng”. Một kết quả cho
thấy ACK-confirmed adaptivity không đáng chi phí trên broadcast swarm cũng là
một kết luận comm/control có giá trị nếu model, baseline và inference đủ mạnh.
