---
layout: post
title: Android Support Media
date: '2010-02-13 06:15:55 +0900'
categories:
- work-n-play
tags:
- android
- codec
- opencore
- pvcore
--- 

[그림 유실]

Android 에서 기본으로 제공하는 A/V Codec 들이다. 물론, S/W Codec 들이며, Packet Video 에서 Contribution 한 openCORE Framework 내에 포함되어 있다. H/W Codec 을 사용하고 싶다면, 이런 S/W Codec 들을 들어 내고, H/W Codec 들을 OpenMAX IL API 로 싸서 플러그인 시켜야 한다.

위에 나열된 코덱이 아닌 다른 코덱을 넣으려면 ... 난감해 진다. 확인된 바로는 컨텐츠를 A/V 로 Demuxing 하고, 위 표에서 지원하지 않는 코덱으로 인코딩된 컨텐츠를 위한 재생하기 위한 Parser 와, 지원하지 않는 포맷으로 인코딩된 비디오를 오디오와 묶어서 파일포맷컨테이너로 만들어 주는 Composer 를 끼워 넣을 수 없는 구조로 되어 있다.

그런데... Qualcomm MSM7200 을 사용하는 HTC G1 이나 Samsung Galaxy 등은 이미 WMV 등을 탑재하고 있다.

- Qualcomm, HTC, Samsung 이 Parser 를 구현했거나,
- Packet Video 의 상용 pvCORE를 라이센스 했거나...

둘 중 하나 일 것이다.

## 참고자료

- [http://developer.android.com/guide/appendix/media-formats.html](http://developer.android.com/guide/appendix/media-formats.html)
