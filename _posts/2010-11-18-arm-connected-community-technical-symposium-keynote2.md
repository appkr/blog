---
layout: post
title: ARM Connected Community Technical Symposium 2010 Keynote II
date: '2010-11-18 12:04:00 +0900'
categories:
- around-me
tags:
- arm
- soc
- 기획자
---

## Challenges of Making a High-performance Mobile SoC-An IP Perspective

*김진현상무, Samsung*

### A. Mobile Device Usages and Demand Forecast

#### 1. Smart Life

인터넷 커넥티비티가 확보된 모바일 디바이스의 보급으로 인해, 언제 어디서든, 실시간으로 사실상 무한대의 정보에 접근할 수 있는 길이 열리게 되었다.

#### 2. Processing Performance Trend

&nbsp;|2008|2009|2010|2011|2012
---|---|---|---|---|---
3D Graphics|4M Tri/s|10M Tri/s|20M Tri/s|50M Tri/s|200M Tri/s
CPU|ARM11 677MHz|Cortex-A8 600MHz|Cortex-A8 1GHz|Cortex-A9 Dual 1GHz|Eagle Dual Core
Multimedia|SD 480p|HD 720p|HD1080p|1080p 3D Vision|UHD
Applications|Web Browsing/Social Networking|&nbsp;|3D Gaming / 3D UI|&nbsp;|Augmented Reality / 3D Display / Imaging

#### 3. Process Technology Trend
-   Gate density doubles at each node
-   with more integrated functions and features
-   with higher performance
-   with lower active and static power

#### 4. Gate Density (M/mm^2): 65nm → x2 → 45nm → x2 → 32nm
-   Relative Performance (Ring Oscillator): 65nm → 23% up → 45nm → 45% up → 32nm
-   Relative Power: 미세화 공정을 한 단계 거칠수록 평균 Active Power/MHz 25% Down, Standby Leakage 50% Down

#### 5. Market Outlook: Smartphone & Tablet (M Units)

&nbsp;|2009|2010|2011|2012|2013|CAGR
---|---|---|---|---|---|---
Mobile phone|1,290|1,380|1,460|1,545|1,625|&nbsp;
Smartphone|173|280|405|540|678|&nbsp;
Smartphone Penetration|13%|20%|28%|35%|42%|&nbsp;
Tablet|0|17|53|78|108|85%

<!--more-->

<div class="spacer">• • •</div>

### B. Mobile SoC Market Landscape

#### 1. Mobile SoC

is a Key Enabler of Mobile Experience

#### 2. Key Ingredients in Mobile SoC

-   CPU
    -   OS와 applications 을 구동하기 위한 General-purpose CPU core(s) 필요
    -   Mobile 기기가 점점 범용성이 높은 PC 와 같은 기능을 하면서 CPU Core 의 중요성 증가

-   Multimedia IP
    -   고품질의 비주얼 경험에 대한 요구사항 증가
    -   3D, Video Codec, ISP(Image Signal Processing) 등 하드웨어 가속 기반 사용자 경험 제공 필요

    *삼성전자는 저전력 요구사항을 만족하기 위해 당분간은 Programmable (DSP) IP를 제공하지 않고, Full Hardware IP를 채용하는 것을 제품 전략으로 하고 있음.*

-   Memory Subsystem
    -   풍부한 사용자 경험을 제공하기 위해 메모리 대역폭에 대한 수요 증가
    -   시스템 간의 연결을 위한 버스와 메모리 컨트롤러로 구성

-   Status of AP Market: PC 시장과 달리, Mobile SoC 시장은 서부 개척 시대와 같은 상황.

-   삼성전자의 Mobile CPU 전략

    *삼성의 경쟁사 대비 빠른 미세공정기술 기반으로, 최신의 CPU Core 를 탑재한 Mobile SoC 를 경쟁사 보다 빨리 시장에 제공함으로써, 시장을 선도해 나간다.*

- 삼성전자의 Key Multimedia Hardware 가속 IP
    -   Video
        -   Full HD enc/dec: H.264, MPEG4, VC-1 and more…
        -   Feature '10: 1080p 60fps real-time processing
        -   Feature '11~: Stereoscopic, UHD (4x of Full HD), and HDR
    -   3D Grahpics
        -   Desktop or console game quality for smartphone
        -   Feature '10: ~4 shaders, 60M Tri/s
        -   Feature '11~: 4~32 full-precision shaders, ~400M Tri/s
    -   ISP
        -   12Mpix imaging and Full HD motion video support
        -   Feature '10: 12Mpix @15fps or 3Mpix @60fpx
        -   Feature '11~: 24MPix @15fps or 6Mpix @60fps

<div class="spacer">• • •</div>

### C. IP DEVELOPMENT PROCESS

#### 1. IP Development Challenges
-   Schedule
    -  사용자의 요구사항에 대응하기 위해서는 항상 공격적인 IP 개발 일정을 운영해야 함.
    -  새로운 멀티미디어 IP의 개발과 지속적인 성능 향상
    -  메모리 서브시스템 제약사항에 대한 고려
-   Power Requirement
    -   Power 요구사항을 만족시키기 위한 Hardwired 디자인
    -   다양한 Power Saving Feature 필요
-   Verification
    -   대량 생산 제품에서의 Bug 는 회사 경영에 치명적 영향

#### 2. IP Development Phases

VoC → Exploration → Implementation (→ Iteration) → Verification (← Iteration)

#### 3. (Example) Multi-Format Video Codec IP

&nbsp;|Previous Generation|Current Generation|Next Generation
---|---|---|---
# of supported Standard/Profile|Enc:6, Dec: 12|Enc:7, Dec: 12|Enc: 8, Dec: 16
Performance|720p @30fps|1080p @30fps|1080p @60fps
Design Complexity|3.0M Gates|4.0M Gates|6~7 M Gates

-   Exploration: Structural C-Model
    -   실제 하드웨어 디자인을 하기 전에 알고리즘 및 기능적 정확성을 위해 C-Model 로 Feasibility 검증
    -   새로운 Encoding, Decoding 표준 추가 및 성능 개선
    -   C-Model 에서 Conformance 및 성능 시험
    -   Firmware development platform

-   Exploration: Memory Bandwidth Trends in Mobile SoC

-   Verification: Goal is to deliver stable bug-free IP
    -   "Maximize coverage within time and resource restriction"
    -   개발과정에서의 버그 비용은 크지 않지만, 양산 이후의 버그 비용은 엄청나다, 특히 하드웨어일 경우에는 ...
    -   삼성전자의 MFC conformance test streamdms ~20K
    -   Error resilience test
    -   검증환경: RTL Simulation, H/W emulation, FPGA

<div class="spacer">• • •</div>

### D. CONCLUDING REMARKS

-   Mobile 기기의 보급으로 사람들이 언제 어디서나 일하고, 놀 수 있게 되었다.
-   고 품질 사용자 경험에 대한 요구사항 증가로, Mobile 기기는 더 강력해진 반면, 전력 소모는 더 줄어들고 있다.
-   사용자 경험의 Key Enabler 는 Mobile SoC 이고, 성공적인 Mobile SoC 사업을 위해서는 파트너와의 밀접한 협업과, 차별화된 IP 보유가 필수적이다.

