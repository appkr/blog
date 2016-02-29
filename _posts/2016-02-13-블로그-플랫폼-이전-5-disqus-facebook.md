---
layout: post
title:  블로그 플랫폼 이전 5 - Disqus & Facebook
date: 2016-02-13 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- jekyll
---
Wordpress 에서 Jekyll 로 마이그레이션 과정에서 배운 내용을 총 5 편의 포스트로 정리해 본다.

1. [개발자로서의 새로운 삶](/work-n-play/블로그-플랫폼-이전-1-개발자로서의-새로운-삶)
2. [Goodbye Wordpress, Hello Jekyll](/work-n-play/블로그-플랫폼-이전-2-goodbye-wordpress-hello-jekyll)
3. [Publishing](/work-n-play/블로그-플랫폼-이전-3-publishing)
4. [Build Automation with Gulp](/work-n-play/블로그-플랫폼-이전-4-build-automation-with-gulp)
5. _Disqus & Facebook_

지난 2 주일 동안 일어난 우여곡절들을 기억을 되살려 최대한 복기해 두었다.

<div class="spacer">• • •</div>

기존 Wordpress to Jekyll 마이그레이션 시리즈에 하나의 포스트를 더 추가한다. 오늘 구현한 따끈한 기능 2가지 이다.

- Disqus[^1] 최신 댓글 뽑아 오기
- Facebook 최신 포스트 뽑아 오기

## Disqus 최근 댓글 뽑아 오기

Disqus 에서 이미 위젯을 제공하고 있어서 구현은 아주 간단한다.

```html
<!-- https://github.com/appkr/blog/blob/master/_includes/site-sidebar.html#L64 -->

<!-- ... -->
<section class="box" id="recent-comments">
  <div class="box-header">
    <h3>Recent Comments</h3>
  </div>

  <div class="box-body dsq-widget">
    <script src="http://appkr.disqus.com/recent_comments_widget.js?num_items=5&hide_mods=0&hide_avatars=0&avatar_size=32&excerpt_length=100"></script>
  </div>
</section>
<!-- ... -->
```

<!--more-->

핵심은 `<script src="..."></script>` 한 줄이다. 각 쿼리 스트링 파라미터의 의미는 아래와 같다.

Name|Default|Description
---|--:|---
`num_items`|5|가져올 댓글 갯수 (최신순)
`hide_mods`|0|관리자 댓글 숨김 여부 (`1` 로 설정하면 관리자 댓글은 빠짐)
`excerpt_length`|100|잘라낼 댓글 본문 길이 (Double Byte Safe)
`hide_avatars`|0|Avatar 이미지 숨김 여부 (`1` 로 설정하면 Avatar 빠짐)
`avatar_size`|32|Avatar 이미지 크기

렌더링 된 Markup 은 아래와 같다. 태그와 클래스를 이용하여 적절히 스타일링 하였다.

```html
<ul class="dsq-widget-list">
  <li class="dsq-widget-item">
    <a href="https://disqus.com/by/{user_id}/">
      <img class="dsq-widget-avatar" src="{avatar_url}">
    </a>
    <a class="dsq-widget-user" href="https://disqus.com/by/{user_id}/">{user_name}</a> 
    <span class="dsq-widget-comment">
      <p>{message}</p>
    </span>
    <p class="dsq-widget-meta">
      <a href="{post_url}">{post_title}</a>
      <a href="{post_url}/#comment-{comment_id}">{n} {minutes/hours/days/...} ago</a>
    </p>
  </li>
</ul>
```

## Facebook 최신 포스트 뽑아 오기

몇 년 전에 Facebook 개발자 문서 보면서 한숨~ 쉬었던 기억이 있다. 오늘도 삽질 꽤나 했다. 가장 큰 문제점은 찾기가 너무 힘들다는 것. 

### App Registration

