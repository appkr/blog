---
layout: post-minimal
title: '라라벨 마이크로서비스 예제 3부'
date: 2021-02-17 00:00:00 +0900
categories:
- work-n-play
tags:
- PHP
- Laravel
- MSA
- Oauth2
image: /images/2021-02-17-uaa.svg
---

모노리틱 서비스 구조에서 마이크로 서비스 구조로 전환할 때 사용자 인증을 어떻게 통합할지에 대한 내용을 계속 이어갑니다. 이번 포스트에서는 아래 그림처럼 한 마이크로 서비스가 다른 마이크로 서비스를 호출하는 경우를 살펴볼겁니다.

![](/images/2021-02-17-uaa.puml)
<div class="text-center"><small>UAA 연동 시나리오</small></div>

전체 예제 코드는 [https://github.com/appkr/laravel-msa-example](https://github.com/appkr/laravel-msa-example)에 있습니다.

<!--more-->
<div class="spacer">• • •</div>

<div class="panel panel-default" style="width:100%; margin: auto;">
  <div class="panel-body text-center">
     <a><i class="material-icons">info</i> 이하 본문에서 줄번호가 있는 코드 박스는 모바일 뷰에서 깨집니다. 데스크탑 브라우저를 권장합니다.</a>
  </div>
</div>

## 6 구현#3 ClientCredentials 그랜트 

### 6-1 TokenProvider 구현
TBD

### 6-2 Title
TBD

## 7 정리
