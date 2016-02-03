---
layout: post
title: Android Customized Multimedia Structure
date: '2010-02-13 11:50:56 +0900'
categories:
- work-n-play
tags:
- android
- opencore
---

이게 가능할까? openCORE 를 들어 내고, Proprietary MM Framework 로 갈아 치우는 것이 가능할까? Helix Community 에서도 유사한 시도를 하고 있다. [HelixDNA Client 를 Andorid 에 포팅 하는 프로젝트](https://porting.helixcommunity.org/2008/android)를 ...

<div class="spacer">• • •</div>

아래 그림과 같은 구조를 가진 단말이 Android Market 을 포함한 전체 Android 세상에 들어 갔을 때, 어떤 잠재적인 문제가 있을까?

[그림 유실]

## 덧글 #1. Android-Gstreamer Project

Open Source 의 장점은 이런게 아닐까 싶다. 누군가 이런 고민을 하고 있는 사람이 있었다. 좌측 그림에서 Proprietary MM Framework 를 gStreamer 로 대체하고 별도의 JavaPlayer.apk 를 개발하는 Open Source Project 를 진행하고 있었다.

Android-Gstreamer Project. 내가 속한 조직 내부에서도 그간의 결과물들을 포팅하는데 성공했다 (상당한 양의 최적화 작업을 해야 겠지만...). 특이한 점은 gStreamer 에서 바로 Surface Flinger 와 Audio Flinger 의 A/V Sync 를 사용할 수 없어서, gStreamer 에서 제공하는 Sync 를 사용하고, Sync 된 것을 Surface/Audio Flinger 로 넘겨 주는 식이다. Media Manager 에서 OpenCORE 를 거치지 않고 gStreamer Codec 을 바로 불러 쓰도록 구조화 되어 있다.
