---
layout: post-minimal
title: '내가 경험한 제품 기획'
date: 2023-11-05 09:00:00 +0900
categories:
- work-n-play
- learn-n-think
tags:
- 기획자
- 경력개발
image: /images/2023-11-05-fabless-3.png
---

세상은 두 부류의 사람으로 나눌 수 있습니다: **자본가**와 **노동자**

기업의 제무제표를 잘 들여다보면, 이 둘의 역할이 보입니다. 

[![삼성전자](/images/2023-11-05-samsung.png)](/images/2023-11-05-samsung.png)
<div class="text-center"><small>클릭하면 큰 그림을 볼 수 있습니다</small></div>

그림은 [금감원 전자공시시스템](//dart.fss.or.kr)에 공시된 삼성전자의 2022년 재무상태표입니다. 숫자가 너무 커서 읽기가 어려운데, 2022년 말 기준으로 삼성전자의 자산 규모는 448조원입니다. 이 중 93조원은 부채로 조달했고, 355조원은 자기자본으로 조달했네요. 2022년 동안의 매출은 302조원이고, 순이익이 55조원입니다.

기업이란 뜻 있는 기업가가 **자본가**로부터 투자<small class="text-muted">자본</small>를 받거나 차용<small class="text-muted">부채</small>하여 사업에 필요한 자산을 구매하여 수익 활동을 하는 것입니다. 기업은 기계장치와 같은 고정자산만으로 수익을 낼 수 없습니다. 당연히 **노동자**가 필요하죠. 노동자는 노동력 제공의 댓가로 근로 소득을 얻습니다.

기업 활동의 결과로 노동자는 근로 소득을 받아 가계를 유지하고, 주주는 자본 이득을, 채권자는 이자 수익을 얻습니다. 근로자는 근로소득세를 납부하고, 기업은 법인세를, 주주는 주식소득세를, 채권자는 이자소득세를 납부합니다. 이것이 제가 배운 가계, 기업, 정부가 돌아가는 원리입니다.

필자는 개발자로 전업하기 전에 스마트카드<small class="text-muted">T-money 카드</small>, GSM/GPRS 휴대폰 설계 및 제조<small class="text-muted">벨웨이브</small>, 범용 반도체 설계 및 제조<small class="text-muted">코아로직</small> 등 임베디드 시스템 산업에서 제품 매니저로 10년간 일했습니다. **가치 있는 제품, 즉 소비자가 기꺼이 돈을 내고 구매할 멋진 제품을 발굴하고, 그 제품을 시장에 딜리버리할 때까지의 전 과정을 책임지는 것이 제품 매니저의 역할**입니다. 

가치 있는 제품을 발굴하고 딜리버리하는 제품 매니저의 본질은 같지만, 소프트웨어 회사의 제품 매니저와는 하는 일이 다랐습니다. 이 포스트에서는 하드웨어 회사의 제품 매니저로서 일하던 당시의 시대 상황, 풀어야 했던 문제들에 대해 써보려 합니다.

<!--more-->
<div class="spacer">• • •</div>

## 대 격변의 시대

필자가 임베디드 시스템 산업에서 제품 매니저로 일하던 2002년부터 2011년까지는 대 격변기였습니다: 스마트폰, WCDMA<small class="text-muted">3G</small> 등 **모바일 혁명**과 AWS, MS, 애플, 구글을 중심으로 **클라우드 혁명**이 일어났던 시기였습니다. 

필자가 일했던 휴대폰 설계 및 제조 회사는 역사 속으로 사라졌습니다. 당시엔 GPRS/CDMA 등 2G 통신망에서 각 회사마다 고유한 운영체제와 애플리케이션을 개발하던 시절이었습니다 <small class="text-muted">Feature Phone</small>. 국내엔 삼성, LG 뿐만아니라 팬텍, VKMobile, 벨웨이브와 같은 회사들이 플레이하고, 해외에선 노키아아 전세계를 장악했었죠. 중국, 유라시아, 남미 시장을 공략하던 벨웨이브도 UMTS <small class="text-muted">Universal Mobile Telecommunication System</small>, 즉 3G 통신의 물결을 준비해야 했고, 개발 실패와 제품 경쟁력 저하로 문을 닫았습니다.

멀티미디어 반도체를 설계하는 코스닥에도 등록된 회사로 옮겼는데요. 인수한 모회사와<small class="text-muted">인수한 회사는 삼성전자와 관련된 그룹</small>의 역학 관계, HLOS <small class="text-muted">High-Level OS, Symbian, WinMo, Linux/Android 등</small> 개발 실기(失期)와 글로벌 시장에서의 경쟁력 저하 등으로 중국계 회사에 팔렸다가 지금은 문을 닫았습니다. 

사실 외부적인 요인들이 더 컸죠. 스티브잡스의 **아이폰**은 전세계를 충격에 빠뜨렸습니다: 블랙베리, 윈도모바일, 노키아 뿐만아니라, MP3 Player, PMP, 차량용 네비 산업까지 초토화시켰으니까요. 게다가 **안드로이드** 플랫폼은 하드웨어를 표준화시켜버렸습니다: 과거엔 각자의 운영체제로 각자의 특화된 애플리케이션을 담아 매력적인 폼팩터로 고객의 지갑을 열었습니다만, 안드로이드는 우리 플랫폼을 구동시키려면 요런 저런 하드웨어 사양으로 설계해야 해~라며 그간의 관행을 완전 뒤집어 버렸죠.

주) 노키아의 사업 철수로 쏟아져 나온 개발자들의 게임 스타트업을 차리면서 핀란드의 GDP 구성이 바뀌었다. 안드로이드 출시로 직장을 잃은 또는 자발적으로 퇴사한 개발자들이 앱 스토어의 시대를 열었다. 

