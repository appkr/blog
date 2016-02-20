---
layout: post
title: Android Emulator GMS 실행 하기
date: '2010-02-13 06:58:51 +0900'
categories:
- work-n-play
tags:
- android
- gms
---

Google Mobile Service 들은 Closed Source 이다. 즉, SDK Release 에서 포함되지 않는다. Emulator 에서 Google Map, YouTube, Android Market 을 접속할 수 없다는 의미이다.

<div class="spacer">• • •</div>

Emulator 에서 GMS 에 접속하는 꼼수를 기록한다.

- [HTC 홈페이지](http://developer.htc.com/google-io-device.html#s3)를 방문하여 system image 파일을 다운로드 받는다
- 적절한 위치에 압축을 푼다.
- 압축이 풀린 system.img 파일을 실행하고자 하는 avd 패스에 넣어 준다.
- avd 를 생성할 때 System Partition Size 를 넉넉하게 잡아야 한다. 기본으로 설정된 72MB 로는 system.img 를 로드할 수 없다.
- emulator를 실행한다.

[그림 유실]

<div class="spacer">• • •</div>

## 덧글 #1

Platform 2.0, API Level 5 로 만든 AVD에서는 3G icon이 뜨지 않고, 네트워크 접속이 안된다.
 
## 덧글 #2

[http://www.androlib.com/](http://www.androlib.com/) 안드로이드 마켓에 있는 것은 거의 다 있다.
