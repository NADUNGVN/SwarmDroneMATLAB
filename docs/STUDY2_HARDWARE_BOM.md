# Study 2 — Hardware default and staged BOM

**Decision date:** 2026-08-28  
**Status:** provisional hardware default; EXP12--EXP14 remain hardware-independent.  
**Primary purpose:** EXP15 trace/HIL validation of shared-medium broadcast,
contention, aggregated ACK, energy and embedded timing. This document does not
turn any simulation result into a hardware result.

## 1. Default decision

The default experimental radio is **Linux/mac80211 2.4 GHz IEEE 802.11n**. The
initial bench uses Raspberry Pi 5 4 GB nodes and an external AR9271/
`ath9k_htc` USB radio. The candidate adapter is ALFA AWUS036NHA, subject to a
one-unit procurement smoke test confirming USB ID `0cf3:9271`, IBSS/monitor
operation, frame capture and fixed transmit-rate configuration on the exact OS
image.

This choice is a measurement target, not a claim that EXP12 implements the full
IEEE 802.11 standard. EXP12--EXP14 retain p-persistent CSMA as the primary
abstract MAC and TDMA/slotted ALOHA as references. EXP15 asks whether the result
survives traces from a real CSMA/CA medium.

Primary radio mode is **IBSS/ad-hoc broadcast** so one over-the-air DATA frame
can have multiple receivers. Infrastructure mode through an AP is a secondary
reference because an AP can change forwarding and airtime semantics. Wired
Gigabit Ethernet is a separate management/logging plane; SSH, clock sync and
result collection must not add load to the experimental Wi-Fi plane.

Rationale and sources:

- Raspberry Pi 5 provides dual-band 802.11ac, Gigabit Ethernet and USB, but the
  external research radio is used for reproducible Linux driver/mode control:
  <https://www.raspberrypi.com/products/raspberry-pi-5/>.
- Linux Wireless documents IBSS, mesh and monitor support for the
  `ath9k_htc` driver; ALFA documents AR9271 support on Raspberry Pi OS and
  identifies AWUS036NHA as an AR9271 product:
  <https://wireless.docs.kernel.org/en/latest/en/users/drivers.html> and
  <https://docs.alfa.com.tw/Support/Linux/AR9271/>.

## 2. Procurement stages

### B0 — No-purchase stage: EXP12--EXP14

Use the existing workstation for simulation, preregistration and holdout. No
radio or vehicle is scientifically required. The experiment code must expose
PHY/frame timing and trace inputs so the B1 measurements can replace assumptions
without rewriting the policy.

### B1 — Three-node procurement smoke test

Buy this first. Do not order five identical radios before the candidate passes.

| Item | Qty. | Required specification | Purpose |
|---|---:|---|---|
| Raspberry Pi 5 | 3 | 4 GB RAM | sender, receiver and interferer/second sender |
| Official-class USB-C supply | 3 | 5 V, 5 A / 27 W | avoid power-induced timing faults |
| Active cooler or fan case | 3 | Pi 5 compatible | prevent thermal throttling |
| Storage | 3 | 64 GB high-endurance microSD minimum | OS, pcap and protocol logs |
| AR9271 USB Wi-Fi adapter | 3 | exact chipset/USB ID verified | experimental data plane |
| Gigabit Ethernet switch | 1 | at least 8 ports | isolated control/logging plane |
| Ethernet cables | 4 | Cat5e or better | three nodes plus workstation |
| External antennas | 3 | identical, supplied or calibrated | symmetric baseline geometry |

**B1 gate.** On one frozen OS image, all three adapters must support IBSS,
monitor capture, broadcast reception, channel/rate selection, and timestamped
pcap. A zero-load single broadcast must be observed as one transmitted 802.11
DATA frame and multiple receptions. Adapter revision, USB ID, firmware, kernel,
driver, antenna and regulatory domain are logged. Failure changes the radio
candidate, not the protocol.

### B2 — Complete five-node shared-medium bench

After B1 passes, add:

| Item | Additional qty. | Final qty. | Purpose |
|---|---:|---:|---|
| Raspberry Pi 5 4 GB + supply + cooling + storage | 2 | 5 | match primary `N=5` cell |
| Verified AR9271 adapter and antenna | 2 | 5 | one experimental interface/node |
| Passive-sniffer radio | 1 | 1 | independent packet/airtime evidence |
| Sniffer host | 0 or 1 | existing laptop preferred | prevents capture work from perturbing nodes |
| Fixed nonconductive stands and measurement tape | 5 | 5 | repeatable geometry |
| USB-to-UART adapter or logic analyzer | 1 | 1 | optional GPIO/serial timing cross-check |

The five Pi nodes are sufficient for application timing, MAC traces, queueing,
ACK implosion, hidden-terminal geometry and energy experiments. They are not
flight controllers and do not validate vehicle dynamics.

### B3 — Power measurement

| Item | Qty. | Requirement | Use |
|---|---:|---|---|
| Precision power analyzer | 1 | simultaneous voltage/current, sufficient bandwidth | energy per DATA/ACK and policy duty-cycle delta |
| Powered USB breakout/test lead | 1 | current path accessible without changing USB data | measure the external Wi-Fi adapter separately |