먼저 [Facebook Developer Console](https://developers.facebook.com/quickstarts/?platform=web) 에서 App 을 등록해야 한다. 등록하고 받은 `app_id`, `app_secret` 는 잘 보관해 두어야 한다.

### Javascript SDK 설치

SDK 를 설치하고 초기화 해야 한다. App 등록에서 받은 `app_id` 를 `facebookAppId` 변수에 할당하였다.

```javascript
// https://github.com/appkr/blog/blob/master/_assets/scripts/main.js#L271

/* Facebook Recent UserFeeds */
window.fbAsyncInit = function() {
  var facebookAppId = '{app_id}';
  FB.init({appId: facebookAppId, status: true, xfbml: false, cookie: true, version: 'v2.5'});
};

(function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) {return;}
  js = d.createElement(s); js.id = id;
  js.src = "//connect.facebook.net/en_US/sdk.js";
  fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));
```

페이지 로드해서 에러가 안났다. SDK 가 잘 로드되었다는 의미다~

### Markup

표시할 뷰의 내용이 복잡하지도 않을 뿐더러, 3rd Party Template Engine[^2] 의존성을 제거하기 위해 Template 컴파일을 직접 구현하기로 했다. 

`ul.facebook-feed` 엘리먼트 안쪽에, Template 으로 쓰일 `script#facebook-feed-template` 엘리먼트를 위치시켰다. 그리고, Jekyll Liquid 와 충돌을 피하기 위해서 Single Curly Brace (`{}`) 를 String Interpolation 기호로 사용하였다. 바인딩할 대상은 `{ message }`, `{ id }`, `{ created_time }` 딱 3 개 뿐이다.

```html
<!-- https://github.com/appkr/blog/blob/master/_includes/site-sidebar.html#L74 -->

<section class="box" id="recent-feeds">
  <div class="box-header">
    <h3>Facebook Posts</h3>
  </div>

  <div class="box-body">
    <ul id="facebook-feed">
      <script id="facebook-feed-template" type="text/x-template">
        <li>
          <span class="facebook-message">
            { message }
          </span>
          ·
          <span class="facebook-meta">
            <a href="https://www.facebook.com/juwonkimatmedotcom/posts/{ id }">
              { created_time }
            </a>
          </span>
        </li>
      </script>
    </ul>
  </div>
</section>
```

### Template Compile & Rendering

[Facebook Graph API](https://developers.facebook.com/docs/graph-api) 를 이용하면 내 Facebook 계정의 포스트를 가져올 수 있다. 다만, 최근 API 에서는 `GET` 요청에도 인증이 필요한 것 같다. 여기서 꽤 오랜 삽질을 했다.

Oauth 인증 UI 및 프로세스를 직접 구현하는 것을 피하기 위해, CURL 을 이용하였다. 

```bash
$ curl "https://graph.facebook.com/oauth/access_token?client_id={app_id}&client_secret={app_secret}&grant_type=client_credentials&scope=user_posts"
# access_token=xxxxxxxxxxxxxxxxxxxxxxxxx...
```

여기서 받은 `access_token` 은 1 시간 짜리이다. Facebook 공식 용어로는 Long Lived Token 이라 하는데, 60 일 짜리 토큰으로 교환해야 한다.  

```bash
curl "https://graph.facebook.com/oauth/access_token?grant_type=fb_exchange_token&client_id={app_id}&client_secret={app_secret}&fb_exchange_token={access_token}"
# access_token=yyyyyyyyyyyyyyyyyyyyyyyyy...
```

60 일 짜리 `access_token` 이 확보되었다. API 를 호출하면 되는데... 

Javascript 에서는 코드 내에 포함된 `access_token` 이 공개되므로 보안상 아주 위험하다. Javascript 를 벗어 나지 않고 이를 감출 수 있는 방법을 찾아 헤멨지만, 결론은 "그런 방법은 없다" 였다. 현재까지 조사한 바로는 자체 백엔드 서버 없이는 불가하다고 알려져 있는데... 일단 보안을 좀 희생하면서, 구현에 집중하기로 한다. 

문서를 보고 `me/posts` 엔드포인트를 이용하면 된다는 것을 알았다. `me/posts` API 호출 결과에서 `response.data` 속성이 포스트들을 담고 있는 Collection 이다. `markup` 변수는 `compile()` Helper 에 의해 컴파일된 `li` 엘리먼트가 포함된 HTML 이며, 이 HTML 을 `ul#facebook-feed` 에 붙여 DOM 을 업데이트하였다. (화면이 로드되고 한참 있다 뜬다~ jQuery 를 쓰면 안되는 이유;;)

```javascript
// https://github.com/appkr/blog/blob/master/_assets/scripts/main.js#L291

window.fbAsyncInit = function() {
  var facebookAccessToken =  '{access_token}';
  var facebookAppId = '{app_id}';
  var facebookFeedContainer = $('ul#facebook-feed');
  var facebookFeedTemplate = $.trim($('#facebook-feed-template').html());

  FB.init({appId: facebookAppId, status: true, xfbml: false, cookie: true, version: 'v2.5'});

  FB.api('me/posts', 'GET', {limit: 3, access_token: facebookAccessToken}, function(response) {
    if (! response || response.error) {
      facebookFeedContainer.html('<li>Some error :(</li>');
    }

    var markup = compile(facebookFeedTemplate, response.data);
    facebookFeedContainer.append(markup);
  });
};
```

아래는 `compile()`, `truncate()` Helper 이다. 넘겨 받은 `facebookUserFeedCollection` 배열을 순회하면서 Regex 로 `{}` 를 찾은 후, 배열 아이템의 값을 바인딩시키는 식으로 Template 을 HTML 로 컴파일하였다. 

```javascript
// https://github.com/appkr/blog/blob/master/_assets/scripts/main.js#L263

var compile = function(layoutTemplate, facebookUserFeedCollection) {
  var markup = '';

  $.each(facebookUserFeedCollection, function(index, item) {
    markup += layoutTemplate
      .replace(/{\s?id\s?}/ig, item.id.split('_')[1])
      .replace(/{\s?message\s?}/ig, truncate(item.message || item.story))
      .replace(/{\s?created_time\s?}/ig, moment(item.created_time, moment.ISO_8601).fromNow());
  });

  return markup;
};

var truncate = function(str, len) {
  var len = len || 100;

  if (str.length > len) {
    return str.substring(0, len - 1) + '...';
  }

  return str;
};
```

휴~ 

Disqus 와 동일한 *`{n} {minutes/hours/days/...} ago`* 형식의 날짜로 포맷팅하기 위해 `moment` 패키지를 가져왔고, `moment('2016-02-12T09:00:00+0000', moment.ISO_8601).fromNow())` 처럼 사용하였다.

```bash
$ bower install moment --save-dev
```

<div class="spacer">• • •</div>

[^1]: [Disqus](https://disqus.com/) 는 댓글 서비스 이다. Jekyll 은 모든 면에서 내가 원하는 것들을 충족해 주었지만, 가장 아쉬운 점 중에 하나가 블로그 포스트에 대한 댓글이었다. 댓글의 특성상 블로그 방문자와 계속 인터랙션해야 하기 때문에 댓글을 저장할 백엔드가 반드시 필요한데... 이 때 선택할 수 있는 옵션이 Disqus 와 같은 외부 댓글 서비스이다. 유사 서비스로는 [Livere-국산](https://www.livere.com/), [Chak-국산](http://chak.it/) 등이 있다.

[^2]: Javascript Template Engine 으로는 [Handlebars](http://handlebarsjs.com/)가 전통적 강자이다. [EJS](http://ejs.co/) 도 꽤 쓰이는 것 같다. 관련해서 [SitePoint 에서 훌륭한 아티클](http://www.sitepoint.com/overview-javascript-templating-engines/)을 썼다. 

