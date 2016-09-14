---
layout: post
title: 제 3 자에 의한 Android Market
slug: 3rd-party-android-market
date: '2010-02-13 15:33:29 +0900'
categories:
- around-me
tags:
- android
- opensource
---

## Android Market 에 대한 사람들의 착각

많은 사람들의 Android 관련 착각 중에 하나가, Android Market/Maps/Youtube 와 같은 Google Mobile Service 가 Open Source Android Platform 에 포함되어 있을 것이라는 것이다. 이들은 Google 이 엄격하게 통제하는 Closed Source 이다. 즉, Google 과 이들 Closed Source 사용권에 대한 합의 없이, [http://source.android.com](http://source.android.com) 에서 받은 소스로 단말을 개발한다면, Google 이 제공하는 Killer App 들을 사용할 수 없다는 의미이다.

[그림 유실] Google Mobile Service (Market, Map, Youtube, ...)의 사용

## Google 의 Android 포지셔닝 및 라이센스 정책

Google 은 Android 를

> 운영체제와 미들웨어 및 폰북 등 주요 Java Application 을 포함한, '모바일폰'을 위한 Full Software Stack

으로 정의 한다. '모바일 폰' 용으로만 Android를 포지셔닝 한다는 의미이다. Google 은 아래 표와 같이 3 가지의 라이센스 정책을 가지고 있다.

라이센스 정책|설명|특징|차별화 포인트
---|---|---|---
GED-Google Experience Device|사업자나 제조사가 임의로 Google Apps.를 삭제할 수 없음<br/> Google Apps. 의 Source가 제공됨<br/> HTC G1 등 사업자 향으로 출시되는 모델들|What Google wants<br/> 저가 외엔 차별 포인트 발굴 어려움->Featurephone 시장 일부 대체|기구/하드웨어 제외하면 UI/Home Screen 외엔 차별화 힘듦
GMS-Google Mobile Service|사업자나 제조사가 Google Apps. 삭제 가능 -> 현재로선 사업자 제조사의 Andorid Killer App 이 준비되어 있지 않은 상태<br/>
Google Apps. 의 Binary가 제공됨<br/> HTC Hero, Moto DROID|What MNO & Dev. Mfg. wants<br/> 사업자나 제조사는 자체 커뮤니티를 발전시키려고 함<br/> JIL Widget Platform, SKAF|UI를 포함한 전체 구조를 뜯어 고치고, 필요시 사업자/제조사 Proprietary Layer 탑재
Open Source|Google Apps. 사용 불가<br/> ZiiLabs ZiiEgg, OESF|Google에서 신경쓰지 않는 시장<br/> 용산 PC조립시장과 유사하게 진화할 것 (Software의 표준화가 Hardware의 표준화를 Push->좀 심하게 말하면, 보드사서 기구만 끼우고 Android 깔면 작동)|자유도 가장 높음

<!--more-->

## Google 의 대응

- Google은 시장의 분산 (Fragmentation) 으로 인해, Android 의 집중력이 분산되는 것을 원하지 않음.
- WindRiver 社를 통해 CTS (Compatibility Test Suite) 를 개발 중이고, 2010 년에 배포할 예정->별도의 인증마크를 제공할 지는 공개되지 않았으나, CTS 를 통과하지 못한 단말은 Android 시장 및 Ecosystem 에서 자연도태 시키겠다는 의미로 해석 됨.
- Google 이 Hardware 를 직접 만들고 있다는 루머가 돌고 있음

Android 는 Linux Kernel 부분은 GPL 로, 그 상위는 Apache License 로 구성하고 있다. 즉, 누구나 갖다 쓰는데 제약이 없다는 의미이고, 이는 곧 업체간의 소프트웨어의 차별화가 힘들다는 의미이기도 하다.

## 컨수머 기기에서의 Android

Android를 컨수머 기기에서 사용하면서 Google 이 전세계를 대상으로 구축한 3rd Party Indie App. 개발자들의 Ecosystem 의 이득을 얻겠다는 것(무임승차)은 염치 없는 이야기다. Open Source 방식에서는 Android Market 을 사용할 수 없다는 의미이다. 최근에 공개한 Google Maps Navigation 도 Android Market 을 통해서만 무료로 다운로드 받을 수 있다. 즉, Google 의 정책이 변하지 않는 한, GED 나 GMS 계약을 맺은 Android Phone 에서만 가능하다는 말이다. 만약 어둠의 경로에서 각 App 들의 apk 가 돌고 있고, 이를 불법으로 탑재할 용기가 있는 간 큰 컨수머 기기 제조사가 있다면 모를까?

## 진퉁과 짝퉁, 제 3자에 의한 Android Market

AppStore 에서 판매를 목표로 하는, 전세계의 많은 Indie App. 개발자들은 Apple, Google, Blackberry, Palm, Microsoft 뿐만 아니라, 국내 사업자/제조사들의 AppStore 를 저울질하고 있다 (물론 개발언어는 전부 다르다). 이들의 선택 기준은 누적 단말 판매 대수 및 향후 전망, 즉, '얼마나 큰 잠재시장이 있느냐?' 이다. 3 천만대의 인프라를 목표로 할 것인가? 1 천만대의 인프라를 목표로 할 것인가? 말이다.

그런데, Google 은 특이하게 아직 제 3 자에 의한 AppStore 운영을 막지 않고 있다. Android 내에서는 이 Indie 개발자들이 어느 시장에 올릴 지 다시 고민을 하게 된다. 물론, Google 이 운영하는 Android Market 을 선택할 것이다. 그런데, Android Ecosystem 의 결집력을 약화시키고 시장이 분산될 수 있음에도 불구하고, 아직 까지 이들을 통제하지 않는 Google 의 속셈은 무엇일까? Indie 개발자들이 몰리지 않을 것이고 전혀 위협적이지도 않으므로, 이런 제 3자의 Market 은 자연도태될 것이라 생각하는가?

그런 면에서, MiKandi.com 은 참 재미있다. PC 시장 (3억대/년, x86 Architecture 판매 수량 참조) 에서 성인물 컨텐츠의 시장 규모를 생각한다면, 급성장하는 Smartphone (휴대폰 전체 12억대/스마트폰 1억 5천만대 @2008, 스마트폰 '09~'13 CAGR 20% 이상) 에서의 성인물 컨텐츠 시장은 엄청나리라. Google 이 속으로 낄낄대고 있는 것은 아닐지, ["Android Phone 에서는 성인 게임과 야동도 볼 수 있다고... 그래서, 더 많은 서비스/고객 베이스를 가질 수 있다고... "](http://www.androidfootprint.com/2008/10/joy-of-techs-take-on-iphone-vs-android/%29)

한가지 더. 컨수머 기기들에게는 이런 제 3 자에 의한 Market 이 좋은 소식이지만, 얼마나 양질의 개발자가 몰리고, 얼마나 양질의 App 들이 올라 올지는 미지수다.

- slideme.org 
- andappstore.com
- mikandi.com

## 잡소리 - 한국 소프트웨어 개발자

Android 와 같은 Software Framework 의 표준화는 Hardware 의 표준화를 촉진한 것 뿐만 아니라, 소프트웨어 개발자의 일자리도 뺏아 갔다.

좀 심하게 말하면, 이제 점점 더 단말개발사의 소프트웨어 개발자의 역할은 자신의 Custom Hardware 에 따른 Device Driver 를 개발하고, Andorid 와 같은 표준화된 Framework 이 받아 들일 수 있도록 HAL (Hardware Abstraction Layer) 작업만 해 주는 일로 한정될 것이다. 왜냐하면, 상위의 표준화된 Framework 는 그냥 돈다는 얘기다 (실제로는 모든게 완벽하게 "그냥" 돌지는 않는다). 제조사의 제품 차별화를 위해 단말에 Built-in 된 Killer App 을 개발하는 일을 제외하면, 대부분의 App 은 Open Market 의 3rd Party Indie App 개발자가 개발해 준다. 사실, 과거에 폐쇄된 개발 환경에서 기획자 몇 명의 아이디어로 개발한 App 과 개방된 개발 환경에서 전세계 수천만의 기상천외한 아이디어로 개발한 App 중 시장에서 누가 승리할 것 같은가?

Android 와 같은 표준 Framework 의 Architecturing 은 Google 의 핵심 엔지니어들이 설계하고, 인건비가 저렴하면서 똑똑한 중국/인도 엔지니어들이 코딩한다. 작년 인도 Bangalore 를 방문하고 3가지에 놀랐다. 첫째는 인도 인프라의 낙후성에 놀랐고, 두번째 인도 소프트웨어 엔지니어들이 Reference Code 없이 From Scratch 로 개발하는 것에 놀랐고, 마지막으로 인도 소프트웨어 엔지니어들이 변호사 급의 대우를 받는 것에 놀랐다.

한국의 소프트웨어 개발자들은 어떻게 생존해야 할 것인가? 어떤 역량을 개발하여 점점 글로벌화 되어가서 국경이 없어 지는 소프트웨어 엔지니어 시장에서 자신을 차별화시키고, Career Path 를 어떻게 설계해야 할 것인가?

## 덧 2010-07-17

2.0 Eclair 이후 부터, [CTS (Compatibility Test Suite)](http://source.android.com/compatibility/cts-intro.html) 인증을 받으면, 비 휴대폰 단말도 Market 을 비롯한 GMS App 들을 라이센스 받아 탑재할 수 있다.
