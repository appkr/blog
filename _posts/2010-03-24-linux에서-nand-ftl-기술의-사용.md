---
layout: post
title: Linux에서 Nand-FTL 기술의 사용
date: '2010-03-24 13:00:28 +0900'
categories:
- work-n-play
tags:
- opensource
- linux
- 기획자
---

## FTL 이란?

USB 케이블등을 이용해서 휴대단말과 PC 를 연결하여 카메라로 찍은 영상 등을 PC 로 가져오고, PC 에서 다운로드/인코딩한 동영상이나 파일을 휴대단말로 복사하는 것은 필수적인 기능이다.

Nand Flash Memory 를 저장장치로 하는 휴대단말과 PC 를 서로 연결하여, 위와 같이 파일을 주고 받기 위해서 필요한 기술이 FTL (Flash Translation Layer) 이다. PC 는 Block 단위의 저장공간을 할당하는 반면에, Nand 는 Page 단위로 저장공간을 활용하기 때문에 양 File System 간의 상호운용성을 위해 단말 시스템에 필요한 기반 기술이 FTL 이라는 녀석이다.

이런 문제점을 피하기 위해 휴대단말의 Nand 에 SD카드 인터페이스를 도입하여 PC 의 파일시스템을 그대로 사용할 수 있는 Movi-Nand 등이 있으나, Nand 와의 가격/특성 차이로 휴대 단말 제조사들의 상품 기획은 다양할 수 있다.

<!--more-->

## Linux Kernel 에 포함된 FTL 의 상용 목적 사용은 "불가"

- 일반 공중에게 공개되어 있는 Linux Kernel (GPL) 의 Nand Driver 에는 이미 FTL 이 구현되어 있다. (kernalx.x.x/drivers/mtd)
- Kernel 이 포함되어 공개된 FTL 소스코드는 사용에 다음의 제약이 있다. (quote from kernalx.x.x/drivers/mtd/ftl.c)

```
LEGAL NOTE: The FTL format is patented by M-Systems. 

They have granted a license for its use with PCMCIA devices: "M-Systems grants a royalty-free, non-exclusive license under any presently existing M-Systems intellectual property rights necessary for the design and development of FTL-compatible drivers, file systems and utilities using the data formats with PCMCIA PC Cards as described in the PCMCIA Flash Translation Layer (FTL) Specification."

Use of the FTL format for non-PCMCIA applications may be an infringement of these patents. For additional information, contact M-Systems (http://www.m-sys.com) directly.
```

M-systems 가 Linux Kernel 에 Contribution 한 FTL 코드는 PCMCIA 디바이스 구현에만 자유롭게 사용할 수 있으며, 다른 디바이스로 사용하고자 할 경우에는 M-Systems 의 허락을 받아야 한다는 내용이다. 그런데, 요즘 PCMCIA 디바이스를 누가 쓴다더냐?

- 오픈소스 검출 툴 검사 결과, 실제로 상용화 프로젝트에 Linux Kernel 에 포함된 FTL 관련 코드가 사용된 경우는 없었다.
- Google 검색 결과에 따르면, 다음의 기업들이 FTL 과 관련된 원천적이고 포괄적인 특허를 보유한 것으로 추정된다.

  - [Mitsubishi](http://deadwi.jaram.org/wiki/wikka.php?wakka=FlashMitsubishi): Flash Memory Card with Block Memory Address Arrangement
  - [M-system](http://deadwi.jaram.org/wiki/wikka.php?wakka=FlashMSystem): Flash File System Optimized for Page-mode Flash Technologies
  - [Lexar media](http://deadwi.jaram.org/wiki/wikka.php?wakka=FlashLexar): Moving Sequential Sectors within a Clock of Information in a Flash Memory Mass Storage Architecture
  - Samsung: Method of Driving remapping in flash memory and flash memory architecture

  *상기의 특허를 피해가는 방법에 대한 논문들이 상당히 많이 있으나, 상기의 특허들 만큼의 성능을 내지 못하는 것으로 알려져 있다.*

- FTL 관련 논문은 여기—[http://aisitei.tistory.com/253](http://aisitei.tistory.com/253)—를 참조하자.

## 결론

- Nand 가 포함된 휴대단말에서 FTL 을 포함하여 상용화하고자 한다면,
  - 위에 나열한 원천 특허권자로 부터 사용권/실시권을 라이센스 받는다.
  - File System 및 FTL 개발을 전문으로 하는 3rd Party 의 솔루션을 활용한다.
  - 위 특허를 피할 수 있는 논문을 참조하여 자체 개발한다.
  - 원천특허에도 논문에도 없는 전혀 새로운 방법을 고안해서 자체 개발한다.
- 다른 OS 에서 Linux 의 FTL 코드를 참조하여 함수/변수명을 전부 변경하여 개발한 후, OS 의 특성상 소스가 아닌 바이너리 형태로 배포한다고 해도, Reverse Engineering 에 의해서 위 원천 특허들의 침해 사실이 밝혀질 가능성이 충분하며, 특허권 소유자로 부터 소송을 당할 잠재적 위험이 있다.

**`주)`** Linux Kernel 에 포함된 FTL 코드들은 GPL 로 선언되어 있다.

**`주)`** 특허료 많이 받아봐야, 단말 1 대당 500 원을 넘기 힘들 것이다. 1 만대 파는 회사에 500 만원을 받아 내자고, 변호사 비용과 비싼 시간을 들여 소송을 걸지는 않을 것이다.

## 덧글 2010-04-02

Nokia 에서 N900 을 개발하면서 만든 UBIFS (driver/mtd/ubifs, fs/ubi) 는 현재까지 확인된 바에 따르면 상용으로 사용하는 데 전혀 제한이 없는 것으로 확인되었다. Nokia 는 N900 상용화와 함께 개발한 UBIFS 코드들을 kernel.org 에 Contribution 하였고, Kernel 2.6.27 이후부터 기본으로 패키지되어 있다.
