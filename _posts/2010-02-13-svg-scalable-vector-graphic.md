---
layout: post
title: SVG, Scalable Vector Graphic
date: '2010-02-13 13:40:01 +0900'
categories:
- learn-n-think
tags:
- 3d
- opengles
- openvg
---

[그림 유실]

SVG 는 W3C 에서 정한 2D Graphics 의 컨텐츠 형식 표준 (xml) 이다. Mobile 에서는 SVG-tiny 라는 Profile 을 사용한다. Mobile 에서 SVG Engine 을 제공하는 기업으로는 Ikivo, Bitflash 등이 유명하다.

GPU 의 하드웨어 가속을 사용하려면 Khronos Group 에서 제정한 OpenVG 라는 Media Acceleration API 가 필요하며, 이는 SVG Engine 과 엮인다. (물론, GPU 가 없을 경우, Software SVG 엔진만으로도 SVG 를 구현할 수 있다.)

상위 Application 은 OpenVG 의 Low-level API 를 직접 호출해서 2D Application 또는 2D UI 를 만들 수도 있으며, SVG Engine 의 API 를 호출할 수도 있다. 이는 3D 에서도 마찬가지이다.

<div class="spacer">• • •</div>

SVG 표준 Test vector 는 tiger.svg 이며, IE 를 제외한 현존하는 거의 대부분의 인터넷 브라우저는 SVG 파일을 재생할 수 있다. 아래 그림은 tiger.svg 를 Firefox 에서 재생하는 화면이다. Ctrl+, Ctrl- 를 이용하여, 확대 축소해 볼 수 있다.

[그림 유실]

OpenVG 로 Wrapping 한 GPU 가 있다면, 인터넷 브라우저에서 Graphic 및 Font Rendering 에서 상당한 성능향상을 기대할 수 있다.

## 참고자료

- [http://en.wikipedia.org/wiki/Comparison_of_layout_engines_(SVG)](http://en.wikipedia.org/wiki/Comparison_of_layout_engines_%28SVG%29)
- [tiger.svg](http://croczilla.com/bits_and_pieces/svg/samples/tiger)
- [http://code.google.com/p/skia/wiki/Roadmap](http://code.google.com/p/skia/wiki/Roadmap)

 
## 덧글

Android/Chrome OS 에서는 Graphic Engine 으로 200 5년에 Google 이 인수한 Skia Library 가 사용되며, OpenVG/OpenGL ES 를 모두 수용하는 것으로 이해하고 있다. 바꾸어 말하면, Skia 는 Graphic(UI) Engine 으로 볼 수 있다.
