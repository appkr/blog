---
layout: post
title: HD video & codecs
date: '2010-02-13 13:44:54 +0900'
categories:
- learn-n-think
tags:
- codec
- soc
---

Full HD Video 를 비압축된 상태로 전송하려면 초당 186Mbps 의 Bandwidth 가 필요하고, 90 분 짜리 영화 한편을 저장했을 경우 1.1 Tbyte 의 용량을 차지한다.

&nbsp;|산술 데이터량|bit|in byte|Resolution consideration
---|--:|--:|--:|--:
w1920xh1080|2,073,600|259,200|bits per frame|2073600x24bits
49,766,400|6,220,800|bitrate @30fps|49766400x30frames|1,492,992,000
186,624,000|bitrate @90min HD video|1492992000x60secx90min|8,062,156,800,000|1,007,769,600,000

<div class="spacer">• • •</div>

그런데, 실제 국내에서 상용 서비스 되고 있는 IPTV 의 경우, 영상을 H.264 로 부호화하여 전송을 하고 있으며, 필요한 Bandwidth 는 음성정보를 포함하여 대략 19Mbps 인 것으로 알고 있다. 이 차이는 H.264 부호화기 (Encoder) 가 Chroma subsampling 된 YUV4:2:0 (정식 용어로 YCbCr4:2:0) 포맷을 Camera Sensor 등의 소스로 부터 Input 받아, Motion estimation 이란 과정을 거쳐 영상을 부호화 때문이다. Motion Estimation 이란, 이전 프레임의 영상등의 정보를 바탕으로 다음 프레임의 움직임을 예측하는 알고리즘으로 대부분의 부호화기는 이 과정을 거치지만, 현재로서는 H.264 의 Algorithm 성능이 우수한 것으로 알려져 있다. H.264 부호화기는 압축 성능은 우수한 반면, 그 복잡성으로 인해 엄청난 CPU 연산량을 필요로 한다.

## 주

- `YUV` 아날로그 영상에서 사용하는 Color space 규격이다. 디지털에서는 YCbCr 로 표시해야 하지만, 일반적으로 YUV 라고 혼용해서 사용한다.
- `Color Space` 우리가 일반적으로 알고 있고 LCD 에서 사용하는 RGB, 인쇄를 위한 CMYK 등을 Color Space 라 한다.
- `Chroma Subsampling` `Y (luma)` 는 밝기를 나타내며,` UV(chroma)` 는 색상을 나타내는데, 인간의 눈은 색상보다 밝기에 더 민감하게 반응하기 때문에 UV 값을 임의로 조정하여 영상의 크기를 줄이는 기술을 말한다. 4:4:4 원본 대비, 4:2:0 의 경우 1/2~1/3 의 Bandwidth 로 데이터량을 줄일 수 있다.
- `Color Space Conversion` YUV 영상을 LCD 에서 보여주기 위해서 는 YUV 를 RGB 로 변환하는 변환기가 필요하다. 또, 영상의 크기와 LCD 의 크기가 다를 경우, 영상의 크기를 LCD 에 맞게 조정해 주는 Scaler 라는 장치도 필요하다.
