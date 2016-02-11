---
layout: post
title: ARM Connected Community Technical Symposium 2009
date: '2010-02-13 12:10:46 +0900'
categories:
- around-me
tags:
- arm
---

ARM 社는 일반인에게는 잘 알려져 있지 않지만, Embedded System 산업의 가장 근간이 되는 IP (설계자산) 회사이다. PC 에서 사용하는 CPU 가 Intel 社의 x86 Architecture 를 사용하는 것과 마찬가지로, 이동통신단말/PMP/NAS/PND/eBook/... 등에는 모두 ARM 社의 ARMv5/v6/v7 Architecture 가 탑재되어 있다. Intel 社는 종합반도체 (IDM) 회사로 자신이 x86 설계자산을 가지고 반도체를 설계하고 생산도 하지만, ARM 社는 직접 반도체를 제조하지는 않고 개발된 IP 를 반도체 제조사에 라이센스하는 비즈니스를 한다. ARM Architecture 를 라이센스 받아 반도체를 개발하는 회사는 우리가 잘 알고 있는 Qualcomm 을 비롯하여, nVidia, TI, Marvell, ST Microelectronics, NXP… 국내의 CoreLogic, Telechips, Mtekvision 등의 Fabless 기업들이 해당한다.

> Fabless, 반도체 산업에서는 특이하게 공장이라 부르지 않고 Fabrication (Fab, 팹) 이라 부른다.
> 
> 대만의 TSMC, UMC 와 같이 Fab 만 운영하는 회사를 Foundry 라고 분류한다. 생산시설은 없지만, 반도체를 설계만 하고 생산을 Foundry 에 위탁하는 기업을 Fabless (팹리스) 라 부른다. Intel, Samsung, ST 와 같은 회사는 설계와 생산을 모두 하기 때문에, IDM (종합 반도체) 이라 부른다.

<div class="spacer">• • •</div>

ARM 社는 전세계 IP 회사 중 최대규모의 회사이다. Rambus 가 2위. ARM 의 IP 는 전세계적으로 매년 30억개 이상 Shipping 된다고 추정된다. 휴대단말 뿐만 아니라, 우리들 PC 에도 Network Processor 는 주로 ARM 이 사용된다. ARM Connected Community 는 ARM 社의 Ecosystem Program 의 이름이다.

올해는 신제품도 새로운 로드맵도 없었던 기존 제품 소개 정도로 그쳤다. 매년 똑 같지만, 오전에는 1 트랙으로 3 개의 세션이 있었고, 오후에는 3 트랙으로 각 트랙별 4 개의 세션과 통합 세션 1 개가 있었다. 주목할만한 내용만 간단히 정리해 놓기로 한다.

**`주)`** 제시된 정보나 수치는 연사들의 주장으로, 필자의 견해와 무관함을 분명히 해 둔다.

<div class="spacer">• • •</div>

## Key Note1: A New Era of Smart Computing

*by Tudor Brown, President/ARM Ltd.*

- Mobile Internet 붐에 대한 기대
- Featurephone Shipment 는 concave (시장이 saturation 되는 모양) 형태를 띠는 반면, Smartphone 은 convex (급속 성장) 형태를 띤다.
- Connectivity 의 필요성 증가. GPS, Biometrics, HDD, HSPA/WiMAX, mobile TV, SD(HC), USB, WiFi, TV-Out, NFC/RFID, Bluetooth/UWB, Stereo Headset, ...
- 시장의 분화 (다양화) 로 인한 기회 증가.
  - 2013년: 24 억 대의 Consumer Mobile Device
  - 2013년: 14억대의 Mobile
  - 2013년: 6억대의 Home
  - 2013년: 1.3억대의 Netbook
  - 2013년: 2억대의 PMP
  - 2013년, 0.5억대의 전장용 멀티미디어 장치
- Internet 은 Digital Home의 초석이 될 것.
- 기술적인 Challenge
  - More Performance -> SoC 의 복잡도 증가
  - Memory Interface 의 Bottleneck 증가
  - 소모 전류 최소화에 대한 요구 증가
  - Software 의 호환성 및 재 사용성에 대한 필요성 증가
