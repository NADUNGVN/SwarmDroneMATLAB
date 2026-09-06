# Tổng quan nghiên cứu và định nghĩa đích IEEE IoT-J

**Ngày chốt bằng chứng:** 06-09-2026  
**Kho mã:** `D:\Research\Drone\SwarmDroneMATLAB`  
**Đích gần nhất:** bài báo nghiên cứu đầy đủ về communication/networking cho
IEEE Internet of Things Journal (IoT-J), hoặc venue Transactions tương đương  
**Phạm vi tìm kiếm:** nguồn chính thức của IEEE và các công trình gốc được tìm
thấy tới ngày chốt bằng chứng

## 1. Kết luận điều hành

Nghiên cứu hiện tại **đã vượt giai đoạn tìm ý tưởng** và đã hình thành một cơ
chế ứng viên có bản sắc riêng:

> một lớp xác nhận tính hợp lệ nhất quán (coherence-certified validity layer)
> cho lịch truyền phân tán của UAV swarm, trong đó tuổi thông tin được xác nhận
> nhân quả được đổi thành miền bất định chuyển động, miền này sinh ra đồ thị
> xung đột tương lai, còn lịch mới chỉ được kích hoạt sau khi một giao dịch
> witness đa bên được chuyển tiếp và xác nhận trên cùng shared PHY.

Tuy nhiên, nghiên cứu **chưa phải kết quả sẵn sàng nộp**. Bằng chứng mới nhất
EXP23AQ xác nhận state machine quản lý đa-hop và fail-silent semantics, nhưng
chính verdict của thí nghiệm vẫn để các cờ sau ở `false`:

- closed-loop management relaying;
- repeated online renewal;
- fresh-seed system evidence;
- broad robustness;
- submission claim.

Nói ngắn gọn: **chúng ta đã có candidate mechanism và nhiều viên gạch đúng;
chúng ta chưa có end-to-end journal result**.

Deep research cũng làm hẹp novelty perimeter. Tới 2026, literature đã có TDMA
phân tán, reservation chống hidden terminal, lịch UAV tự tổ chức, dynamic slot
allocation, hybrid CSMA/TDMA, DRL phân tán, safe random access, AoI dưới
feedback không hoàn hảo và ACK-based distributed belief. Vì vậy, không được
tuyên bố novelty ở bất kỳ thành phần riêng lẻ nào trong số đó. Khoảng trống còn
có thể bảo vệ là **chuỗi kết hợp nhân quả từ receiver-confirmed information tới
schedule-validity certificate cho closed-loop peer swarm**, kèm routed
management và exact common-PHY accounting.

## 2. “Đạt mục tiêu” được định nghĩa là gì?

### 2.1 Điều IEEE thực sự yêu cầu

IoT-J công bố các đóng góp mới và đáng kể về kiến trúc IoT, enabling
technologies, communication/networking protocols, services và applications.
Hướng hiện tại nằm đúng scope protocol/networking và sensing–communication–
control co-design. IEEE nói reviewer đánh giá scope, novelty, validity, cách
phân tích dữ liệu, clarity, compliance và mức advancement; checklist reviewer
còn hỏi literature có đầy đủ, thiết kế/phương pháp có sound, kết quả có thể tái
lập và conclusion có được dữ liệu hỗ trợ hay không.

Nguồn chính thức không đưa ra công thức kiểu “vượt X% là được nhận”. Do đó,
checklist ở dưới là **operational definition của chương trình nghiên cứu**, được
xây từ tiêu chí IEEE và rủi ro kỹ thuật thực tế; nó không phải quy định chính
thức hay bảo đảm acceptance.

