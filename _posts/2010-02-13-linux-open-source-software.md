---
layout: post
title: Linux & Open Source Software
date: '2010-02-13 16:00:17 +0900'
categories:
- work-n-play
tags:
- linux
- opensource
---

이 포스트는 어떤 법적인 조언도 담고 있지 않습니다. 이 포스트의 내용을 참고하는 것은 독자의 선택이며, 필자는 어떤 법적인 책임도 지지 않습니다.

<div class="spacer">• • •</div>

기억력이 점점 나빠진다. 이해했다고 생각했는데, 나중에 필요하면 다시 꺼내서 다시 공부해야 한다. 그 대표적인 것이 Open Source Software 의 개념이다. 

## 소프트웨어 라이센스 정책

### Open Source

통념적으로 소스코드가 공개되어 누구나 수정하고 재배포할 수 있는 소프트웨어를 말한다. 원작자가 지정한 라이센스 조건만을 지키면, 기업에서도 상용으로 사용할 수 있다. GPL, LGPL, BSD, MPL, Apache 등이 유명한 오픈소스 라이센스 정책이다.
 
### Closed Source (Proprietary Source)

소스코드가 공개되어 있지 않고, 저작권자가 통제권을 행사할 수 소프트웨어를 말한다. 저작권자와의 협의 (계약) 없이 수정하거나 재 배포할 수 없다. 주로 기업이나 기업집단에 의해 독립적으로 소유되며, 라이센싱을 통해 돈을 벌 목적으로 만들어진 소프트웨어로 이해하면 된다.

### Free Software

"Free lunch", "Freedom" 에서 사용된 "Free" 의 의미는 서로 다르다. 오픈소스는 소스코드를 공개한다는 의미가 강하고, 프리소프트웨어는 "사용의 자유" 의 의미가 강하다. 혹자는

> Open source is a development methodology; free software is a social movement.

라고 말한다.

### Shared Source

3rd Party 들과 계약을 통해 소스코드를 공개하는 수준을 정의한 Microsoft 의 라이센스 정책이다. 계약의 형태에 따라, 완전 Closed Source 계약, Source Code 참조 가능 계약, 수정 및 재배포 가능 계약으로 나누어질 수 있다.

## 오픈소스 소프트웨어의 장점

-   방대한 개발자 커뮤니티

    전세계 개발자들이 오픈된 토론을 통하여 해당 오픈소스 소프트웨어의 구조, 버그 패치, 기능을 계속 발전시킨다. 전세계의 많은 개발자들이 프로젝트에 참여하기 때문에, 한 개 또는 몇개의 기업이 참여한 클로즈드소스 프로젝트에 비해 훨씬 많은 개발자 리소스를 확보할 수 있게 된다.

-   빠른 개발 및 품질 검증

    전세계 개발자들이 참여하므로 개발의 속도나 버그 패치의 속도면에서 클로즈드소스 프로젝트에 비해 훨씬 빠르다.

-   더 큰 에코시스템

    클로즈드소스 프로젝트가 갖는 폐쇄형 개발 생태계에 비해서?전통적인 갑을관계에서 솔루션/용역 업체들을 줄세워 봐야 손으로 꼽을 수 있을 정도이다?, 오픈된 소스를 이용하여 상용화 서비스를 제공하는 많은 기업들이 존재한다.

-   표준 기반 소프트웨어

    POSIX, SVR4, BSD Socket 과 같은 산업 표준을 사용하므로 산업/시장간의 경계를 허물어 뜨리고, 기존 개발 결과물들의 재활용성을 높여 준다.

-   소스코드 제공

-   비용 절감

## GPL (General Public License)

[그림 유실] 

소프트웨어 개발자가 GPL 라이센스 정책을 선택한다면,

- 저작권을 표시하고
- 무보증 (No warranty) 조항을 표시하고
- GPL 로 배포됨

을 명시해야 한다.

자신이나 제 3자의 특허를 포함하여 개발한 소프트웨어를 GPL 로 배포한다면, 자신의 특허에 대한 Royalty 를 청구할 수 없고, 제 3 자도 특허에 대한 Royalty 를 청구할 수 없다. 제 3 자의 특허를 사용하여 소프트웨어를 만들고 GPL 로 배포하고자 한다면, 특허를 가진 제 3 자에게 사전 동의를 얻어야 한다. GPL 로 선언된 소스코드를 수정한 코드 (Derived Work) 는 GPL 조건을 따라야 한다. GPL 로 선언된 콤포넌트를 링크한 (Static, Dynamic Link 모두에 해당) 상위 Application 은 GPL 조건을 따라야 한다.

