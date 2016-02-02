---
layout: post
title: Video Codec Quality Comparison
date: '2010-02-13 13:25:16 +0900'
categories:
- learn-n-think
tags:
- codec
---

Doom9 이라는 해외 포럼에서 IPTV 전송에 최적화된 Parameter Setting (Test Options) 으로 각 코덱별로 테스트한 영상화질을 나타낸다. 본 자료에 의하면, H.264, VP7, VP6, VC-1, DivX5 순으로 평가되었다. 본 자료에서 제시한 테스트 결과는 필자와는 무관하다.

 
## Test Vector #1 (resolution unknown)

Codec|ES Bitrate|PSNR|SSIM|Test Options
---|---|---|---|---
DivX|447 kbps|35.5729|63.49|B-frames, best quality for bitrate, MPEG quantizer
XviD|447 kbps|39.6601|64.36|MPEG quantization, Trellis quantization, Qpel, VHQ for B-frames
Nero AVC|446 kbps|40.6388|69.53|CABAC entropy coding
x.264|447 kbps|40.4423|68.24|CABAC entropy coding
VP7|446 kbps|40.5841|68.09|
VP6|446 kbps|40.2241|66.53|VP6.2 Heightened Sharpness Profile with all the default settings
VC-1|446 kbps|39.5186|64.16|Maximum keyframe distance which was set to 20 seconds
RV10|447 kbps|39.4594|62.83|

**`주)`**

- [`PSNR, Peak Signal-to-Noise Ratio`](http://en.wikipedia.org/wiki/PSNR) 원본 대비 압축된 영상의 화질을 측정하는 단위, 높을 수록 좋음.
- `SSIM` 동 자료를 발표한 연구기관에서 정한 주관적 화질 측정 단위, 높을 수록 좋음

## Test Vector # 2 (resolution unknown)

Codec|ES Bitrate|PSNR|SSIM|Test Options
---|---|---|---|---
DivX|896 kbps|42.622|77.47|상동
XviD|896 kbps|42.6654|77.95|No B-frames, Cartoon mode on, Trellis on
Nero AVC|896 kbps|43.2847|80.13|8×8 transform, 2 reference frames, deblock strength was set to 2
x.264|896 kbps|43.132|79.25|8×8 transform, 2 reference frames, deblock strength was set to 2
VP7|896 kbps|43.1338|78.86|
VP6|897 kbps|42.9876|78.35|상동
VC-1|896 kbps|42.5786|76.74|상동
RV10|896 kbps|42.5815|77.21

<div class="spacer">• • •</div>

## TI DSP 연산량

아래는 TI 64x+ Core 에서 D1(720*480) @30fps YUV 4:2:0 영상을 재생하기 위해 필요한 Codec Only 의 요구 계산량이다. 코덱은 Target System 에 맞추어 ASM/C-Level 최적화를 통해 계산량을 줄일 수 있기 때문에, 또, Target System 에 따라 계산량이 변하므로, 이 수치가 불변의 수치는 아니다. TI 64x+ DSP 에서는 H.264 대비 VC-1 이 동일한 Resolution 의 영상을 부호화/복호화하기 위한 계산량 측면에서 더 우수하다.

Video Codec|Encoder|Decoder
---|---|---
H.263/MPEG4-SP|250 MHz|100 MHz
H.264 Base Profile|410 MHz|300 MHz
H.264 Main Profile|590 MHz|450 MHz
VC-1|360 MHz|360 MHz

**`주)`**

H.263/MPEG4는 H.264/VC-1 대비 코덱의 복잡성이 낮아 계산량은 적으로 그 부호화된 이미지의 파일 사이즈는 몇 배에 달한다. 즉, 더 많은 Bitrate가 필요하며, 파일 이동 또는 네트워크 전송에서 불리하다.

## 참고자료

- FG IPTV-OD-0096, Working Document: Toolbox for content coding at 4th FG IPTV meeting
- [Video Compression: System Trade-Offs with H.264, VC-1 and other Codecs](http://www.ti.com/litv/pdf/spry088)
- [VC-1 Technical Overview](http://www.microsoft.com/windows/windowsmedia/howto/articles/vc1techoverview.aspx)
