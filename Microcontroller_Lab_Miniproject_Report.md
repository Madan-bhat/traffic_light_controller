# Microcontroller LAB Mini-project Report

**Title:** Adaptive Four-Way Traffic Light Control System Using the 8051 Microcontroller with Vehicle Density Sensing and Emergency Vehicle Detection

## Student Details

| Name | Registration No | Objectives addressed by individual | Individual contribution towards attaining the objective | Signature |
|------|-----------------|------------------------------------|----------------------------------------------------------|-----------|
|      |                 |                                    |                                                          |           |
|      |                 |                                    |                                                          |           |
|      |                 |                                    |                                                          |           |
|      |                 |                                    |                                                          |           |

**Date of Submission:** ____________________  
**Staff Signature:** ____________________

---

## 1. Problem Statement

Existing fixed-time traffic light systems operate on preset clocks that change phases after fixed durations, regardless of actual traffic density. This causes unnecessary waiting at empty approaches and increased congestion during peak hours. Greenhouse emissions rise as vehicles idle, and emergency vehicles (ambulances, fire engines) are frequently delayed due to inflexible signal timing.

There is a clear need for an adaptive controller that assigns green time according to demand on each approach and provides an override so emergency vehicles receive priority without compromising overall safety.

## 2. Objectives

1. Design a four-way traffic signal controller on the AT89C51 / 8051 that cycles Lane1 → Lane2 → Lane3 → Lane4 with safe red–yellow–green sequencing.
2. Sense vehicle presence on each approach (four active-high sensors) and extend green time when traffic is detected.
3. Skip a lane’s green phase when its sensor shows no traffic, reducing idle green time.
4. Provide emergency override (one switch per approach) that forces green for that lane until the switch is released, then resumes the normal cycle.
5. Support a pedestrian walk phase when a push-button request is active.
6. Implement the full control algorithm in 8051 assembly and verify on a hardware prototype / simulator.

## 3. System Overview

| Item | Description |
|------|-------------|
| Microcontroller | AT89C51 (8051-compatible), 11.0592 MHz crystal |
| Vehicle sensors | 4 × IR / obstacle sensors on **P2.0, P2.2, P2.4, P2.6** (one per lane) |
| Emergency inputs | 4 × push-buttons on **P3.0–P3.3** (Lane1–Lane4) |
| Pedestrian input | Push-button on **P3.7** |
| Outputs | Port **P1**: Lane1 & Lane2 LEDs + pedestrian (P1.7); Port **P0**: Lane3 & Lane4 LEDs |
| Timing | Nested software delay loops (~1 s base); green ≈ 20 s, optional +10 s density, yellow ≈ 2 s, pedestrian ≈ 15 s |

**Note:** This implementation uses **four** lane sensors (binary present/absent), not eight dual-density sensors. Green extension is a fixed +10 s when the lane sensor is active—not a multi-level density classifier or hardware Timer0 Mode-1 scheduler.

## 4. Port Map and Signal Encoding

### Inputs

| Pin | Function |
|-----|----------|
| P2.0 | Lane 1 vehicle sensor |
| P2.2 | Lane 2 vehicle sensor |
| P2.4 | Lane 3 vehicle sensor |
| P2.6 | Lane 4 vehicle sensor |
| P3.0 | Emergency — force Lane 1 green |
| P3.1 | Emergency — force Lane 2 green |
| P3.2 | Emergency — force Lane 3 green |
| P3.3 | Emergency — force Lane 4 green |
| P3.7 | Pedestrian request |

### Typical LED patterns (hex values used in code)

| Value | Port | Meaning (per design) |
|-------|------|----------------------|
| `#09h` | P0 / P1 | Both lanes on that port red |
| `#0Ch` | P0 / P1 | First lane green, second red |
| `#21h` | P0 / P1 | Second lane green, first red |
| `#0Ah` | P0 / P1 | First lane yellow, second red |
| `#11h` | P0 / P1 | Second lane yellow, first red |
| `#89h` | P1 | Pedestrian walk + reds |

Exact LED-to-bit wiring must match the lab schematic; the hex constants assume the same bit layout as the accompanying `code.asm`.

## 5. Algorithm / Flow

1. **Lane i:** If sensor inactive → skip to next lane. Else set conflicting approaches red and this lane green.
2. **Density:** If the lane sensor is still active, call extra delay (`delaye`, ~10 s), then normal green (`delayg`, ~20 s).
3. Yellow (`delayy`, ~2 s), then all-red clearance (`delays`, ~1 s).
4. After Lane4, if **P3.7** set → all-red + pedestrian walk (`delayp`, ~15 s).
5. Loop back to Lane1.
6. During every 1 s base delay, poll **P3.0–P3.3**. If an emergency is active, force that lane green until the switch clears, then resume from the saved lane ID in internal RAM **30h**.

### Important implementation detail

The delay routine uses **R7** as a loop counter. The current lane number is therefore stored in **direct RAM address 30h**, not in R7. Emergency resume compares against `30h`. Using R7 for both lane ID and delay counting is a latent bug and must be avoided.

## 6. Software Structure (`code.asm`)

| Label | Role |
|-------|------|
| `Lane1`–`Lane4` | Per-lane sense / skip / green / yellow / red |
| `Ped` | Pedestrian phase |
| `delayg` / `delayy` / `delaye` / `delayp` / `delays` | Timing |
| `em1`–`em4` / `em_resume` | Emergency hold and return to cycle |

Language: **8051 assembly** (Keil µVision / equivalent assembler).

## 7. Hardware / Materials (Bill of Materials)

| Qty | Item |
|-----|------|
| 1 | AT89C51 microcontroller (40-pin DIP) |
| 1 | 11.0592 MHz crystal |
| 2 | 33 pF ceramic capacitors (crystal load) |
| 1 | Reset circuit (10 µF + 8.2–10 kΩ as per lab standard) |
| — | Port-0 pull-up resistors (if required) |
| 4 | IR / obstacle sensor modules (lanes) |
| 12+ | LEDs — red, yellow, green (5 mm) + series resistors |
| 1 | Pedestrian indicator LED |
| 5 | Push-buttons (4 emergency + 1 pedestrian) |
| 1 | 5 V regulated supply (e.g. 7805) |
| — | Breadboard / PCB, wires, headers |

*[Insert photograph(s) of the hardware prototype here]*

## 8. Results / Expected Behaviour

| Condition | Behaviour |
|-----------|-----------|
| No vehicles on a lane | That lane’s green phase is skipped |
| Vehicle present | ~20 s green; +~10 s if sensor still asserts at start of phase |
| Emergency switch held | Corresponding lane forced green until release |
| Pedestrian button | All-red + walk interval after Lane4 |
| Conflict safety | Only one approach green at a time; yellow before red |

*[Insert Proteus / Keil simulation screenshots or bench photos here]*

## 9. Conclusion

The adaptive four-way controller demonstrates demand-based green extension, empty-lane skipping, emergency preemption, and a pedestrian phase on a classic 8051 platform. Software delay loops keep the design lab-simple; the same structure can later be migrated to Timer0 interrupts for more accurate timing.

## 10. References

1. Mazidi, M. A., et al. — *The 8051 Microcontroller and Embedded Systems*.
2. Atmel / Microchip AT89C51 datasheet.
3. Lab manual — Microcontroller Laboratory (institution-specific).

---

*Report aligned with `code.asm` (4-sensor adaptive cycle, RAM 30h lane ID, emergency on P3.0–P3.3, pedestrian on P3.7).*
