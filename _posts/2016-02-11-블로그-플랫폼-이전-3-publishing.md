---
layout: post
title:  블로그 플랫폼 이전 3 - Publishing
slug: jekyll-blogging-part3
date: 2016-02-11 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- Jekyll
image: http://s6.postimg.org/ejkibz8o1/01_header.png
---
Wordpress 에서 Jekyll 로 마이그레이션 과정에서 배운 내용을 총 5 편의 포스트로 정리해 본다.

1. [개발자로서의 새로운 삶](/work-n-play/블로그-플랫폼-이전-1-개발자로서의-새로운-삶)
2. [Goodbye Wordpress, Hello Jekyll](/work-n-play/블로그-플랫폼-이전-2-goodbye-wordpress-hello-jekyll)
3. _Publishing_
4. [Build Automation with Gulp](/work-n-play/블로그-플랫폼-이전-4-build-automation-with-gulp)
5. [Disqus & Facebook](/work-n-play/블로그-플랫폼-이전-5-disqus-facebook)

지난 2 주일 동안 일어난 우여곡절들을 기억을 되살려 최대한 복기해 두었다.

<div class="spacer">• • •</div>

연초에 블로그 이전을 생각하며 여기 저기 눈팅하던 중 디자인 ([themeforest-Globals](http://themeforest.net/item/globals-material-universal-psd-template/11932290)) 하나가 눈에 들어왔다. 내용과 품질에 비해서 너무 저렴한 가격 $12. 지르지 않을 이유가 없었다.

[![themeforest-Globals](http://s6.postimg.org/ejkibz8o1/01_header.png)](http://s6.postimg.org/ejkibz8o1/01_header.png)

<div class="spacer"></div>

그런데, 구매한 후 다운로드하고 파일 압축을 풀고서야 알았다, "PSD 파일 밖에 없다는 것을". 기존에 구매했던 관리자용 템플릿인 [Inspina](https://wrapbootstrap.com/theme/inspinia-responsive-admin-theme-WB0R5L90S) 처럼, AngularJS, MEAN, RoR, .. 등 대부분의 플랫폼에 미리 포팅되어 동작하는 템플릿을 기대하고 있었던 것이다.

<!--more-->

## 퍼블리싱

이번에 디자이너와 코더라는 직종이 별도로 있는 지 처음 알았다. 요즘은 이 둘을 합쳐서 퍼블리셔라 한다고 들었다.

기존에 HTML, CSS Markup 은 많이 해 보았지만, 디자인을 그대로 옮긴 경험은 없었다. 이 바닥에서 먹고 살려면 어차피 익숙해져야 하는 일이니 이번에 퍼블리싱을 경험해 보자며 뛰어든 작업의 결과물이 이 블로그이다.

## Layout & HTML Markup

마스터 레이아웃이다. 앞서 SEO (==검색 엔진 최적화) 를 언급했는데, 그 중 일부가 여기에 포함되어 있다.

{% raw %}
```html
<!-- https://github.com/appkr/blog/blob/master/_layouts/default.html -->

<!DOCTYPE html>
<html>
<head>
  <meta name="description" content="{% if page.excerpt %}{{ page.excerpt | strip_html | strip_newlines | strip | truncate: 160 }}{% else %}{{ site.description }}{% endif %}"/>
  <!-- Facebook Meta -->
  <meta property="og:title" content="{% if page.title %}{{ page.title }}{% else %}{{ site.title }}{% endif %}"/>
  <!-- ... -->
  <link rel="stylesheet" href="/styles/main.min.css"/>
</head>

<body id="app">
  {% include site-header.html %}
  {{ content }}
  {% include site-footer.html %}

  <script src="/scripts/main.min.js"></script>
</body>
</html>
```
{% endraw %}

위 마스터 레이아웃을 이용(상속)하는 뷰들은 아래 처럼 작성하였다. 아래는 대문 페이지의 일부~

{% raw %}
```html
<!-- https://github.com/appkr/blog/blob/master/index.html -->
---
layout: default # /_layouts/default.html 레이아웃을 상속한다는 의미임.
# 이하 HTML Markup 들은 모두 /_layouts/default.html 에 쓴 {{ content }} 영역에 렌더링 됨.
---
<div class="container">
  <div id="main" class="col-md-9">
    {% for post in paginator.posts %}
    <article class="box">
      <!-- ... -->
      <div class="box-body">
        {{ post.content | split:'<!--more-->' | first }}
      </div>
    </article>
    {% endfor %}

    <nav id="pagination"><!-- ... --></nav>
  </div>

  <aside id="sidebar" class="col-md-3">
    {% include site-sidebar.html %}
  </aside>
</div>
```
{% endraw %}

전체 레이아웃은 다음 그림과 같다. 레이아웃 맨 아래에 `_layouts/site-footer.html` 은 스크린샷에서 빠졌다.

[![](/images/2016-02-11-img-03.png)](/images/2016-02-11-img-03.png)

## Bower

3rd Party Front-end 패키지 관리를 위해 [Bower](http://bower.io/) 를 계속 이용해 왔다. 이 프로젝트에서 사용할 Assets 을 정의할 `bower.json` 과 Bower 설정을 저장할 `.bowerrc` 파일을 만들었다. 

```bash
$ bower init
$ touch .bowerrc
```

[이전 포스트의 프로젝트 구조](/work-n-play/블로그-플랫폼-이전-2-goodbye-wordpress-hello-jekyll/#structure-config) 에서 정한 대로 Bower 가 끌고오는 Assets 들의 설치 디렉토리를 `_assets/vendor` 로 변경해 주었다. 기본값으로 두었을 때 사용되는 `bower_components` 는 Gulp Build 자동화할 때 불편하기 때문에...

```javascript
// https://github.com/appkr/blog/blob/master/.bowerrc

{
  "directory": "_assets/vendor"
}
```

### 덧 

[Bower 를 쓰지 말고 Npm 을 쓰자](https://gofore.com/ohjelmistokehitys/stop-using-bower/)는 움직임이 있는데, 아직은 익숙한 툴이라 사용하고 있다. 주목하고 있어야 할 흐름 중 하나이다.

## Styles

UI 요소를 위해 FezVrasta 의 [Bootstrap Material Design](https://github.com/FezVrasta/bootstrap-material-design) 을 적용하였다. 개발을 모두 종료하고 보니, 상단 네비게이션 요소, 검색 박스, 아이콘을 제외하고는 사용한 것이 없었다. (걷어 내야할까 고민 중...)

```bash
$ bower install bootstrap-material-design --save-dev
```

Sass 보다는 Curly Brace(`{}`)를 사용하는 SCSS 문법을 선호한다.

```css
// https://github.com/appkr/blog/blob/master/_assets/styles/main.scss

@charset "utf-8";

@import "../vendor/bootstrap-sass/assets/stylesheets/bootstrap";
@import "../vendor/bootstrap-material-design/sass/bootstrap-material-design";
@import "../vendor/bootstrap-material-design/sass/ripples";

$text-color: #9699a6;
// ...

body {
  color: $text-color;
  // ...
}

// ...
```

### 덧 

Jekyll 은 Fenced Code Block 의 스타일링을 기본 지원한다. 이 프로젝트에서는 Jekyll 의 기본 값인 `Rouge` 를 이용하지 않고, 일부러 [`Pygments`](http://pygments.org/) 를 이용하였다. `Pygments` 는 Python 으로 작성된 Syntax Highlighter 로, `Rouge` 보다 [더 많은 언어의 문법](http://pygments.org/languages/)을 지원하기 때문이다.

```bash
$ pip install Pygments
$ gem install pygments.rb
```

여기까지 했다고 해서 Fenced Code Block 이 예쁘게 표시되는 것은 아니다. `Pygments` 의 역할은, 가령 `<span class="cp">&lt;!DOCTYPE html&gt;</span>` 처럼, 코드 영역에 class 를 덧 붙여주는 역할을 한다. 따라서, `Pygments` 에 호환되도록 스타일시트를 정의해 주어야 한다. 이 프로젝트에서는 [SETI Theme](https://github.com/appkr/blog/blob/master/_assets/styles/main.scss#L209) 을 적용하였다.

## Javascripts

검색 기능을 부여하기 위해 [Simple-Jekyll-Search](https://github.com/christian-fei/Simple-Jekyll-Search)를 이용하였다. 포스트에 포함된 이미지를 확대해서 Lightbox 로 보여 주기 위해 [Bootstrap 3 Lightbox](https://github.com/ashleydw/lightbox) 도 가져왔다.

```bash
$ bower install simple-jekyll-search ekko-lightbox --save-dev
```

### Search

"데이터베이스를 사용하지 않는 정적 페이지인데 검색이 가능해?" 라고 반문하는 방문자가 있다면 당연한 일이다. 나도 그랬으니까... Simple-Jekyll-Search 의 동작 원리는 `search.json` 이란 파일에 사이트 전체의 인덱스를 미리 만들 수 있도록 Liquid 문법으로 써 놓고, Jekyll Build 때 인덱싱된 파일이 떨구어지도록 하는 식이다. `search.json` 이 생성되면 프로젝트를 배포할 때 같이 배포되며, Javascript 가 Ajax 요청으로 로컬에 위치한 전체 사이트 인덱스를 검색하고 결과를 뷰로 보여줄 수 있다.

{% raw %}
```javascript
// https://github.com/appkr/blog/blob/master/search.json

---
---
[
  {% for post in site.posts %}
  {
    "title"    : "{{ post.title | escape }}",
    "category" : "{{ post.category }}",
    "tags"     : "{{ post.tags | join: ', ' }}",
    "url"      : "{{ site.baseurl }}{{ post.url }}",
    "date"     : "{{ post.date }}"
  }{% unless forloop.last %},{% endunless %}
  {% endfor %}
]
```
{% endraw %}

검색 폼과 검색 결과를 보여줄 HTML Markup 을 준비하고,

```html
<!-- https://github.com/appkr/blog/blob/master/_includes/site-sidebar.html#L3 -->

<form action="#">
  <div class="form-group">
    <input class="form-control input-lg" type="text" id="q" placeholder="Search...">
    <ul id="q-results"></ul>
  </div>
</form>
<!-- ... -->
```

Javascript 로 Symple-Jekyll-Search 를 구동하면 끝~

```javascript
// https://github.com/appkr/blog/blob/master/_assets/scripts/main.js#L141

SimpleJekyllSearch({
  searchInput: document.getElementById('q'),
  resultsContainer: document.getElementById('q-results'),
  json: '/search.json',
  searchResultTemplate: '<li><a href="{url}" title="{desc}">{title}</a></li>',
  noResultsText: '<li class="text-warning">No results found</li>',
  limit: 10,
  fuzzy: false,
  exclude: []
});
```

[![Search](/images/2016-02-11-img-01.png)](/images/2016-02-11-img-01.png)

### Lightbox

이미지를 클릭/터치했을 때 [Modal](http://getbootstrap.com/javascript/#modals) 로 보여 주는 기능이다. [스타일](https://github.com/appkr/blog/blob/master/_assets/styles/main.scss#L590)은 약간만 수정해 주면 나머지는 Bootstrap 제공 스타일이 거의 그대로 사용된다. 기능 활성화를 위해 아래 Javascript 를 작성하였다.

```javascript
// https://github.com/appkr/blog/blob/master/_assets/scripts/main.js#L67

var imgObjects = bodyContainer.find('img');

imgObjects.each(function() {
  var that = $(this);
  that.closest('a').attr('data-toggle', 'lightbox').attr('data-title', that.attr('alt'));
});

bodyContainer.delegate('*[data-toggle="lightbox"]', 'click', function(e) {
  e.preventDefault();
  $(this).ekkoLightbox();
});
```

[![Lightbox](/images/2016-02-11-img-02.png)](/images/2016-02-11-img-02.png)

<div class="spacer">• • •</div>

## 삽질

삽질은 개발자의 고유한 특징이다. 비 개발자는 그냥 '안되는구나~' 라고 불평하며 다른 대안을 찾아 나서기 때문이다. 

Twitter Boostrap (==twbs) 클래스들이 오버라이드될 줄 알았는데, 잘못된 가정이었다. 이번에 알게된 사실은 CSS 스타일 정의에서 가중치 또는 우선순위이다. HTML Element 에 부여된 id 는 100 점, class 는 10 점, tag 는 1 점 이라는 것이다. 가령 `blockquote  {...}` 는 1점인 반면, `#app blockquote {...}` 는 101 점. `blockquote {... !important}` 를 쓰는 것은 안티패턴이다. 해서 twbs 클래스를 오버라이드하는 가장 좋은 방법은 아래 처럼 id 를 이용하는 방법..

```html
<!-- https://github.com/appkr/blog/blob/master/_layouts/default.html -->

<!DOCTYPE html>
<html>
<head>
<!-- ... -->
</head>
<body id="app">
<!-- ... -->
```

```css
// https://github.com/appkr/blog/blob/master/_assets/styles/main.scss

#app {
  blockquote {
    border: none;
    // ...
  }
}
```
