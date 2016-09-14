---
layout: post
title: bluetooth 솔루션 선택
slug: technical-decision-on-bluetooth
date: '2010-02-13 11:45:53 +0900'
categories:
- work-n-play
tags:
- bluetooth
- connectivity
- 기획자
---

많은 단말회사들이 이런 고민을 하고 있겠지?

## BT Stack

참조번호|Profile
---|---
`d`|RFCOM (serial)
`c`|L2CAP
`b`|LC/LM
`a`|Bluetooth Baseband

<!--more-->
<div class="spacer">• • •</div>

## Solution Comparison

&nbsp;|ROM version|MM Version
---|---|---
Vendor/Software|BCHS|BlueLab (HSP, A2DP 기본 탑재)
제공 범위	|~ `b` 까지	|~`d`까지
모듈 구성|	BT BB, ROM(for Firmware|BT BB, mcu, Kalimba DSP(64mips, for SBC enc/dec), Flash Memory
주요 활용 분야|Device Tx, Rx|Accessory(주로 헤드셋) Rx
단가|x|3x

**`고려사항`** WinCE나 RTOS 에서는 MM 이 훌륭한 솔루션이나, Linux 에서는 상품화된 이력 확인 안됨.

## Issues

- 추가 Profile 을 넣어야 할 경우, MM은 확장성이 떨어 진다.
- MM 의 내장 Falsh Memory 가 제한적이라, Device Tx 용도로 사용할 경우 외장 Memory 를 활용해야 한다.
- ROM 은 `c`/`d` 및 SBD enc/dec 를 모두 Software 로 처리한다.
- 국내에서 BT 를 Linux 에서 구현한 업체는 많지 않다. 따라서, MM 을 사용할 경우에도 전체 Stack 에 대한 지원이 가능할 지 의문이다.
- Linux 에서는 ROM 이나 MM 이나 업무 내용은 동일할 것으로 추정된다.