- ARM社의 솔루션
  - NEON 에서의 Skia GFX 지원
  - Chrome OS 에서의 JIT 지원
  - MALI GPU 에서의 Flash 10 지원
  - ARM Android Solution Center 오픈 ([http://www.arm.com/community)](http://www.arm.com/community)
  - 32/28nm 공정에 대한 로드맵
  - Osprey 출시 (Dual-core CortexA9 40nm Hard Macro)
  - MALI Video Engine (Mali-VE3 up to D1, Mali-VE6 up to 1080p@30fps)
  - MALI Developer Center ([http://www.malideveloper.com/)](http://www.malideveloper.com)
  - MCU programming in the web ([http://mbed.org)](http://mbed.org)
  - CMSIS, ARM Cortex Microcontroller Software Interface Standard
  - ARM Connected Community, 600+ Partners
  - Game Rule 의 변화
  - A battle of architecture -> A battle of business model. 1992년에 10개가 넘던 CPU Architecture 들이 현재는 x86, ARM, MIPS, SPARC 로 재편되었다. 그 이유는 Ecosystem!!! 즉, Business model!!!
  - Intel 과 ARM 과의 전쟁이 아니라, Intel 과 Semiconductor Industry 와의 전쟁.

<!--more-->

### ARM 社의 Vision.

> "A world where your electronic products and services are based upon energy efficient technology, making life batter for everyone."

**`주)`**

`JIT <sup>Just in Time compilation</sup>` [http://en.wikipedia.org/wiki/Just-in-time_compilation](http://en.wikipedia.org/wiki/Just-in-time_compilation)

`Skia` Graphic Engine으로 Chrome OS에서 사용될 예정. [http://en.wikipedia.org/wiki/Skia_Graphics_Engine](http://en.wikipedia.org/wiki/Skia_Graphics_Engine)
 
## Key Note 2: Challenges and Chances in Mobile SoC Markets

*by 정세웅전무, Samsung*

- Digitalization, 종이사진/카세트테입/비디오테입 시장의 쇠락
- Mobile internet experience
  - Full web browsing
  - Realtime video streaming
  - New mobile service (e.g. LBS 外)
- Samsung 전자의 시장 전망
  - MID, Netbook 시장의 성장
  - Intel 과 ARM 진영의 전쟁, Microsoft 와 Linux 진영과의 전쟁
  - ARM 진영 내에 속한 SoC Vendor 들 사이에서도 치열한 전쟁
- SoC Vendor 들에게 닥친 Challenge (SoC를 잘 만들기 위해서 고려해야 할 점)
  - Performance
  - CPU
  - Multimedia: 삼성전자는 Programmable보다는 Hardwired Video Codec으로...
  - DRAM
  - Peripheral & other memories
  - Bus: AHB -> AXI -> NoC (Network on Chip) Architecture 로 진화
  - Power
  - Clock gating
  - DVFS, Dynamic Voltage and Frequency Scaling
  - Power gating
  - Voltage island
  - Adaptive body biasing

## Enabling the next 15+ billion units from under $ to over 2GHz

*by Ian Rickards, CPU Product Manager, ARM Ltd.*

- Cortex Lineup
  - A Series for reature-rich OS and applications, 스마트폰/PMP/MID/Smartbook 등
  - R Series for real-time signal processing, 잉크젯프린터/SSD 디스크 등
  - M Series for 16bit micro-controller, MCU 가 쓰이는 모든 시장
- Cortex A Lineup
  - Osprey(soon), 2GHz TSMC@40nm
  - A9 (1~4x Symmetric Multi Processor), A8 (current volume product)
  - A5 for power-sensitive applications
- Cortex R Lineup
  - R4F, floating point computation
  - R4
  - SC300 for smartcard (Infineon Technology selects this)
- Cortex M Lineup: M3 for MCU, M1 for FPGA, M0 for MCU
- CortexA9 이 현재 시중에 나와 있는 Netbook (Intel Atom) 대비 1/5 전류 소모

## Track III: Samsung's Perspective: The Future of Mobile Computing

*by 조현덕수석, Samsung*

- Mobile device trends
  - Service trends, AppStore/Social Network/Open OS
  - UI trends, Keypad -> Touch -> Voice & Character Recognition
  - Convergence trends, Featurephone -> Smartphone -> Smartbook/MID
  - Market segmentation by performance and screen size, Smartphone -> MID/PND/PMP -> Netbook(Smartbook)
- The future of smartphone
  - Communication(2G->2.5G->3G)-centric 단말들의 곡선이 점점 완만해지는 반면, Application-centric(Fun-centric) 단말들은 급속 성장
  - Open OS의 붐은 Open Hardware Platform도 드라이브 하고 있음 (e.g. [ODROID 단말](http://www.odroid.com/))
  - Paradign Shift, Communication centered -> Computation centered, 즉, 향후 시스템은 Powerful Applications Processor와 Thin modem으로 구성될 것.
- The future of netbook
  - Fast growing market and 2 major segments: Premium (+300$, x86, Windows), Value (~200$, ARM, Linux)
  - ARM based netbook 이 증가 하는 이유, Performance/Power/Footprint/Megatrend (Open OS)
- Samsung's solution
  - World 1st 1GHz CortexA8 CPU in 45nm LP
  - Windows Mobile/CE, Linux, Android, Ubuntu, Chrome OS, Firefox, ThinkFree Office, Flash 10, OpenGL/MAX

## Track II: ARM Profiler: Android/Linux Application Profiling

*by Alex Growcoot, ARM Ltd*

- Graphical 한 디버깅 환경을 제공
- RVDS 4.0 Professional Version 에서만 Profiler 사용 가능
- Trace 2 장비가 있어야 하며, 디버깅용 20pin ETM 포트를 이용해 연결
- 장비 및 RVDS 4.0 Single User License 만 해도 수 천만원

## Track II: Turning on NEON light on

*by Ian Richards, ARM Ltd*

- NEON, SIMD Instruction set 을 가진 DSP
- How to use NEON
  - OpenMAX DL Library, [http://www.arm.com/products/esd/openmax_home.html](http://www.arm.com/products/esd/openmax_home.html), [http://www.arm.com/products/multimedia/openmax/](http://www.arm.com/products/multimedia/openmax/)
  - RVDS3.1 이상의 개발환경에서 기존 소스코드를 NEON 용으로 자동 컴파일해주는 Vectoring Compiler 제공
  - RVDS 3.0 이상에서 NEON 에서 C 함수를 불러 들일 수 있고, Assembler 수준의 최적화도 가능함.
  - 다양한 NEON Opensource Project 진행 중, Bluez/Pixman/ffmpeg/x264/Android Skia library, Ubuntu 9.04

## Track I: Belnding Graphics and Video in Multimedia Systems

*by Hessed Choi, ARM Korea Ltd*

- IP Lineup
  - 2D/3D, MALI Graphics (55/200/400)
  - Video, MALI-VE Video (3/6)
- Combining video and graphics
  - 멋진 UI 를 위해
  - 화면 전환 효과를 위해
  - 2/D3D Graphic 내부에 Video 컨텐츠 재생을 위해
  - Video post processing (Color space conversion, Scaling)
  - Video encoding 전에 2D/3D Graphic 효과 Muxing 을 위해
  - 그러나, 쉽지 않다. 시스템 전체의 성능 및 전류 소모를 고려해서 디자인해야 한다.
- Challenges
  - Per core resource usage, Graphics와 Video에 필요한 Bandwidth의 합이 시스템 제약사항을 넘을 수 있음.
    - Worst bandwidth for 1080p encoding @30fps including B-frames 504MBps<br/>
    - Worst bandwidth for 1080p decoding @30fps including B-frames 498MBps
  - Data movement/hardware interaction, SoC 한 블럭의 Output이 다른 블럭의 Input이 되므로, Buffer sharing과 Data compatibility는 항상 문제가 됨.
    - (X)<br/>
    - Video engine -> Converter(yuv to rgb conversion) -> GPU<br/>
    - (O)<br/>
    - Video engine -> GPU (Video engine -> YUV video output -> Video buffer in shared memory -> GPU reads as YUV texture -> GPU -> Output rendered frame -> Final RGB frame buffer)

## 통합 Track: Storming into the Next Era of Computing

*by Bob Morris, ARM Ltd.*

- 왜 시장이 우왕좌왕하는가?
  - Paradigm shifting, Mini/mainframe computing -> Personal computing -> Cloud computing
  - 사용자의 기대는 빠르게 변화 (문맥/상황 정보 인식, 이동성, 인터넷 접속, 항상 켜져 있을 것, 멀티미디어)
  - Enabling Technology 들은 이미 가용 (컴퓨터시스템의 크기, 모바일 브로드밴드, 디바이스의 진화)
- 어떤 기술을 선택할 것인가?
  - Key system component, CPU Core/Graphics/Video/Memory subsystem
  - e.g. Marvel 88AP510, STn U8500, Samsung S5PV210
- 상품화를 위해서... ARM 의 Ecosystem 을 활용하라.
- 미래는 어떻게 될까?
  - 2011년이 되면 Netbook Average Selling Price 는 $200 의 벽을 넘을 것.
  - Lots of change… an example is the eBook readers.

## 눈에 띠는 전시 부스와 ARM-powered 단말들

- ZiiEgg: 굉장히 가볍다. 기구적인 완성도는 높으나, UI 측면은 약한 듯 (Android 기본 조작을 위한 Mandatory Hardkey 가 없음). HDMI TV 셋팅이 되지 않아, Video Quality 확인 못함.
- HTC Hero: SO NICE!!! 20분 동안 만져 봤다.
- Telechips 社의 TCC89xx/92xx 보드가 데모 부스마다 쫘악 깔렸다.
- [TAT社의 UI Engine Demo](http://cusee.net/2462150): 조작이 불편하고 직관적이지 않다.
- Digital Aria: FxUI-3D를 ARM11/MALI200-Android 에 Integration 완료했다.
- [Archos 5 Internet Tablet](http://cusee.net/2462150): 상/하단으로 UI를 나누었다. 하단 GUI 가 탭과 같은 역할을 하고, 상단은 적응적으로 바뀐다. 별도의 Standalone Player 를 올리지 않고, Android 기반의 Player 를 Gallery 밖으로만 빼 놓았다.
- [ThunderSoft](http://www.youtube.com/watch?v=o5M42OLuTsI): 기본적으로 Phone 용으로 기획되고 개발된 Android 를, MID/Netbook 용으로 확장하기 위해, 가장 불편했던 다중 Window (또는 TAB 구조) 와 File Explorer 기능을 수정했다.

## 관련기사

- [모바일 인터넷의 새 시대 ARM에 열린 멋진 신세계](http://www.nekorea.co.kr/article_view.asp?seno=5964) (Nikkei Electronics 12월호)
