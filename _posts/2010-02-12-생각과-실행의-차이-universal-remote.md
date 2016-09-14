---
layout: post
title: 생각과 실행의 차이, Universal Remote
slug: think-of-practice
date: '2010-02-12 17:01:41 +0900'
categories:
- learn-n-think
tags:
- arm
- mcu
---

내가 생각하던 것은 이미 있더라.

<!--more-->
<div class="spacer">• • •</div>

우리는 너무 많은 리모컨을 가지고 있다. 그래서, 풀터치가 되는 Universal Remote Controller 를 생각하고 있었다.

- 집안의 있는 모든 기기 (TV, DVD, 컴퓨터, 에어컨, 조명, ...) 를 무선으로 조작할 수 있어야 한다.
- 즉, 리모컨에 내가 가진 기기들을 등록할 수 있는 프로그래밍 기능이 있어야 한다.
- 각 기기들의 작동상태를 리모콘에서 확인할 수도 있어야 한다.
- 각 기기들을 선택했을 때 마다, 조작을 위한 리모컨 UI 는 바뀌어야 한다.

<div class="spacer">• • •</div>

하지만, 현재로서는 환경이나 기술이 이런 아이디어를 구현하기는 힘들다.

- 삼성전자 모든 TV용 만능 리모컨이 15,000원 수준이다. (8bit mcu 정도 탑재)
- 현재 리모컨들이 사용하는 IR은 양방향 데이터 전송이 불가하다.
- 가전 기기들을 구성하는 모든 인프라가 양방향 데이터 전송이 가능한 장치로 바뀌어야 한다.
- 결국, 돈이 많이 든다는 얘기다.

<div class="spacer">• • •</div>

그런데, 이미 Logitech 에서 유사한 걸 만들었더군... 하지만 내가 생각하던 것에 아주 못 미친다. 가격 들으면 까무러 친다. 거의 40 만원.

[![Universal Remote](http://img.youtube.com/vi/-TRPP4RK8J4/0.jpg)](http://www.youtube.com/watch?v=-TRPP4RK8J4)

시간이 지나면 해결되겠지만, 가전 셋트메이커들이 양방향 데이터 통신이 가능한 장치를 자신들의 셋트에 심고, 셋트들과 같이 작동하는, 내가 생각하던 통합 리모컨이 나왔으면 좋겠다. 매년 여름이 되면, 에어컨 리모컨 찾아 삼만리... 윽 정말 귀찮다.

<div class="spacer">• • •</div>

그럼 이런 공식이 적용되겠지. 리모컨용 프로세서 = ARM을 탑재한 RISC CPU.