Default instrument class is Joulescope JS220 or equivalent. JS220 is specified
for 300 kHz bandwidth, 2 MS/s and +/-3 A continuous current:
<https://download.joulescope.com/products/JS220/JS220-K000/description.html>.
Because Raspberry Pi 5 is specified for a 5 V/5 A supply, JS220 must **not** be
assumed suitable for the full worst-case Pi supply path. Measure the USB radio
separately, or select a higher-continuous-current instrument for whole-node
power. One analyzer is enough; repeat paired runs node by node.

### B4 — Two-aircraft gate; purchase only after B2 passes

The default flight platform is a **500 mm PX4 research quadrotor**, starting
with two aircraft rather than five.

| Item | Qty. | Default | Notes |
|---|---:|---|---|
| Airframe/development kit | 2 | Holybro X500 V2 class | room for companion computer and research radio |
| Flight controller | 2 | Pixhawk 6C class running PX4 | autopilot/safety loop, not the research policy |
| Companion computer | 2 | Raspberry Pi 4 Model B, 4 GB | run policy, logging and Wi-Fi; lower-power default than the bench Pi 5 |
| Research Wi-Fi interface | 2 | same driver family validated at B1 | exact adapter may be repackaged for weight/power |
| Battery | at least 4 | 4S, airframe-approved capacity/C-rating | two active plus two turnaround spares |
| Balance charger and fire-safe handling | 1 set | matched to LiPo chemistry | laboratory safety |
| RC transmitter/receiver and independent kill path | 1 set | PX4-compatible | safety supervisor |
| Spare propellers and one motor/ESC set | 1 lot | exact airframe match | controlled recovery from minor damage |
| Position ground truth | 1 system | outdoor RTK GNSS or indoor motion capture/UWB | do not use ordinary GNSS as formation ground truth |
| Netted volume or geofenced test range | 1 | institution-approved | two-UAV safety gate |

Holybro specifies the X500 V2 as a 500 mm frame with mounts for Raspberry Pi,
about 18 minutes hover without added payload using a 5000 mAh battery, and a 4S
3000--5000 mAh recommendation. These are vendor figures and must be replaced by
our measured endurance/payload margin before flight:
<https://holybro.com/products/x500-v2-kits>. Pixhawk 6C uses an STM32H743
480 MHz controller with redundant IMUs:
<https://holybro.com/products/pixhawk-6c>.

PX4 documents a Raspberry Pi companion connection to Pixhawk through `TELEM2`
for ROS 2/offboard operation:
<https://docs.px4.io/main/en/companion_computer/pixhawk_rpi>. If an integrated
Holybro CM4 baseboard is chosen as a later packaging alternative, note that its documented plug-in flight
controllers are PAB-form-factor units such as Pixhawk 6X; a Pixhawk 6C requires
the normal external wiring. Do not order the integrated baseboard until this
mechanical-interface choice is frozen. Raspberry Pi specifies a 15 W USB-C
supply for Pi 4; the aircraft DC regulator still requires a measured transient
margin with the Wi-Fi adapter attached:
<https://www.raspberrypi.com/products/raspberry-pi-4-model-b/>.

**B4 gate.** First validate one tethered/network-in-loop aircraft, then two
aircraft with an independent safety pilot. Scale to three--five only after
tracking, minimum separation, failsafe, PDR/RTT, power and invariant gates pass.

## 3. Alternative safe indoor platform

Crazyflie 2.1+ with Lighthouse positioning is an optional control/formation
platform when a netted X500 facility is unavailable. It is not the primary
communication validation because its native 2.4 GHz radio is not Wi-Fi. The
official platform lists seven-minute flight time and 15 g recommended payload,
which also makes adding a conventional USB Wi-Fi interface impractical:
<https://www.bitcraze.io/products/crazyflie-2-1-plus/>. Use Crazyflie only to
validate control integration/safety or build a separate custom-radio study;
do not merge those results with the Wi-Fi MAC evidence.

## 4. Equipment deliberately deferred

- No Jetson/GPU unless a later study adds vision or learning.
- No SDR/USRP for the primary Study 2 question; add one only for PHY/SINR or
  interference-waveform research.
- No five-UAV purchase before the two-aircraft gate.
- No motion-capture purchase before the institution decides indoor versus
  outdoor flight and checks whether an existing facility can be used.
- No exact onboard Wi-Fi adapter lock until B1 measures driver behavior and B4
  measures payload/current. The bench chipset/driver semantics are fixed first;
  packaging can change only with a documented equivalence test.

## 5. Required artifacts from hardware

Every B1--B4 campaign archives raw `pcap`, node logs, clock-sync residuals,
configuration, kernel/firmware/driver versions, antenna geometry, channel,
transmit power, rate-control setting, packet schema, measured frame sizes,
airtime, queue delay, ACK RTT, PDR, busy fraction and power traces. Application
DATA rate, over-the-air frame rate, recipient delivery rate and occupied airtime
remain distinct metrics.