그런데 GPLed 소프트웨어 개발자는 자신이 채용한 알고리즘 등에 대한 특허권 존재 여부를 잘 모른다. 이런 경우에 특허권자는 GPL 소프트웨어 개발자 보다는, GPL 소프트웨어를 사용하는 기업에 특허 소송을 한다. 이는 경제논리로서, 개인보다 기업에 청구해야 돈이 나오기 때문이다. 이런 숨어 있는 특허권의 위험성을 사전에 찾아 주는 툴이 BlackDuck 社의 ProtexIP 이다.

## LGPL (Lesser GPL)

[그림 유실]

소프트웨어 개발자가 LGPL 라이센스 정책을 선택한다면,

- 저작권을 표시하고
- 무보증 (No warranty) 조항을 표시하고
- LGPL 로 배포됨

을 명시해야 한다.

LGPL 선언된 소스코드를 수정한 코드는 다시 LGPL 로 배포되어야 한다. **LGPL 선언된 콤포넌트를 수정하여 Static Link/Dynamic Link 하는 Application 은 다시 LGPL 로 배포될 의무는 없다.** 다만, 콤포넌트를 수정하여 상위 Application 에 Static Link 를 했을 경우, 수정된 LGPLed 원본 (Static Link 된 Component) 의 바이너리 코드는 제공해야 한다 (Section 6).

## Linux System Architecture

[그림 유실]

일반적으로 Linux System 은 아래 그림과 같이 Kernel Space 와 User Space 로 나눌 수 있다. Kernel 자체는 GPL 이며, Kernel 과 Static 으로 엮이는 Device Driver 도 당연히 GPL 이 되어야 한다. 반면, Kernel 과 System Call 을 통해서 접근하는 User Space 의 Application 들은 라이센스 정책을 자유롭게 취할 수 있다. 그리고, 다행히도 User Space 에서 구동하는 주요 Open Source Library 들은 99% 가 non-GPL 로 선언 되어 있어서, 이들을 Link 해서 사용할 경우 소스 공개에 의무는 없어진다.

### 대표적인 Linux Middlewares

Middleware or Library|Function|License
---|---|---
glibc|Standard C library|LGPL
libg++|Standard C++ library|LGPL
Qt|Graphics framework|LGPL/Proprietary
libjpeg|Jpeg library|IJG's free license
ffmpeg|Multimedia Framework (Codecs)|LGPL
Gstreamer|Multimedia Framework|LGPL

### libc

Android 에서는 Linux 에서 대표적인 C Runtime 인 glibc 나 uclibc 를 사용하지 않고, bionic libc 를 사용한다. 이들은 LGPL 로 선언되어 있으나, 어떤 이유에서인 지 몰라도, Android 에서는 라이센스문제가 전혀 없는 bionic 을 사용하였다. 때문에, gcc 로 컴파일되는 Native C 코드를 작성하게 되면 복잡한 NDK (Native Development Kit) 과정을 거쳐야 한다.

### Qt