Nguồn: [IoT-J Guidelines for Authors](https://ieee-iotj.org/guidelines-for-authors/),
[IEEE peer-review criteria](https://journals.ieeeauthorcenter.ieee.org/submit-your-article-for-peer-review/about-the-peer-review-process/),
[IEEE reviewer checklist](https://journals.ieeeauthorcenter.ieee.org/submit-your-article-for-peer-review/become-an-ieee-reviewer/),
và [IoT-J call về AoI/data semantics và communication–control co-design](https://ieee-iotj.org/wp-content/uploads/2020/03/CFP_AoI_IoTJ.pdf).

### 2.2 Định nghĩa đóng góp khoa học thành công

Mục tiêu khoa học được xem là đạt khi bằng chứng hỗ trợ được một claim có dạng:

> Dưới một tập giả thiết công khai, lớp coherence certification đề xuất ngăn
> lịch cũ/mới không nhất quán tạo ra scheduled receiver conflict; giao dịch cập
> nhật lịch đa-hop đạt reliability/time certificate đã đăng ký; và trong một
> operating envelope có ý nghĩa, cơ chế cung cấp một safety–control–airtime
> frontier mà các baseline gần nhất không đạt được với cùng information set,
> PHY, traffic và tuning budget.

Claim này không yêu cầu phương pháp thắng mọi baseline ở mọi cell. Nó yêu cầu:

1. có một lợi ích phân biệt được và có ý nghĩa, không chỉ code correctness;
2. không bị tuned periodic hoặc prior-art baseline epsilon-dominate trên toàn
   vùng được tuyên bố;
3. nếu ưu thế là safety/certification, chi phí để mua ưu thế đó phải được báo
   đầy đủ và so ở operating point tương đương;
4. ngoài operating envelope phải công khai refusal, degradation và negative
   result thay vì mở rộng claim.

### 2.3 Định nghĩa “submission-ready”

Chỉ gọi là sẵn sàng nộp khi **tất cả tám gate** sau đóng đồng thời:

| Gate | Điều kiện pass | Trạng thái 06-09-2026 |
|---|---|---|
| G1 — Scope/novelty | Claim hẹp, literature map cập nhật tới ngày nộp, không nhận vơ TDMA/AoI/ACK/mobility adaptation | **Một phần** |
| G2 — Formal contract | Assumptions, causal information set, safety theorem, reliability/time bound, complexity và failure boundary thống nhất | **Một phần** |
| G3 — Execution fidelity | DATA và mọi management hop/retry/recipient/collision/byte/airtime dùng cùng event timeline và replay chính xác | **Pass cho management transaction; chưa pass end-to-end plant** |
| G4 — Closed-loop value | Chính routed schedule điều khiển DATA delivery và plant, không dùng logical-delivery shortcut; safety và performance được đo | **Chưa pass** |
| G5 — Renewal/robustness | Nhiều lần renewal/migration; topology, direction, scale, burst/correlated loss, load và clock nằm trong matrix đã định | **Chưa pass** |
| G6 — Prior-art comparison | Ít nhất các baseline gần nhất được port công bằng, tuned trên development và so bằng fresh paired evidence | **Chưa pass cho candidate hiện tại** |
| G7 — Confirmatory inference | Policy/config/claims freeze trước holdout; seed tách biệt; power/CI/multiplicity/sensitivity/boundary đầy đủ | **Chưa pass cho end-to-end candidate** |
| G8 — Artifact/manuscript | One-command reproduction, manifest/hash/config, claim–evidence ledger và manuscript không vượt quá dữ liệu | **Một phần** |

Điều kiện go/no-go cuối cùng là: G1–G8 đều pass và một harsh internal review
không tìm thấy logical shortcut, unfair baseline, hidden cost hoặc claim vượt
scope. Acceptance vẫn là quyết định biên tập bên ngoài; “đạt mục tiêu nghiên
cứu” ở đây nghĩa là **đủ mạnh và đủ sạch để nộp**, không phải hứa chắc được nhận.

## 3. Kiến thức đã tích lũy qua toàn bộ chương trình

### 3.1 Study 1: ACK nhân quả và AoI-aware event trigger

Study 1 tạo ra nền tảng khoa học tốt:

- phân biệt true receiver AoI với sender-estimated confirmed AoI;
- giữ causality: ACK chỉ cập nhật knowledge sau accepted DATA và không rollback;
- tách new information khỏi refresh bằng cooldown khác nhau;
- dùng paired seeds, confidence intervals và giữ negative results;
- cho thấy kết luận có thể đảo khi đổi từ directed-link count sang broadcast /
  airtime accounting.

Nhưng Study 1 cũng loại bỏ một hướng claim: Causal-v3 không phải cải tiến phổ
quát. Nó thua P10 ở Clean theo chính dominance rule và lợi ích suy yếu dưới
broadcast accounting. Kết quả này trở thành nền tảng và boundary, không phải
claim trung tâm hiện tại.

### 3.2 Study 2 giai đoạn đầu: shared medium và feedback selection

Nhánh Causal-Broadcast đã đưa collision, queueing, DATA/ACK airtime, piggyback
và standalone feedback lên shared event timeline. Các EXP12–EXP20 xác nhận hạ
tầng và nhiều cơ chế cục bộ, đồng thời bác bỏ các selector quá rộng:

- MAC-aware selector chỉ có lợi trong vùng hẹp;
- một số periodic point và prior-art projection dominate candidate;
- kết quả không tổng quát sang N lớn hoặc access mechanism khác;
- ACK sớm hơn không tự động nghĩa là receiver state mới hơn hoặc plant tốt hơn,
  vì ACK còn đổi các DATA decision về sau.

Giá trị lớn nhất của giai đoạn này là đã loại bỏ câu chuyện yếu “chọn ACK route
thông minh” trước khi viết thành bài.

### 3.3 Pivot sang distributed scheduling validity

EXP21–EXP22 cho thấy vấn đề cốt lõi dưới shared PHY không chỉ là trigger DATA,
mà là lịch phân tán có còn hợp lệ khi các node có local view khác nhau hay
không. D-STR và ELCS-F đã giúp nhận diện ba failure mode:

1. management erasure làm các node false-resolved hoặc giữ frame khác nhau;
2. limited visibility làm local schedule không physically composable;
3. fail-silent bảo vệ collision safety nhưng có thể phá closed-loop safety nếu
   DATA service biến mất quá lâu.

Periodic frontier sau đó epsilon-dominate ELCS-F ở các cost-matched point. Điều
này buộc nghiên cứu pivot tiếp: novelty không nằm ở “cấp lease” hay “distributed
reservation”, mà ở certificate về **coherence của schedule version và physical
validity**.

### 3.4 Candidate hiện tại: coherence-certified validity layer

Kiến trúc hiện tại gồm sáu mắt xích:

1. **Causal knowledge:** receiver-confirmed age không bao giờ lạc quan hơn true
   accepted generation time theo protocol contract.
2. **State uncertainty:** bounded velocity/acceleration đổi age thành reachable
   state tube.
3. **Future conflict:** các tube sinh potential physical-interference
   supergraph; broadcast receiver lifting đổi nó thành sender-conflict graph.
4. **Versioned witness closure:** schedule tuple, graph digest và horizon được
   khóa bằng PREPARE–QUIESCENT–EVIDENCE–RESPONSE–COMMIT; thiếu positive evidence
   thì node không active.
5. **Self-revocation/protected service:** node dừng scheduled use trước khi rời
   tube; fail-silent schedule acquisition không được phép đồng nghĩa với mất
   mọi state service của plant.
6. **Common-PHY accounting:** management route, repetition, retry, DATA,
   receiver outcome, clock guard, bytes và airtime phải nằm trên một event
   timeline.

Đây là contribution candidate. Nó **không** phải một TDMA allocator mới nói
chung, cũng không phải một AoI scheduler mới nói chung.

## 4. Tiến độ thực tế và ý nghĩa của các experiment gần nhất

### 4.1 Những lớp đã được xác nhận

- **EXP23M:** reachable-tube/supergraph geometry kernel; 600/600 rows, 16/16
  gates. Xác nhận causal horizon contraction/refusal và self-revocation, nhưng
  chỉ ở geometry level.
- **EXP23S/T/U:** packetized revocation và dynamic common-PHY envelope. Safety
  không phụ thuộc REVOKE delivery; permanent response blackout bộc lộ outage và
  cost boundary.
- **EXP23W:** fixed-graph fast reactivation, 800/800 trajectories và 21/21
  gates. Cải thiện RMSE so với đợi old fence, nhưng chưa thay graph.
- **EXP23X/Y:** local union-graph migration kernel/common-PHY. Chứng minh được
  migration mechanics; plant integration tiếp theo phát hiện failure thật.
- **EXP23Z:** invalid 15/16. Permanent RESPONSE blackout giữ schedule fail-silent
  nhưng làm UAV mất state service và vượt separation threshold. Negative result
  này dẫn tới protected emergency DATA.
- **EXP23AA/AB:** protected service và bounded retry/backoff feasible ở
  development; đóng outage mechanism nhưng chưa phải confirmation.
- **EXP23AC:** bác bỏ giả thiết “chỉ migrate một sender”; receiver lifting cho
  thấy phải migrate toàn dependency closure.
- **EXP23AD/AE:** receiver-lifted dependency closure và common-PHY schedule được
  xác nhận ở một online migration transaction.
- **EXP23AI:** 300/300 fresh rows, 28/28 gates. Xác nhận một causal online
  receiver-lifted transaction, protected service, affine clocks và exact
  integer accounting. Nhưng management reach lúc đó còn là full logical
  matrix.
- **EXP23AN/AO:** xác nhận routing primitive và multi-origin routed transaction;
  tại `r=4`, analytical transaction-failure upper bound là
  `9.095543974e-4`, conservative duration `5.034618441 s < 6.5 s`.
- **EXP23AQ:** 500/500 normal transactions hoàn tất, 19/19 gates; ba blackout
  fixtures đều fail safe; continuous builder replay đúng state hash,
  attempts/bytes/airtime. Đây là mốc hiện tại.

### 4.2 EXP23AQ đã chứng minh gì — và chưa chứng minh gì

Đã chứng minh trong retained N=10 geometry và mô hình erasure đã đăng ký:

- multi-origin management packets có thể được route causal qua nhiều hop;
- phase precedence và state isolation đúng;
- không có receiver collision, cross-packet write, forbidden read hay premature
  activation trong registered traces;
- reliability certificate và time budget đồng thời khả thi;
- PREPARE, RESPONSE và COMMIT blackout đều giữ đúng fail-silent boundary.

Chưa chứng minh:

- routed transaction thực sự điều khiển DATA service và plant trajectory;
- nhiều renewal liên tiếp trong cùng mission;
- candidate còn hoạt động dưới burst/correlated loss, external load, nhiều
  topology/command/scale;
- safety–control–airtime frontier thắng hoặc không bị dominate bởi prior art;
- final fresh holdout sau khi method và claims được freeze.

Vì vậy, điểm hiện tại chính xác là **protocol-state confirmation**, chưa phải
**system-level efficacy confirmation**.

## 5. Literature review theo dòng vấn đề

### Hướng A — Distributed reservation giải collision và hidden terminal

FPRP đã làm localized five-phase reservation trong vùng hai hop, hoàn toàn phân
tán và hướng tới broadcast scheduling không hidden terminal. DTSS dùng
REQ/RES, receiver lists và blocked slots để hỗ trợ đồng thời unicast, multicast
và broadcast, đồng thời phân tích scheduling time. E-TDMA còn cập nhật lịch
phân tán theo topology/bandwidth thay đổi.

Các công trình này giải được distributed acquisition và conflict-free schedule
formation. Chúng khiến các claim “five-phase reservation”, “receiver response”,
“cumulative witness”, “hidden-terminal-free schedule” hoặc “evolutionary
update” không còn mới.

Nguồn: [FPRP](https://drum.lib.umd.edu/items/70739de1-fe55-4964-ad5c-276f5d3e5d4f),
[DTSS](https://onlinelibrary.wiley.com/doi/10.1155/2015/234143),
[E-TDMA](https://drum.lib.umd.edu/items/84d4c4f9-042e-4786-b279-c72bdc50681e).

### Hướng B — UAV/FANET MAC thích nghi mobility, topology và load

DTSA cấp slot không tuần hoàn theo communication demand trong swarm. Aydin và
cộng sự xây self-organizing STDMA với join/migration/exit và điều chỉnh slot
trước topology change. H-SATMAC là hybrid self-adaptive TDMA MAC cho large-scale
UAV ad-hoc networks. DCFG-TDMA dùng distributed coalition formation để tăng
spatial reuse. Đây là một family đã đông và tiếp tục phát triển.

Nguồn: [DTSA](https://arxiv.org/abs/2202.00919),
[Aydin et al., IEEE Access 2024](https://doi.org/10.1109/ACCESS.2024.3381859),
[H-SATMAC, IEEE IoT-J 2026](https://doi.org/10.1109/JIOT.2025.3577782),
[DCFG-TDMA 2025](https://www.mdpi.com/1099-4300/27/3/256).

Khoảng trống không phải “chưa ai thích nghi topology”. Câu hỏi còn lại là:
khi topology/state knowledge khác nhau giữa node và có packet loss, bằng chứng
nào cho phép một schedule version trở thành **safe authority cho tương lai**?

### Hướng C — Learning-based distributed access tối ưu performance/risk

MDRA-TDMA dùng DRQN và local observations để cấp lượng resource conflict-free
trong FANET động, và so trực tiếp với FPRP. OSMAR, đã xuất hiện trong IoT-J
2026, dùng safe multi-agent RL, risk-aware exclusion và overheard slot status để
giảm collision, tăng fairness và robustness.

Nguồn: [MDRA-TDMA, IEEE TVT 2026](https://ieeexplore.ieee.org/document/11298554/),
[OSMAR, IEEE IoT-J 2026](https://doi.org/10.1109/JIOT.2026.3676620).

Các bài này đặt bar rất rõ: một bài communication/FANET hiện đại phải so với
dynamic distributed access mạnh, không chỉ periodic TDMA. Candidate của chúng
ta không nên đấu bằng “tối ưu throughput tốt hơn RL”; lợi thế phải là explicit
causal certificate, interpretable failure semantics và closed-loop guarantee.

### Hướng D — AoI, delayed feedback và distributed belief

WiSwarm cho thấy application-layer AoI middleware có thể loại stale packets,
điều phối traffic và cải thiện tracking trong multi-UAV system, nhưng kiến trúc
đó là sensing UAVs tới một controller. Imperfect-feedback AoI work duy trì belief
về receiver age khi ACK/NACK có thể mất. Công trình two-way-delay 2026 tối ưu
status updating với forward/feedback Markov delay. DELTA dùng public ACK/NACK
và dynamic epistemic logic để các sensor suy luận belief của node khác trong
distributed goal-oriented random access.

Nguồn: [WiSwarm](https://www.mit.edu/~kadota/PDFs/INFOCOM_2023.pdf),
[AoI minimization với imperfect feedback](https://ieeexplore.ieee.org/document/10622227/),
[goal-oriented updating với two-way delay](https://open.metu.edu.tr/handle/11511/118846),
[DELTA](https://www.research.unipd.it/retrieve/8eb24a78-6a39-400e-92a5-cc116a7907c0/2026_TON.pdf).

Do đó, “ACK tạo belief” và “AoI ảnh hưởng access” không phải novelty. Phần khác
biệt phải là cách private, per-receiver confirmed knowledge được chuyển thành
future physical-conflict certificate và schedule activation trong peer swarm.

### Hướng E — AoI, reliability và UAV coordination ở cấp tối ưu hóa

Một preprint tháng 8-2026 đã đồng tối ưu AoI, short-packet reliability và swarm
connectivity cho UAV-assisted IoT data collection. Bài này là bài toán collection
tới fusion center chứ không phải peer schedule coherence, nhưng cho thấy claim
“joint AoI/reliability/connectivity for UAV swarm” đã quá rộng và không còn an
toàn.

Nguồn: [Bafarassat và Coleri, 2026 preprint](https://arxiv.org/abs/2608.00061).

## 6. Gap còn bảo vệ được sau deep research

Không có một paper được tìm thấy trong scoped search đồng thời thực hiện toàn bộ
chuỗi sau:

1. dùng only-causal, per-receiver confirmation để định lượng state uncertainty;
2. nâng uncertainty qua bounded motion thành future physical graph rồi receiver-
   lift thành sender-conflict supergraph;
3. bind graph digest, slot tuple, version và expiry bằng routed multi-party
   positive evidence;
4. chỉ activate/re-activate khi witness closure hợp lệ, và tự revoke trước tube
   escape;
5. giữ closed-loop state service trong certificate blackout mà không tái mở
   scheduled collision;
6. tính toàn bộ DATA và management hop/retry/recipient trên cùng PHY timeline và
   đánh giá trực tiếp bằng formation control.

Đây là **gap inference**, không phải bằng chứng tuyệt đối rằng chưa từng có bài
nào. Trước khi nộp phải lặp backward/forward citation search quanh FPRP, DTSS,
Aydin, H-SATMAC, MDRA, OSMAR, WiSwarm và DELTA; novelty wording nên dùng
“we address” hoặc “to the best of our scoped review”, không dùng “the first”
nếu chưa có systematic-review protocol.

## 7. Khoảng cách còn lại: năm work package bắt buộc

### WP1 — Routed common-PHY plant closed loop

Đưa exact EXP23AQ continuous routed schedule vào executor đang phát DATA và cập
nhật estimator/controller. Gate phải bắt được mọi shortcut giữa logical packet
và physical reception. Đây là bước kế tiếp tức thời và có giá trị thông tin cao
nhất: nếu plant không an toàn hoặc periodic dominate, candidate phải quay lại
design trước khi mở rộng matrix.

### WP2 — Repeated online renewal/migration

Một mission phải có nhiều tube expiry, command change và graph migration nối
tiếp. Kiểm tra version overlap, delayed old packets, duplicate/reordered
management, local revocation, protected service và bounded recovery. Một
transaction đúng không suy ra protocol dài hạn đúng.

### WP3 — Operating envelope và scalability

Sau khi WP1–WP2 pass, freeze cơ chế rồi quét có cấu trúc theo swarm size,
topology/degree, motion/command direction, causal-state uncertainty, burst hoặc
correlated loss, reverse asymmetry, external load và clock epoch. Mục tiêu là
vẽ vùng `certify / shorten / refuse / fail-safe`, không che failure cells.

### WP4 — Prior-art frontier và mechanism ablation

Port công bằng ít nhất:

- periodic static TDMA rate frontier;
- FPRP/DTSS-style distributed acquisition;
- một mobility-adaptive UAV scheduler như DTSA/Aydin/H-SATMAC family;
- một modern learning/risk-aware reference như MDRA hoặc OSMAR nếu có thể tái
  tạo action/information model trung thực.

DELTA hoặc delayed-feedback belief nên là semantic-access boundary, không nhất
thiết là direct TDMA replacement. Mọi baseline phải dùng cùng traffic, PHY,
receiver graph, initialization budget và development tuning budget. Ablation
phải tách hiệu quả của tube/supergraph, witness closure, version barrier,
self-revocation, protected service và routing repetition.

### WP5 — Frozen confirmatory study và artifact closure

Sau development, chốt trước primary hypotheses, practical margins, sample size,
seed partition, multiplicity procedure và allowed exclusions. Mở disjoint fresh
holdout đúng một lần. Sau đó tái tạo toàn bộ tables/figures/verdict từ một entry
point, khóa hashes/configs và đối chiếu từng câu claim với artifact.

## 8. Thứ tự quyết định hợp lý

```text
EXP23AQ: routed state machine PASS
             |
             v
WP1: routed PHY + DATA + plant
     | fail/dominated -> sửa design, chưa mở breadth
     v pass
WP2: repeated renewal/version churn
     | fail -> sửa long-horizon protocol
     v pass
WP3 + WP4: envelope/scaling + prior-art frontiers
     | không có distinct value -> thu hẹp/đổi contribution
     v pass
WP5: frozen fresh confirmation
     |
     v
G1--G8 audit -> submission-ready
```

Thứ tự này hợp lý vì WP1 kiểm tra đúng rủi ro lớn nhất còn treo với chi phí thấp
hơn việc chạy một robustness matrix lớn. Không nên mở rộng ồ ạt hoặc bắt đầu
đóng manuscript khi exact routed protocol chưa tác động lên plant.

## 9. Phán quyết hiện tại

**Mức trưởng thành:** candidate mechanism đã được nhận diện và protocol
primitives được kiểm chứng sâu; system claim chưa đóng.  
**Novelty risk:** trung bình–cao nếu diễn đạt là distributed/adaptive TDMA;
trung bình nếu khóa vào causal coherence certificate và chứng minh đủ chuỗi.  
**Evidence risk:** cao nhất ở routed plant closed loop, repeated renewal và
fair prior-art comparison.  
**Submission verdict:** `NOT_SUBMISSION_READY`.  
**Bước kế tiếp duy nhất hợp lý:** routed common-PHY plant closed-loop bằng exact
EXP23AQ state machine, trước mọi robustness sweep hay paper claim.

## 10. Giới hạn của deep research

Tìm kiếm ưu tiên IEEE pages, publisher pages, institutional repositories và
author manuscripts. Một số nội dung IEEE mới chỉ truy cập được metadata/abstract
do paywall hoặc indexing. Việc không tìm thấy exact six-link chain ở Section 6
không chứng minh global novelty. Cần chạy lại citation search ngay trước khi
freeze contribution và ngay trước ngày nộp.
