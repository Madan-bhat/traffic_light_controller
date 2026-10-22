; Adaptive Four-Way Traffic Light Control — 8051
; Ports:
;   P1 = Lane1 / Lane2 lights (+ P1.7 pedestrian)
;   P0 = Lane3 / Lane4 lights
;   P2.0,P2.2,P2.4,P2.6 = vehicle sensors (active high)
;   P3.0–P3.3 = emergency (active high)
;   P3.7 = pedestrian request (active high)
; RAM 30h = current lane ID (must NOT use R7 — delays destroy R7)

Org 0000h
	ljmp Lane1

Lane1:
	mov 30h, #01h			; save lane ID (delays use R7 as counter)
	jnb P2.0, Lane2			; skip if no traffic at Lane 1
	mov p0, #09h			; L3,L4 red
	mov p1, #0ch			; L1 green, L2 red

	mov a, p2
	anl a, #01h			; density check: P2.0 only
	cjne a, #01h, rare1
	acall delaye			; +10 s if vehicle present
rare1:
	acall delayg			; 20 s green
	mov p1, #0ah			; L1 yellow, L2 red
	acall delayy
	mov p1, #09h			; L1,L2 red
	acall delays

Lane2:
	mov 30h, #02h
	jnb P2.2, Lane3			; skip if no traffic at Lane 2
	mov p0, #09h			; keep L3,L4 red
	mov p1, #21h			; L2 green, L1 red

	mov a, p2
	anl a, #04h			; density check: P2.2 only
	cjne a, #04h, rare2
	acall delaye
rare2:
	acall delayg
	mov p1, #11h			; L2 yellow, L1 red
	acall delayy
	mov p1, #09h
	acall delays

Lane3:
	mov 30h, #03h
	jnb P2.4, Lane4			; skip if no traffic at Lane 3
	mov p1, #09h			; keep L1,L2 red
	mov p0, #0ch			; L3 green, L4 red

	mov a, p2
	anl a, #10h			; density check: P2.4 only
	cjne a, #10h, rare3
	acall delaye
rare3:
	acall delayg
	mov p0, #0ah			; L3 yellow, L4 red
	acall delayy
	mov p0, #09h
	acall delays

Lane4:
	mov 30h, #04h
	jnb P2.6, Ped			; skip if no traffic at Lane 4
	mov p1, #09h
	mov p0, #21h			; L4 green, L3 red

	mov a, p2
	anl a, #40h			; density check: P2.6 only
	cjne a, #40h, rare4
	acall delaye
rare4:
	acall delayg
	mov p0, #11h			; L4 yellow, L3 red
	acall delayy
	mov p0, #09h
	acall delays

;---------------------| PEDESTRIAN |-----------------------------
Ped:
	jnb P3.7, cycend		; no pedestrian request
	mov p0, #09h			; all vehicle red
	mov p1, #89h			; ped walk + reds
	acall delayp
	mov p1, #09h			; ped off
	acall delays

cycend:
	ljmp Lane1			; restart cycle (ljmp: safe distance)

;------------| DELAYS |--------------------
delayp:	mov r1, #0eh			; ~15 s
dp:	acall delays
	djnz r1, dp
	ret

delayg:	mov r1, #14h			; ~20 s
dg:	acall delays
	djnz r1, dg
	ret

delayy:	mov r1, #02h			; ~2 s
dy:	acall delays
	djnz r1, dy
	ret

delaye:	mov r1, #0ah			; ~10 s
de:	acall delays
	djnz r1, de
	ret

; ~1 s software delay; polls emergency each second
; WARNING: this routine destroys R5, R6, R7 — lane ID lives in 30h
delays:	mov r5, #08h
d1:	mov r6, #250
d2:	mov r7, #250
d3:	djnz r7, d3
	djnz r6, d2
	djnz r5, d1
	jb P3.0, em1
	jb P3.1, em2
	jb P3.2, em3
	jb P3.3, em4
	ret

;-----------------| EMERGENCY |---------------------
; Hold green for requested lane until switch released, then resume cycle
em1:
	mov p0, #09h
	mov p1, #0ch			; Lane1 green
wait1:
	jb P3.0, wait1
	sjmp em_resume

em2:
	mov p0, #09h
	mov p1, #21h			; Lane2 green
wait2:
	jb P3.1, wait2
	sjmp em_resume

em3:
	mov p1, #09h
	mov p0, #0ch			; Lane3 green
wait3:
	jb P3.2, wait3
	sjmp em_resume

em4:
	mov p1, #09h
	mov p0, #21h			; Lane4 green
wait4:
	jb P3.3, wait4
	; fall through

em_resume:
	mov a, 30h			; restore from saved lane ID (not R7)
	cjne a, #01h, em_r2
	ljmp Lane1
em_r2:	cjne a, #02h, em_r3
	ljmp Lane2
em_r3:	cjne a, #03h, em_r4
	ljmp Lane3
em_r4:	ljmp Lane4

end