QT 는 특이하게 Dual 라이센스 정책을 취하고 있다. 과거까지만 해도, [OSI(Open Source Initiative)](http://www.opensource.org/) 의 인정을 받지 못했던 QPL 이라는 오픈소스 정책과 클로즈드소스 정책의 두가지 정책을 취하고 있었다. QT 의 저작권자인 Trolltech 이 2008 년 Nokia 에 인수되고, 2009 년에서야 QT 를 LGPL QT 와 Proprietary QT 로 구분하였다.

### libjpeg

[그림 유실]

libjpeg 은 [IJG(International JPEG Group)](http://ijg.org/) 의 라이센스를 따른다. 소스를 공개할 의무는 없다.

## Linux Device Drivers

Linux 에서 Device Driver 를 작성하는 방법은 두가지가 있다.

- Direct Kernel Driver
- Binary Module

전자는 Kernel itself 라 할 수 있으므로, GPL 로 선언된 Linux Kernel 에 대한 Derived works 에 간주되고, 당연히 GPL 로 같이 배포되어야 한다.

반면, 후자는 부트 이후에 Device 가 사용될 때 로드되는 Module 방식이다.

> Modules were originally conceived as inserted extentions to a running Linux kernel.

많은 기업들이 Module driver 를 바이너리 형태로 배포하고 소스를 공개하고 있지는 않으며, 현재로서는 유일하게 Driver 소스를 공개하지 않는 방법으로 간주되고 있으나, Linux community 에서는 이 방법을 놓고 계속 논쟁 중이다. 아래 그림은 내 Ubuntu 넷북에서 Module 로 로드된 Driver 들이다.

[그림 유실]

Dynamically loadable driver module 은 Memory allocation, bus enumeration, disable/enable interrupts & preemption, networking service, debugging 등의 Kernel Service 를 접근해야 한다. 즉, Kernel 과 분리된 Standard external kernel symbol 을 통해서만 접근해야 함을 의미한다. 아래 그림은 내 넷북에서 사용 가능한 Standard external kernel symbol 들이다.

Module Driver 에서도 주의할 점이 있다. GPL 선언된 Linux Driver 를 참고해서 개발하면, 아무리 Module 로 로드한다고 해도, Derived works 로 간주되며, 이는 소스를 공개해야 한다는 것이다. Linux Driver 를 Module 로 개발하기 위해서는 From Scratch 로 개발해야 한다.
 
[그림 유실]

## 기업에서 GPLed, LPGLed 소프트웨어의 활용과 활용 사실 공개

기업에서 상용으로 GPL, LPGL 소프트웨어를 상용 제품의 탑재를 목적으로 사용할 수 있다. 이 경우, 전술한 바와 같이, GPL, LGPL 코드를 사용했음을 공개해야 한다. 단말이나 소프트웨어 패키지에 커다랗게 써 붙일 필요는 없지만, 적어도 설명서, 보증서 또는 부트 메시지 등에 표시해야 한다. 또, 소스를 공개해야 할 의무가 있는 경우에는 온/오프라인 미디어를 통해 제공해야 한다. 이러한 의무를 이행하지 않을 경우에는 FSF (Free Software Foundation) 와 같은 오픈소스 라이센스 정책 감시자들로 부터 경고를 받게 된다. FSF 와 같은 기관이 실제 법적인 행동을 취하지는 않으며, 실제 법적인 행동을 취할 수 있는 주체는 해당 소프트웨어의 저작권자이다. 기업이 오픈소스 활용 사실을 공개하지 않아서 생기는 위험은 심각한 "명예 실추"이다.

요즘은 Embedded System 에서도 Linux 나 오픈소스 소프트웨어의 활용도가 점점 높아 지고 있다. 국내 대기업들에서는 3rd Party 로 부터 공급되는 솔루션들에 대한 오픈소스가 몰고 올 수 있는 위험을 사전에 제거하고자 Blackduck 社의 ProtexIP 와 같은 솔루션을 활용하고 있다. 이 솔루션은 계속 업데이트되는 BlackDuck 본사의 DB 서버에 접근하여, 검증하고자 하는 소프트웨어 패키지의 위험 여부를 그래픽으로 표시해 주고, 대응할 수 있도록 도와 준다. Source 뿐만 아니라, Binary 도 완벽하진 않지만 잡아 낸다. 유사 툴로는 Palamida 社의 솔루션도 있다.

[그림 유실]

## RTOS 에서의 Linux Driver 참조 활용

GPL 선언된 Linux Driver 를 참조하여 RTOS Device Driver 를 개발하는 것은 절대 지양해야 한다. Linux Driver 를 참조해서 RTOS Device Driver 를 만들고 마치 직접 개발한 IP (설계자산) 인양 바이너리로 제공해서도 절대 안된다. 여기에는 두 가지 위험이 존재하는데,

- 첫째는 원작자에 대한 저작권법 위반이며,
- 둘째는 Proprietary RTOS 자체, Runtime, Proprietary Application 까지도 모두 GPL 로 간주되어 회사 내의 모든 Proprietary IP 에 대한 소스를 공개해야 해야 하는 위험

이 있다.

## 결론, 요약 정리

오픈소소 활용|라이센스|설명
---|---|---
GPL 복사/수정|GPL|수정물의 소스코드 공개
GPL Library 에 링크|GPL|Library 의 수정코드 뿐만 아니라, 이와 링크되는 Application 의 소스코드도 공개 (다행히도 99%의 Linux Runtime Library 는 non-GPL 로 선언되어 있음)
LGPL Library 에 링크|선택|의무사항 없음
Linux Kernel 과 정상적인 System Call 을 이용하는 상위 Application|선택|의무사항 없음
Linux Kernel 과 Direct Static Call 을 이용하는 상위 Application|GPL|Static link 를 사용하는 Linux device driver 는 Kernel 의 Derived works 로 간주됨으로 소스 공개
Dynamically loadable driver module (standard kernel symbols/interfaces 를 활용하는 경우)|선택|이미 GPL 로 선언된 Driver code 를 참조하지 않았다면, 소스공개 의무 없음
 
## 참고문헌

- William Weinberg and Jason Wacha, Jan. 2004, MontaVista Software, Building Embedded Applications with GPL/LGPL Software
- Wikipedia

## 덧 2016-02-06

<iframe src="//www.slideshare.net/slideshow/embed_code/key/kWKlyD9PKEsrE6" frameborder="0" width="100%" height="485px" marginwidth="0" marginheight="0" scrolling="no" style="margin: 0 auto; max-width: 100%;" allowfullscreen></iframe>