## 2010 국내 팹리스 업계의 상황

폐업한 회사라 이하의 자료는 공개해도 괜찮다고 판단했습니다. 

<div class="grid-container">
    <div class="grid-item">
        <a href="/images/2023-11-05-fabless-1.png" data-toggle="lightbox" data-title="2023-11-05-fabless-1">
            <img src="/images/2023-11-05-fabless-1.png" alt="2023-11-05-fabless-1"/>
        </a>
    </div>
    <div class="grid-item">
        <a href="/images/2023-11-05-fabless-2.png" data-toggle="lightbox" data-title="2023-11-05-fabless-2">
            <img src="/images/2023-11-05-fabless-2.png" alt="2023-11-05-fabless-2"/>
        </a>
    </div>
    <div class="grid-item">
        <a href="/images/2023-11-05-fabless-3.png" data-toggle="lightbox" data-title="2023-11-05-fabless-3">
            <img src="/images/2023-11-05-fabless-3.png" alt="2023-11-05-fabless-3"/>
        </a>
    </div>
    <div class="grid-item">
        <a href="/images/2023-11-05-fabless-4.png" data-toggle="lightbox" data-title="2023-11-05-fabless-4">
            <img src="/images/2023-11-05-fabless-4.png" alt="2023-11-05-fabless-4"/>
        </a>
    </div>
    <div class="grid-item">
        <a href="/images/2023-11-05-fabless-5.png" data-toggle="lightbox" data-title="2023-11-05-fabless-5">
            <img src="/images/2023-11-05-fabless-5.png" alt="2023-11-05-fabless-5"/>
        </a>
    </div>
    <div class="grid-item">
        <a href="/images/2023-11-05-fabless-6.png" data-toggle="lightbox" data-title="2023-11-05-fabless-6">
            <img src="/images/2023-11-05-fabless-6.png" alt="2023-11-05-fabless-6"/>
        </a>
    </div>
