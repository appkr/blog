---
layout: post
title:  블로그 플랫폼 이전 3 - Publishing
date: 2016-02-11 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- jekyll
---
Wordpress 에서 Jekyll 로 마이그레이션 과정에서 배운 내용을 총 4 편의 포스트로 정리해 본다.

1. [개발자로서의 새로운 삶](/work-n-play/블로그-플랫폼-이전-1-개발자로서의-새로운-삶)
2. [Goodbye Wordpress, Hello Jekyll](/work-n-play/블로그-플랫폼-이전-2-goodbye-wordpress-hello-jekyll)
3. _Publishing_
4. [Build Automation with Gulp](/work-n-play/블로그-플랫폼-이전-4-build-automation-with-gulp)

<div class="spacer">• • •</div>

연초에 블로그 이전을 생각하며 여기 저기 눈팅하던 중 디자인 ([themeforest-Globals](http://themeforest.net/item/globals-material-universal-psd-template/11932290)) 하나가 눈에 들어왔다. 내용과 품질에 비해서 너무 저렴한 가격 $12. 지르지 않을 이유가 없었다.

[![themeforest-Globals](http://s6.postimg.org/ejkibz8o1/01_header.png)](http://s6.postimg.org/ejkibz8o1/01_header.png)

<div class="spacer"></div>

그런데, 구매한 후 다운로드 받은 파일을 압축을 풀고서야 알았다, "PSD 파일 밖에 없다는 것을". 기존에 구매했던 관리자용 템플릿인 [Inspina](https://wrapbootstrap.com/theme/inspinia-responsive-admin-theme-WB0R5L90S) 처럼, AngularJS, MEAN, RoR, .. 등 대부분의 플랫폼에 미리 포팅되어 동작하는 템플릿을 기대하고 있었던 것이다.

<!--more-->

### 퍼블리싱

이번에 디자이너와 코더라는 직종이 별도로 있는 지 처음 알았다. 요즘은 이 둘을 합쳐서 퍼블리셔라 한다고 들었다.

기존에 HTML, CSS Markup 은 많이 해 보았지만, 디자인을 그대로 옮긴 경험은 없었다. 이 바닥에서 먹고 살려면 어차피 익숙해져야 하는 일이니 이번에 해 보자며 작업을 시작한 결과물이 이 블로그이다.

Bower 가 끌고오는 Assets 들의 설치 디렉토리 변경해 주었다. 프로젝트 루트에 설치되는 `bower_components` 는 Gulp Build 자동화할 때 불편하기 때문에.. 

```javascript
// https://github.com/appkr/blog/blob/master/.bowerrc

{
  "directory": "_assets/vendor"
}
```

FezVrasta 의 [Bootstrap Material Design](https://github.com/FezVrasta/bootstrap-material-design) 을 적용하였다. 

```bash
$ bower install bootstrap-material-design
```

Sass 보다는 중괄호(`{}`)를 사용하는 SCSS 문법을 선호한다.

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

<div class="spacer">• • •</div>

**`삽질`** 삽질이 없으면 개발자가 아니다. 왜냐하면 개발자가 아니라면, 안되면 그냥 '안되는구나~' 라고 불평하며 더 이상 안 쓰기 때문이다. twbs 클래스들이 오버라이드될 줄 알았는데, 잘못된 가정이었다. 이번에 알게된 사실은 CSS 스타일 정의에서 가중치 또는 우선순위이다. HTML Element 에 부여된 id 는 100 점, class 는 10 점, tag 는 1 점 이라는 것이다. 가령 `blockquote  {...}` 는 1점인 반면, `#app blockquote {...}` 는 101 점. `blockquote {... !important}` 를 쓰는 것은 안티패턴이다. 해서 twbs 클래스를 오버라이드하는 가장 좋은 방법은 아래 처럼 id 를 이용하는 방법..

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
