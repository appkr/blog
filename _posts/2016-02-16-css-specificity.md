---
layout: post
title:  CSS Specificity
date: 2016-02-16 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- css
---
speci.., specifif..., speficyfyf..., specificificfy... what? 

## CSS Specificity

[*|spesɪ|fɪsəti*, 스페시피서티, CSS 적용 우선 순위]. [블로그 플랫폼 이전 3 - Publishing](http://blog.appkr.kr/work-n-play/블로그-플랫폼-이전-3-publishing/#삽질) 포스트에서 twbs 클래스들을 오버라이드하는 과정에서 잘못 이해한 것을, 실험을 통해 배우고 고쳐서 정리해 놓는다. 

## Test

이번 주는 [생활코딩 작심5일](http://onoffmix.com/event/61685) 수업에 자원봉사자로 참여하고 있다. 오늘 수업에서 CSS 얘기를 듣다가 문득 궁금증이 생겼다. 

내가 기존에 알고 있던 지식은 

- Tag Selector 1 점 (*e.g. `a {...}`*)
- Class Selector 10 점 (*e.g. `.darth {...}`*)
- Id Selector 100 점 (*e.g. `#sith {...}`*)

였다. 궁금증은 *'Tag 를 11 개 중첩해서 쓰면 Class 하나를 오버라이드할 수 있을까?'* 라는 것.

<!--more-->

```bash
$ mkdir css-test && cd css-test
$ touch index.html
```

오늘 전까지는, 아래 `<style>` 내부에 주석으로 표시된 계산법으로 알고 있었다. (삐이이~~ 잘못 알고 있던 것이다.)

```html
<!-- index.html -->

<!doctype html>
<html lang="en">
<head>
  <style>
    a { /* ... */ }
    .darth { /* .darth x 1 = 10 점 */
      background-color: blue;
    }
    div>div>div>div>div>div>div>div>div>div>div>a { /* div x 11 + a X 1 = 12 점 */
      background-color: green;
    }
  </style>
</head>
<body>
  <div>
    <div>
      <div>
        <div>
          <div>
            <div>
              <div>
                <div>
                  <div>
                    <div>
                      <div>
                        <a href="#" class="darth">Hello CSS !</a>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</body>
</html>
```

## Conclusion

녹색의 배경색을 기대하며 실험 코드 실행 ! 두둥~~

```bash
# 다른 로컬 서버도 많은데.. PHP 개발자니까 굳이 PHP 내장 서버~~~
# 주제에 살짝 비켜나지만, 나 말고 이 글을 보시는 독자분들에게도 혹시라도 도움이 될수도 있으니...
# 같은 subnet 에 있는 다른 디바이스에서, 이 PHP 내장 서버에 접속 가능하게 하려면
#    localhost:8000 대신 0.0.0.0:8000 으로 PHP 내장 서버를 구동해야 한다.
# PHP 내장 서버는 개발 서버이므로, 혹시라도 외부에 노출되는 것을 방지하기 위해 80 포트는 쓸 수 없다~~
$ php -S localhost:8000

# 'Cmd + d' for new vertical split OR 'Cmd + n' for new tab
$ open http://localhost:8000
```

[![CSS Specificity](/images/2016-02-16-img-01.png)](/images/2016-02-16-img-01.png)

헐~ㅋ 결과는 녹색 (`green`) 이 아니라 청색 (`blue`) 이다. 

실험의 결론을 정리하면, 'Tag selector 는 Class Selector 를 이길 수 없고, Class Selector 는 Id Selector 를 이길 수 없다' 는 것. 즉, 기존의 내 계산법은 잘못된 것이었다.

### What's wrong? What's correct?

CSS 적용 우선순위는 개발팀들이 거의 *de facto* 로 생각하고 프로젝트들에 적용하고 있는 [Semantic Versioning](http://semver.org/lang/ko/) 에 비유할 수 있다. `0.1.0` 과 `0.0.12` 의 차이 같은 것이다. `0.1.0` 이 더 최신 버전이라 채택되고, 특별한 이유가 없다면 `0.0.12` 는 무시되는 것 처럼..

오늘 작심5일 강의에서 알게된 아티클 --[CSS: Specificity Wars](https://stuffandnonsense.co.uk/archives/css_specificity_wars.html)-- 과 Sync 를 위해, CSS 에서는 Dot(`.`) 대신, Comma(`,`) 구분자를 이용해서 다시 계산해 본다.

```html
<!-- index.html -->

<!doctype html>
<html lang="en">
<head>
  <style>
    a { /* ... */ }
    .darth { /* 0, 10, 0 */
      background-color: blue;
    }
    div>div>div>div>div>div>div>div>div>div>div>a { /* 0, 0, 12 */
      background-color: green;
    }
  </style>
</head>

<!-- ... -->
```

[![CSS Specificity](https://stuffandnonsense.co.uk/archives/images/specificitywars-05v2.jpg)](https://stuffandnonsense.co.uk/archives/images/specificitywars-05v2.jpg)

어떤 CSS 룰이 적용될지를 비교할 대상 간에 1의 자리끼리, 10의 자리끼리, 100의 자리끼리 비교해야 한다는 것이 핵심 포인트 !!!

### Then?

그럼 `div .darth` 는 `.darth` 를 이길 수 있을까?

```css
.darth {
  background-color: blue;
}
div>div>div>div>div>div>div>div>div>div>div>a {
  background-color: green;
}
div .darth { /* 0, 10, 1 */
  background-color: black;
}
```
