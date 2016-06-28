---
layout: post
title: '서비스 URL의 중요성 및 변경의 비용' 
date: 2016-05-18 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- 'URL Rewriting'
---

웹 서비스를 하다 보면 마이그레이션을 해야 할 때가 반드시 찾아 온다. 트래픽 양이 변해서 더 큰 또는 작은 서버로 이전한다거나, 다른 프로그래밍 언어 또는 다른 프레임워크로 갈아타야 한다거나..

나에게도 찾아 왔다. 라라벨 온라인 강좌의 라이브 데모 사이트를 AWS(Amazon Web Service)에서 서비스하고 있었는데, 요금이 꽤 나와서 Github Page로 옮겼다. 회원 가입등 서버가 필요한 동적 기능은 버리고, HTML로 강좌만 서비스하는 정적 웹 페이지로 바꾸었다. 이 과정에서 어쩔 수 없이 URL을 변경했다.

변경 전|변경 후
---|---
`/lessons/01-welcome.md`|`/lessons/01-welcome.html`

[Jigsaw](http://jigsaw.tighten.co/)라고 하는 정적 사이트 빌더를 이용했는데, 로컬 컴퓨터에서 마크다운으로 작성한 강좌를 정적 HTML 파일로 전부 트랜스파일한 다음, Github Page에 올리는 방식이다. [Jekyll](http://jekyllrb.com/)을 이용한 이 블로그와 빌드 도구만 다를 뿐 똑같은 방식이다.

AWS 라이브 데모를 닫은 지 2주일 정도됐다. 사용자가 구글 검색 엔진을 통해 들어온다면, 기존의 URL은 당연히 열리지 않는 황당한 경험을 하게 된다. 구글로부터 최근에 404 응답이 많아졌다는 메일을 받았지만, 아무 생각없이 그냥 무시했었다. 커뮤니티에서 같이 활동을 하는 [김종운](https://www.facebook.com/profile.php?id=100001411952158)님과 어제 대화를 나누기 전까지는 말이다. 

> URL이 바꼈던데, 그간에 쌓아 놓은 구글 검색 순위가 아깝지 않으세요?
>
> <footer>김종운님</footer>

[Google Search Console](https://www.google.com/webmasters/tools)로 확인해 보니 다행히 그간에 검색 엔진을 통해 들어온 사용자는 그리 많지 않았고, 순위도 그리 높지 않았을 것이라 생각한다. 그러나, 2 주간 불편을 겪었을, 또 앞으로 불편을 겪을 수도 있는 사용자를 생각하면 고치지 않을 수 없었다.

이 포스트는 다음 내용을 다룬다. SEO(Search Engine Optimization, 검색 엔진 최적화)라는 관점에서 공통점이 있다.

1.  Github Page에서 URL Redirect를 구현한 로그
2.  SEO 관점에서 URL의 중요성 및 일반적인 URL Rewrite 방법

<!--more-->
<div class="spacer">• • •</div>
 
## 1. Github Page에서 URL Redirect

Github Page는 정적 페이지만 서비스할 수 있으며, `.htaccess` 리디렉션 기능을 이용할 수 없다([https://help.github.com/articles/redirects-on-github-pages/](https://help.github.com/articles/redirects-on-github-pages/)). 

그렇다면 웹 페이지에서 다른 페이지로 리디렉션해야한다. 자바스크립트는 클라이언트측에서 동작하는 언어이므로 당연히 사용 가능하다. Github Page의 커스텀 404 페이지와 다음 기술을 적용하기로 했다.

-   HTML 헤더의 `<meta http-equiv="refrech" content="0; http://new/url">` 태그를 이용하는 방법
-   자바스크립트의 `window.location.href` 속성을 이용하는 방법

### 1.1. 커스텀 404 페이지 추가

Github Page(`gh-pages` 브랜치)에 등록되지 않은 파일 요청이 들어오면 404 페이지를 출력하는데, 이 404 페이지를 별도로 추가할 수 있다.

[![Github 404 Page](/images/2016-05-18-img-01.png)](/images/2016-05-18-img-01.png)

### 1.2. 리디렉션 로직 작성

작동 방법에 대한 복안이 서고 나면 구현은 의외로 간단하다.

```html
<!-- // https://github.com/appkr/l5essential-notice/blob/master/404.html -->

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Not Found</title>
  <meta http-equiv="refresh" content="">
  <link rel="canonical" href="http://l5.appkr.kr">
  <style>...</style>
</head>
<body>
  <h1>Not Found</h1>
  <p>The page or resource you request does not exist.</p>

  <script>
    var url = window.location.href;

    if (/([0-9]{2,5}-[\pL-\pN\._-]+)\.md/gi.test(url)) {
      url = url.replace('.md', '.html');
      document.querySelector('link[rel="canonical"]').setAttribute('href', url);
      document.querySelector('meta[http-equiv="refresh"]').setAttribute('content', '0; '+url);
    }
  </script>
</body>
</html>
```

-   `<link rel="canonical" href="...">`

    상당히 중요하다. 구글 검색엔진은 같은 HTML 문서에 대해 중복된 주소가 있으면 검색 순위에 페널티를 준다. 이 태그는 페널티를 피할 뿐만 아니라, 검색 엔진에 인덱싱된 기존 URL을 새 URL로 바꾸도록 한다.

-   `if (/([0-9]{2,5}-[\pL-\pN\._-]+)\.md/gi.test(url)) { ... }`

    `var url = window.location.href;` 변수에는 `http://l5.appkr.kr/lessons/01-welcome.md`와 같은 문자열이 담긴다. 이 변수의 값에 2~5 길이의 숫자로 시작하고, 대시(`-`) 다음에 문자 또는 숫자 등이 연결되어 있으며, `.md`로 끝나는 문자열이 있으면, 이 조건문을 탄다.
    
    이 조건문을 타지 않으면 Not Found 페이지가 그대로 출력된다.

-   `url = url.replace('.md', '.html');`, `document.querySelector(...).setAttribute(...);`

    확장자를 `.html`로 바꾸고 HTML 헤더의 Meta 및 Link 태그의 속성 값을 바꾼다.

검색을 통해 기존 URL로 유입하는 사용자에 대한 처리가 완료되었다.

## 2. SEO 관점에서 URL의 중요성 및 일반적인 URL Rewrite 방법

### 2.1. URL은 최고의 SEO 도구다.

검색 크롤러가 HTML 페이지를 파싱하기도 전에 가장 먼저 맞닥드리는 것이 URL이다. 구글에서 'screen resolution'으로 검색해 보면, 다음 그림과 같은 결과를 얻는다. 검색 결과에서 URL에 볼드 처리된 것을 확인할 수 있다. 

[![Search Engine Friendly URL](/images/2016-05-18-img-02.png)](/images/2016-05-18-img-02.png)

SEO 특강이라고 이것 저것 가르치는 유료 강의들이 있던데, URL이 SEO에 얼마나 중요한지 가르쳐 주는지 모르겠다. 많은 마케터와 개발자가 이 사실을 모르고 있거나, 알고 있더라도 간과한다.

가장 먼저 나온 위키피디아의 원래 주소는 `https://en.wikipedia.org/w/index.php?title=Display_resolution`이다. 어떻게 된거지?

### 2.2. Pretty Url

위키피디아와 같은 SEO-friendly URL은 URL Rewrite를 했기 때문이다. 흔히 Pretty Url이라고 부른다.

-   SEO에 유리하다.
-   인지적으로 훨씬 더 유리하다(`wiki` 카테고리 아래에 `Display_resolution`이란 리소스가 있는 것처럼 보인다).
-   URL과 백엔드(프로그래밍 언어/프레임워크, 또는 이들에 의해 서비스되는 리소스)를 디커플링할 수 있다.

클리앙의 URL 하나를 긁어 왔다. 이 URL을 보고 무엇을 담고 있는 지 알 수 있는가? 절대 알 수 없다. 게다가 서비스 프레임워크로 PHP를 쓰고, `cm_mac`이란 데이터베이스 테이블이 있고, 현재 ID는 `791884`라고 해커한테 광고하고 있다. 
 
```
http://clien.net/cs2/bbs/board.php?bo_table=cm_mac&wr_id=791884
```

백엔드 구현은 위키피디아와 크게 다를 바 없을 것이다. 모르긴 해도 `board.php` 또는 이 파일이 의존하는 다른 파일에서 `SELECT * FROM cm_mac WHERE wr_id=791884;`와 같은 데이터베이스 쿼리를 하고, 쿼리 결과를 HTML에 끼워 넣어서 사용자에게 응답할 것이다.

반면, 위키피디아는 `wiki` 카테고리(또는 디렉터리) 아래에 `Display_resolution`이란 리소스가 있는 것처럼 보인다. 물론 위키피디아도 `SELECT * FROM wiki WHERE title='Display_resolution'` 쿼리를 할 것이다.

### 2.3. URL Rewrite

라라벨 프레임워크에서 프런트 컨트롤러[^1] 구현을 위해 사용한 아파치 웹 서버 설정 파일을 통해 URL Rewrite의 문법과 유용성을 살짝 엿보자.

```apache
# https://github.com/laravel/laravel/blob/master/public/.htaccess

RewriteEngine On

RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)/$ /$1 [L,R=301]

RewriteCond %{REQUEST_FILENAME} !-d
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^ index.php [L]
```

-   `RewriteCond %{REQUEST_FILENAME} !-d`

    다음에 이어질 `RewriteRule`이 동작할 조건이다. 이 조건에 해당할 때만 다음 줄이 실행된다.
    
    `%{REQUEST_FILENAME}`는 아파치 웹 서버의 환경 변수 중 URL에 포함된 경로(Path)를 뜻한다. 위키피디아의 예에서는 `wiki/Screen_resolution`이 된다.
    
    `!`은 Not(Negation, 부정 연산자)이다. `-d`는 디렉터리다. `-f`를 쓰면 파일을 뜻한다. 쉘 스크립트에서 사용하던 `[ !-d "wiki/Screen_resolution"]`과 같다고 보면 된다. 이 문장의 의미는 '서버에 `wiki/Screen_resolution`이라는 디렉터리가 없으면'으로 해석할 수 있다.
    
-   `RewriteRule ^(.*)/$ /$1 [L,R=301]`

    첫 번째 Rewrite 규칙이다. 인자 사이는 공백으로 구분한다. 첫 번째 인자는 찾을 문자열, 두 번째는 바꿀 URL의 모양, 대괄호 안에는 액션을 쓴다.
    
    `^(.*)/$`는 정규 표현식이다. `^`는 시작을 `$`는 끝을 의미한다. `()`는 캡처링 그룹, `.`는 개행을 제외한 모든 문자, `*`는 0개부터 무한대까지의 개수를 한정한다. 해석하자면 `/`로 끝나는 URL 경로다.
    
    `$1`은 캡처링 그룹으로 잡은 문자열이다. 가령, `wiki/Screen_resolution/`처럼 마지막에 `/`가 있었다면, `/wiki/Screen_resolution`로 바꿀 것이다.
    
    `L`을 주면 이 문장 다음에 RewriteRule이 더 있어도 실행하지 않는다. `R=301`은 301 응답 코드와 함께 새로운 URL로 리디렉션한다는 뜻이다. 그냥 `R`만 주면 302 응답 코드로 리디렉션한다. 차이는 301은 영구적 URL 변경, 302는 임시적 URL 변경이다. 웹 브라우저가 아니라 웹 크롤러가 이 URL을 방문했다면 301 응답을 받아 자신의 데이터베이스에서 색인을 업데이트할 것이다.

-   `RewriteCond %{REQUEST_FILENAME} !-d`, `RewriteCond %{REQUEST_FILENAME} !-f`

    다시 한번 더 조건을 타는데, 요청한 URL 경로에 해당하는 파일이나 디렉터리의 존재를 확인한다. 예를 들어, `wiki/foo.png` 등 웹 서버에 이미지, CSS, 자바스크립트 등 정적 파일이 실제로 존재한다면 이 조건은 통과하고, 웹 서버가 처리한다.

-   `RewriteRule ^ index.php [L]`

    이 Rewrite 규칙에 도달하면 무조건 `index.php`로 HTTP 요청을 넘긴다. Rewrite 규칙에는 URL 경로나 쿼리스트링등이 없는데, PHP/라라벨이 `$_SERVER` 수퍼 글로벌 변수를 이용해서 값을 읽을 수 있기 때문에 굳이 넘겨줄 필요가 없기 때문이다.
    
    HTTP 요청을 넘겨 받은 `index.php`는 `$_SERVER['PATH_INFO']`, `$_SERVER['QUERY_STRING']`으로 `wiki/Screen_resolution/`등의 정보를 추출할 수 있으며, 다시 애플리케이션 라우팅을 이용해서 적합한 컨트롤러 로직으로 요청의 처리를 위임한다.

종합하면, 서버에 없는 디렉터리면 요청 URL 끝에 달린 `/`를 떼고 301 응답을 반환하면, 클라이언트는 `/`를 뗀 상태로 다시 요청한다. 이번에는 `/`가 없기 때문에 첫번째 조건은 그냥 통과하고, 두번째 조건에서 서버에 실제로 존재하는 디렉터리 또는 파일이 아니라면, 전부 `index.php`에게 클라이언트의 요청을 처리할 것을 위임한다. 

## 3. 결론

최고의 SEO는 URL이다. 처음부터 URL을 잘 설계해야 하고, URL Rewrite를 도입하라. 그리고, URL 변경의 비용을 절대 무시하지 말라. 

---

[^1]: Front Controller_ 웹 애플리케이션의 단일 진입점이다. 가령 클리앙의 예처럼 `foo.php`, `bar.php`, `...`이 아니라, `index.php` 단 하나의 진입점을 말한다. HTTP 요청이 이 진입점에 들어 오면, 애플리케이션을 부팅하고 라우팅 테이블에 의해 적절한 처리 로직을 가동하고 응답을 반환한다.