</div>
<div class="text-center"><small>클릭하면 큰 그림을 볼 수 있습니다</small></div>

그림을 보면 당시 국내 팹리스 <small class="text-muted">제조 기반 없이 반도체 설계만 전문으로 하는 회사</small> 산업의 상황을 들여다 볼 수 있습니다: 그간에 저가로만 경쟁하던 차이완 <small class="text-muted">차이나 + 타이완</small>들의 기술 경쟁력이 높아지면서 선진 제조업체들과의 틈새에 낀 **넛 크래커** <small class="text-muted">넛 크래커(nut-cracker)는 호두를 양쪽에서 눌러 까는 호두까기 기계를 말하는데 한 나라가 선진국보다는 기술과 품질 경쟁에서, 후발 개발도상국에 비해서는 가격 경쟁에서 밀리는 현상을 지칭할 때 쓰임</small> 상황이었습니다.

<div class="grid-container">
    <div class="grid-item">
        <a href="/images/2023-11-05-corelogic-1.png" data-toggle="lightbox" data-title="2023-11-05-corelogic-1">
            <img src="/images/2023-11-05-corelogic-1.png" alt="2023-11-05-corelogic-1"/>
        </a>
    </div>
    <div class="grid-item">
        <a href="/images/2023-11-05-corelogic-2.png" data-toggle="lightbox" data-title="2023-11-05-corelogic-2">
            <img src="/images/2023-11-05-corelogic-2.png" alt="2023-11-05-corelogic-2"/>
        </a>
    </div>
    <div class="grid-item">
        <a href="/images/2023-11-05-corelogic-3.png" data-toggle="lightbox" data-title="2023-11-05-corelogic-3">
            <img src="/images/2023-11-05-corelogic-3.png" alt="2023-11-05-corelogic-3"/>
        </a>
    </div>
    <div class="grid-item">
        <a href="/images/2023-11-05-corelogic-4.png" data-toggle="lightbox" data-title="2023-11-05-corelogic-4">
            <img src="/images/2023-11-05-corelogic-4.png" alt="2023-11-05-corelogic-4"/>
        </a>
    </div>
    <div class="grid-item">
        <a href="/images/2023-11-05-corelogic-5.png" data-toggle="lightbox" data-title="2023-11-05-corelogic-5">
            <img src="/images/2023-11-05-corelogic-5.png" alt="2023-11-05-corelogic-5"/>
        </a>
    </div>
</div>
<div class="text-center"><small>클릭하면 큰 그림을 볼 수 있습니다</small></div>

이 상태에서 틈새를 찾고, 서두에 말한 기업의 존재 이유를 달성할 제품을 발굴하여, 턴어라운드를 달성하는 것이 제품 매니저의 역할이었죠.

## 제품 매니저의 업무 

요즘은 `Jira`, `Slack`, `Figma`, `Google Suite` 와 같은 도구를 이용해서 업무를 관리하지만, 저 때는 폴더, 이메일, 그룹웨어, MS Office 등이 최선이었습니다. 그림의 두번재 레인의 `YYYYMM_OOOO`로 된 폴더가 프로젝트였고, 각 프로젝트 하위에는 산출물들이 보일겁니다.

[![폴더](/images/2023-11-05-product-manager.png)](/images/2023-11-05-product-manager.png)
<div class="text-center"><small>클릭하면 큰 그림을 볼 수 있습니다</small></div>

제품 매니저의 최종 결과물은 **제품 기획서**와 **제품**입니다.

- (기술 지식이 필요하므로) 엔지니어 출신이 제품을 기획한다
- (제조가 수반되므로) 제품 원가 개념을 잘 알아야 한다
  - 천문학적 개발비가 든다
  - 출시되면 제품 수정이 어렵다
  - 프로젝트를 잘 관리해야 한다: 돈-사람-시간
