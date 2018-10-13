---
layout: post-minimal
title: 'Linux "top" cheatsheet'
date: 2018-10-13 00:00:00 +0900
categories:
- cheatsheet
tags:
- DevOps
- Linux
image: https://asciinema.org/a/206328.png
---

보통 개발용 컴퓨터에서는 `htop`처럼 좀 더 편리한 프로세스 모니터 도구를 사용하지만, 운영 서버에는 서비스에 불필요한 바이너리는 설치하지 않는게 좋죠. 해서, 특히 서비스 장애와 같이 급박한 상황에 운영 서버에 SSH in 해서 `top`을 이용하려면 바보가 된 느낌을 종종 받습니다.

이 포스트에서는 바닐라 리눅스 환경에서 사용 빈도가 높은 `top` 사용법만 정리해봤습니다. 우분투 16.04를 사용했는데요, ~~CentOS도 같을 거라 생각합니다~~ CentOS는 조금 다릅니다, 댓글로 남깁니다.

```bash
$ cat /etc/issue
# Ubuntu 16.04.3 LTS \n \l

$ top
```

## 전체 요약

- Help
  - <kbd>h</kbd>: 도움말
- Display
  - <kbd>Z</kbd>: 칼라 설정
  - <kbd>t</kbd>: CPU 통계 뷰 토글
  - <kbd>m</kbd>: 메모리 통계 뷰 토글
  - <kbd>0</kbd>: Zero value(0) 뷰 토글
  - <kbd>b</kbd>: 하이라이트 토글
  - <kbd>x</kbd>: 활성 필드 표시 토글
  - <kbd>y</kbd>: 활성 프로세스 토글
  - <kbd>c</kbd>: 커맨드 상세 표시 토글
  - <kbd>V</kbd>: 프로세스간 부모/자식 관계 표시
- Action
  - <kbd>W</kbd>: 설정 저장
  - <kbd>k</kbd>: 프로세스 중단하기
- Navigation & Sorting (default: desc)
  - <kbd><</kbd>, <kbd>></kbd>: 활성 필드 네비게이션
  - <kbd>N</kbd>: `PID` 필드를 활성으로 변경
  - <kbd>M</kbd>: `%MEM` 필드를 활성으로 변경
  - <kbd>P</kbd>: `%CPU` 필드를 활성으로 변경
  - <kbd>T</kbd>: `TIME+` 필드를 활성으로 변경
- Search & Filter
  - <kbd>L</kbd>: 검색
  - <kbd>o</kbd>: 필터, e.g. COMMAND=apache, !COMMAND=apache, %MEM>0.1, ..
  - <kbd>u</kbd>: 사용자 이름으로 필터
  - <kbd>ctrl</kbd> + <kbd>O</kbd>: 현재 적용된 필터
  - <kbd>=</kbd>: 필터 해제

<!--more-->
<div class="spacer">• • •</div>

각 키 스트로크에 `top` 화면이 어떻게 반응하는지 Asciinema로 찍었습니다. 

## Help
- <kbd>h</kbd>: 도움말
<script src="https://asciinema.org/a/206306.js" id="asciicast-206306" async></script>

## Display
- <kbd>Z</kbd>: 칼라 설정
<script src="https://asciinema.org/a/206329.js" id="asciicast-206329" async></script>
- <kbd>t</kbd>: CPU 통계 뷰 토글
<script src="https://asciinema.org/a/206311.js" id="asciicast-206311" async></script>
- <kbd>m</kbd>: 메모리 통계 뷰 토글
<script src="https://asciinema.org/a/206312.js" id="asciicast-206312" async></script>
- <kbd>0</kbd>: Zero value(0) 뷰 토글
<script src="https://asciinema.org/a/206313.js" id="asciicast-206313" async></script>
- <kbd>b</kbd>: 하이라이트 토글
<script src="https://asciinema.org/a/206314.js" id="asciicast-206314" async></script>
- <kbd>x</kbd>: 활성 필드 표시 토글
<script src="https://asciinema.org/a/206315.js" id="asciicast-206315" async></script>
- <kbd>y</kbd>: 활성 프로세스 토글
<script src="https://asciinema.org/a/206316.js" id="asciicast-206316" async></script>
- <kbd>c</kbd>: 커맨드 상세 표시 토글
<script src="https://asciinema.org/a/206317.js" id="asciicast-206317" async></script>
- <kbd>V</kbd>: 프로세스간 부모/자식 관계 표시
<script src="https://asciinema.org/a/206318.js" id="asciicast-206318" async></script>

## Action
- <kbd>W</kbd>: 설정 저장
- <kbd>k</kbd>: 프로세스 중단하기
<script src="https://asciinema.org/a/206319.js" id="asciicast-206319" async></script>


## Navigation & Sorting (default: desc)
- <kbd><</kbd>, <kbd>></kbd>: 활성 필드 네비게이션
<script src="https://asciinema.org/a/206320.js" id="asciicast-206320" async></script>
  - <kbd>N</kbd>: `PID` 필드를 활성으로 변경
  <!--206321-->
  - <kbd>M</kbd>: `%MEM` 필드를 활성으로 변경
  <!--206322-->
  - <kbd>P</kbd>: `%CPU` 필드를 활성으로 변경
  <!--206323-->
  - <kbd>T</kbd>: `TIME+` 필드를 활성으로 변경
  <!--206324-->

## Search & Filter
- <kbd>L</kbd>: 검색
<script src="https://asciinema.org/a/206325.js" id="asciicast-206325" async></script>
- <kbd>o</kbd>: 필터, e.g. COMMAND=apache, !COMMAND=apache, %MEM>0.1, ..
<script src="https://asciinema.org/a/206326.js" id="asciicast-206326" async></script>
- <kbd>u</kbd>: 사용자 이름으로 필터
<script src="https://asciinema.org/a/206327.js" id="asciicast-206327" async></script>
- <kbd>ctrl</kbd> + <kbd>O</kbd>: 현재 적용된 필터
<script src="https://asciinema.org/a/206328.js" id="asciicast-206328" async></script>
- <kbd>=</kbd>: 필터 해제
