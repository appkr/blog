---
layout: post-minimal
title: '페이스북으로 데스크탑 라이브 스트리밍 하기' 
date: 2016-07-21 00:00:00 +0900
categories:
- work-n-play
tags:
- streaming
- 개발자
---

최근 페이스북에 추가된 훌륭한 기능 중에 하나가 '라이브'이다. 그런데 모바일 페이스북에서만 가능하고, 데스크탑의 브라우저를 통해 접속한 페이스북에서는 불가능한다. 이 포스트에서는 데스크탑 스크린을 페이스북을 통해 라이브 스트리밍하는 방법을 다룬다. 라이브 코딩 등의 목적으로 활용하면 좋을 듯 하다. 

<!--more-->
<div class="spacer">• • •</div>

## 1. 툴 체인 준비 

데스크탑을 스트리밍하려면 두 가지가 필요하다. 

1.  데스크탑 화면을 캡처하는 도구
2.  캡처된 화면을 스트리밍할 서비스(페이스북)

### 1.1. Open Broadcaster Software(OBS)

OBS는 무료로 쓸 수 있는 오픈소스 화면 캡처 도구다.

```sh
$ brew tap caskroom/cask # Cask tap을 추가하지 않았다면.
$ brew cask install obs --appdir=/Applications
```

홈브루를 쓰지 못한다면, 직접 [다운로드](https://obsproject.com/) 받아 설치하면 된다. 

### 1.2. 페이스북 라이브 스트리밍 스타터 개발

서두에 말했다시피 데스크탑에서 페이스북 라이브를 시작하는 UI가 없다. UI만 없을 뿐 API는 열려 있다.

#### 1.2.1. 개발자가 아니라면

1.2.2. 절은 그냥 무시하라. 이 블로그에 만들어 놓은 [Facebook Live Streaming Starter](http://blog.appkr.kr/live/)에서 <kbd>Create Live Stream To Facebook</kbd> 버튼을 이용하면 된다.

#### 1.2.2. 개발자라면

##### 1단계 페이스북에 앱 등록

[https://developers.facebook.com/quickstarts/?platform=web](https://developers.facebook.com/quickstarts/?platform=web) 주소를 방문하여 앱 등록 절차를 거친다. 

앱 등록을 마치면 `앱 ID`가 발급된다.

[![페이스북 앱 대시보드](/images/2016-07-21-img-01.png)](/images/2016-07-21-img-01.png)

##### 2단계 스타터 페이지 개발

이제 로컬에서 코드 에디터를 열고 HTML 페이지를 만든다. 자바스트립트에서 `YOUR_APP_ID`라 자리표시해 놓은 부분을 1단계에서 얻은 본인의 `앱 ID`를 교체한다.

```html
<!--// whatever/index.html -->

<!DOCTYPE html>
<html>
<head>
  <title>Facebook Live Streaming Starter</title>
</head>
<body>
  <button id="liveButton">
    Create Live Stream To Facebook
  </button>

  <script>
    // 페이스북 SDK 임포트 및 초기화
    // https://developers.facebook.com/docs/javascript/quickstart 
    // 에서 최신 스크립트를 확인하고 사용하시길 권장한다.
    window.fbAsyncInit = function() {
      FB.init({
        appId: YOUR_APP_ID,
        xfbml: true,
        version: 'v2.5'
      });
    };

    (function(d, s, id){
      var js, fjs = d.getElementsByTagName(s)[0];
      if (d.getElementById(id)) {return;}
      js = d.createElement(s); js.id = id;
      js.src = "//connect.facebook.net/en_US/sdk.js";
      fjs.parentNode.insertBefore(js, fjs);
    }(document, 'script', 'facebook-jssdk'));

    // 페이스북 라이브 스트리밍 스타터
    // https://developers.facebook.com/docs/videos/live-video-api#golivedialog
    // 에서 최신 스크립트를 확인하고 사용하시길 권장한다.
    document.getElementById('liveButton').onclick = function() {
      FB.ui({
        display: 'popup',
        method: 'live_broadcast',
        phase: 'create',
      }, function(response) {
        if (!response.id) {
          alert('dialog canceled');
          return;
        }
        alert('stream url:' + response.secure_stream_url);
        FB.ui({
          display: 'popup',
          method: 'live_broadcast',
          phase: 'publish',
          broadcast_data: response,
        }, function(response) {
          alert("video status: \n" + response.status);
        });
      });
    };
  </script>
</body>
</html>
```

이렇게 만든 페이지는 페이스북과 통신할 수 있는 상태여야 하므로, 인터넷에 올려야 한다(e.g. 깃허브 페이지 등).

[![페이스북 라이브 스트리밍 스타터 페이지](/images/2016-07-21-img-02.png)](/images/2016-07-21-img-02.png)

## 2. 방송하기

### 2.1. 스타터 페이지

앞 절에서 만든 스타터 페이지에서 <kbd>Create Live Stream To Facebook</kbd> 버튼을 누른다. 두 개의 팝업 창이 순차적으로 뜬다.

첫번째 팝업에서는 그냥 <kbd>다음</kbd> 버튼을 누른다.

[![페이스북 라이브 스트리밍 팝업 #1](/images/2016-07-21-img-03.png)](/images/2016-07-21-img-03.png)

두번째 팝업에서 `스트림 키`를 복사한다.

[![페이스북 라이브 스트리밍 팝업 #1](/images/2016-07-21-img-04.png)](/images/2016-07-21-img-04.png)

### 2.2. OBS 설정

#### 1단계

OBS를 열고 캡처할 소스를 정한다. 화면 전체를 캡처하려면 `Display Capture`, 특정 창만 캡처하려면 `Window Capture`, 웹캠을 캡처하려면 `Video Capture Device`를 선택한다. 영상 믹싱도 가능하고, 별도 마이크를 이용할 수도 있다. UI가 직관적이어서 눈으로 보면 금방 이해할 수 있을 것이다.

#### 2단계 

OBS UI에서 <kbd>Settings</kbd> 버튼을 눌러, `Stream` 메뉴를 선택하고 다음과 같이 셋팅한다.

-   Service: Facebook Live
-   Stream Key: 앞절에서 복사해 둔 `스트림 키` 붙여넣기

[![OBS 설정](/images/2016-07-21-img-05.png)](/images/2016-07-21-img-05.png)

`Video` 메뉴를 선택하고, Output (Scaled) Resolution을 1280x720 이하로 맞춘다(1280x720을 넘는 영상은 잘린다). 설정을 저장한다.

#### 3단계

OBS UI에서 <kbd>Start Streaming</kbd> 버튼을 누르면, 앞 절의 두번째 페이스북 팝업에 화면이 표시되기 시작한다.

[![방송하기](/images/2016-07-21-img-06.png)](/images/2016-07-21-img-06.png)

팝업 창에서 <kbd>방송하기</kbd> 버튼을 누르고 라이브 스트리밍을 시작한다.

### 보너스. 하드웨어 인코더 사용하기

고화질 영상을 x264 소프트웨어 인코더로 인코딩하다보면 CPU가 100%를 치면서 컴퓨터가 터지려할 것이다. 머신에 비디오 인코딩 전용 하드웨어가 장착되어 있다면 CPU의 부하를 덜 수 있다.

OBS 설정에서 `Output` 메뉴를 선택하고, `Output Mode`를 `Advanced`로 바꾸면 인코더를 선택할 수 있는 UI가 활성화된다.

[![하드웨어 인코더 활성화](/images/2016-07-21-img-07.png)](/images/2016-07-21-img-07.png)

## 3. 결론

방송을 끝내고 싶을 때는 OBS UI에서 <kbd>Stop Streaming</kbd>버튼을 누른다. 아직 정확히 확인하지 못했지만, 방송 중에는 사용자의 영상을 받아 on-the-fly로 HLS(HTTP Live Streaming)으로 바꾸어 네트워크 상태에 따라 Bitrate를 조정하는 것으로 보인다. 방송이 끝나고 나면 고화질 영상으로 인코딩해서 다시 볼 수 있도록 남겨 준다.   

어제, 그제 생활코딩 춘천편에 자원봉사를 다녀왔는데, egoing님이 기존 수업과 달리 보너스로 [Disqus 댓글](https://disqus.com/), [Google Analytics](https://analytics.google.com),  [Uploadcare 파일 업로드](https://uploadcare.com/) 기능을 정적 페이지에 추가하는 데모를 학생들에게 보여 주며, "이게 얼마나 편한건지, 이 기능을 구현하려고 고민/고생해 보지 않은 분은 잘 모를겁니다"라고 말했다. 

마찬가지다. 라이브 스트리밍을 한다는 것이 얼마나 어려운 일인지 모른다. 설령 직접 구현했다 치더라도, 서버의 트래픽 비용을 감당하기가 만만치 않다. 이걸 페이스북이 전부 그냥 해 주는 거다. 

보통 업계 1위를 하면 관료주의와 매너리즘에 빠지기 일쑤다. 현재에 안주하지 않고 계속 기능을 추가해 나가는 페이스북에 박수를 보낸다.  