- 하드웨어의 제품 수명은 3~5년이다
  - 3~5년 뒤를 예측해서 제품을 기획한다
  - 메가 트렌드를 봐야 한다
  - 경쟁사의 제품 로드맵을 정확히 꿰고 있어야 한다

## 제품 기획서 훑어보기

아래는 모바일TV 전용 제품 기획서 풀 버전입니다. <small class="text-muted">기구, 폼팩터, 재질, GUI, 기본 탑재 애플리케이션, 메뉴 트리 구성 등 추가적인 부분들이 더 있지만</small> 휴대폰 회사의 제품 기획서도 이와 비슷합니다.

![모바일TV 전용 제품 기획서 풀 버전](/images/2023-11-05-hawk.png)
<div class="panel panel-default" style="width:100%; max-width: 600px; margin: 1em auto;">
  <div class="panel-body text-center">
    <a href="/files/2023-11-05-hawk.pdf">
      <i class="material-icons">open_in_browser</i>
      브라우저에서 슬라이드 열기
    </a>
  </div>
</div>

이런 내용들이 담겨 있을 겁니다.

### 기획 의도 및 기대 효과 (“왜?”, p4)

모바일TV 애플리케이션용 A/V 디코딩에 최적화된 ASSP <small class="text-muted">Application Specific Standard Product</small> 시장에서 오랫동안 선전했던 기존 제품의 시장 경쟁력이 떨어지고, 기존 제품 출시 이후 신규로 나온 시장<small class="text-muted">일본의 ISDB-T 1Seg, 중국의 CMMB 규격</small>까지 커버하는 초저가 제품으로 기획했네요. 고객의 제품 적용 편의 및 고객의 개발 기간을 단축을 위해 풀 모듈로 패키징합니다. 7억원의 NPV, 20%의 IRR을 기대합니다.

### 목표 시장 선정과 시장성 (“어디서?”, "왜?", p5~p8)

이 제품은 기획 의도에서 목표 시장에 대한 힌트가 있어서 목표 시장 선정 측면에서는 수월했었습니다.

메가트렌드, 5 Forces의 역학 관계, 내부 기술 역량 등 다양한 변수를 고려해서 이익을 낼 수 있는 시장을 선정합니다. 시장을 크게 잡으면 제품이 커지고, 따라서 개발비/기간이 올라갑니다. 시장이 너무 작으면 기대 이익이 적어서 개발비를 회수하지 못합니다. 이 기획에서는 Phone용 모바일 TV, 대형 TV 시장을 제외한 중간 사이즈의 디바이스를 목표 시장으로 하고 있네요. 데이터, 분석력, ... 중요합니다만, 이 지점에서 제품 매니저의 **촉**과 이 제품은 된다라는 **자신감**이 큰 역할을 합니다.

당시 Mobile TV 애플리케이션용 A/V 디코딩에 최적화된 ASSP 풀 모듈 시장 규모를 23.7백만개(3년 합계)로 예측했네요.
 
### 제품 기능명세 (“무엇을?”, p9)

그래서 뭘 만들건데?라는 질문에 대한 답입니다. 

IP <small class="text-muted">설계 자산</small>를 하나 더 추가하면, 공략할 수 있는 시장 범위가 늘어납니다. `SDIO`를 하나 더 추가함으로써, WiFi를 탑재하기를 원하는 고객에게도 제품을 팔 수 있게 됩니다. 대신 5만 Gate Count가 추가되고 그로 인한 웨이퍼 면적 증가로 제품당 원가가 0.78Cent 증가합니다. 결정이 필요한 지점이겠죠?

### 개발 계획 (p10)

대략적인 개발 일정과 제품 개발비를 추정해 봅니다. 개발비 24.7억원, 최초로 판매 가능한 상태까지는 1년 정도를 잡았네요. 

제품 매니저가 독단적으로 정했을까요? 당연히 개발팀과 티키타가했겠죠? 세상에 1원에 만들 수 있다고 공격적으로 말하면 사업성이 안 나오는 제품은 없을 겁니다. 한편 개발하는데 10년이 걸린다고 보수적으로 말하면 사업성이 나오는 제품은 없을 겁니다. 기획 시점의 일정 목표, 개발비등은 그냥 목표입니다. 당연히 정확하지않고, 일을 진행하면서 조정해야 합니다. 조정하더라도 항상 목표는 꼭 필요하죠. 

### 제품 판가 (p11)

마케팅 과목에서 4P <small class="text-muted">Product, Price, Place, Promotion</small>를, 경제학에서 수요공급법칙을 배우며 가격이란 걸 배웠죠. 교과서에는 가격을 결정하는 방법도 참 여러 가지였던 것 같아요. 이 제품은 표준 가격을 3.5달러로 잡았었네요. 

### 매출 및 이익 계획 (p12~p13)

제품 수명 주기 동안 총 7백만개를 팔아서 286억원의 매출을 하겠다고 했군요. 위에서 공략 가능 시장 규모를 23.7백만개로 잡았으니 30%의 시장을 점유하겠다는 계획입니다. 기존 제품을 사용하던 고객 위주로 이 매출을 달성하겠다는 계획이군요. 

기존에 타사의 제품을 쓰다가 어느날 갑자기 우리 제품으로 갈아탄다? 사실 하드웨어는 러닝 체인지라는 것이 매우 어렵습니다. 게다가 고객 제품은 여전히 수명이 남아 있을 수 있고, 우리의 제품 출시로 인해 신제품을 설계할 것이라는 보장도 없습니다. 이 부분은 필자의 전문 분야가 아닌 영업팀의 영역입니다. 자동차, 보험 영업이 어렵다지만, 전방 시장도 하드웨어인 반도체 시장도 만만치 않은 것 같더군요.

### 사업성 분석 (p14~p15)

이상의 모든 계획으로부터 돈을 벌 수 있을까요? 서두에 언급한 기업의 역할을 다할 수 있을까요?

### 시장 진입 및 경쟁 전략 (p16~p17)

싸워서 터지지 않을 묘안을 제시해야합니다. 앞서도 언급했지만 <small class="text-muted">개발비가 커서</small> 다양한 시장을 공략할 수 있도록 제품을 좀 크게 만들고, 일부 기능을 (비)활성하도록 패키징을 달리하며 다른 제품인 것처럼 판매하는 것이 당시의 관례였습니다.

이 제품은 이런 관례를 버리고, 전용 제품으로 만들어 가성비를 추구하는 것이 컨셉이었습니다. 게다가 고객의 하드웨어 보드 실장 공간을 줄여 더 예쁜 폼 팩터를 설계할 수 있는 자유도도 제공하고자 했습니다.

### 핵심 성공 요인, 위험 요소, 위험 회피 계획 (p18)

시장엔 항상 불확실성이 존재합니다. 조직도 마찬가지입니다.

## 결론

기획서 내의 모든 문장은 왜?라는 챌린지를 받습니다. 하루 종일 조사하고 팀들과 인터뷰하고 밤새 정리해서 회의실에 들어가면 깨지기 일쑤였습니다.

제품 매니저 혼자서 이상의 모든 결정을 하지 않습니다. 치열하게 논쟁하고 조율하는 과정을 거쳐서 모두의 합의를 이끌어 내야 합니다. 화두를 던지고, 그 과정을 온전하게 이끌고 가야 하는 사람이 제품 매니저입니다.

> 세상에 쉬운 일은 없다.

<style>
    /* 기본 스타일 */
    .grid-container {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 10px;
    }

    .grid-item {
        text-align: center;
        padding: 10px;
        border: 1px solid #ccc;
    }

    /* 좁은 화면에서 레이아웃 변경 */
    @media screen and (max-width: 768px) {
        .grid-container {
            grid-template-columns: repeat(1, 1fr);
        }
    }
</style>
