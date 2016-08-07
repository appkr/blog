---
layout: post-minimal
title: '자바스크립트와 프로미스' 
date: 2016-08-07 00:00:00 +0900
categories:
- learn-n-think
tags:
- 개발자
- javascript
---

자바스크립트를 처음 만났을 때, 어려운 개념 중에 하나가 프로미스(Promise)다. 순서대로 실행되는 프로그램에서 시간이 오래 걸리는 작업을 수행하는 동안, 프로미스를 이용하면 해당 작업이 끝날 때까지 기다리지 않고 다음 작업을 바로 진행한다. 대신 작업이 끝나면 그 결과를 가지고 다음 작업(콜백)을 실행할 작업자(프로미스)를 심어 놓는다.

[![Promise](/images/2016-08-07-img-01.png)](/images/2016-08-07-img-01.png)

이하 코드들은 크롬 콘솔(<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>c</kbd>)에 붙여 넣으면 동작을 확인해 볼 수 있다.

<!--more-->
<div class="spacer">• • •</div>

## 1. Promise

```javascript
var promise = new Promise(function (성공콜백, 실패콜백) {
  console.log('프로미스 객체가 생성되지마자 바로 실행합니다. 작업자(프로미스)를 고용해놓고, 다음 작업으로 진행합니다.');
  
  setTimeout(function () {
    console.log('5초가 필요한 "Foo" 작업을 시뮬레이션했습니다. 그리고, 작업을 완료했습니다.');
    
    성공콜백('Foo');
  }, 5000);
});

promise.then(function (payload) {
  console.log('"' + payload + '" 작업이 성공하면 고용한 작업자가 대신 실행할 로직입니다.');
}, function (error) {
  console.log('작업이 실패하면 고용한 작업자가 대신 실행할 로직입니다.');
});
```

`Promise` 클래스는 `then()` API를 가지고 있고, 함수를 인자로 받는데, 다시 그 함수는 성공과 실패 콜백을 인자로 받는다. 

## 2. ES6

```javascript
let promise = new Promise((성공콜백, 실패콜백) => {
  console.log('프로미스 객체가 생성되지마자 바로 실행합니다. 작업자(프로미스)를 고용해놓고, 다음 작업으로 진행합니다.');
  
  setTimeout(() => {
    console.log('5초가 필요한 "Foo" 작업을 시뮬레이션했습니다. 그리고, 작업을 완료했습니다.');
    
    성공콜백('Foo');
  }, 5000);
});

promise.then(
  payload => console.log(`"${payload}" 작업이 성공하면 고용한 작업자가 대신 실행할 로직입니다.`), 
  error => console.log('작업이 실패하면 고용한 작업자가 대신 실행할 로직입니다.')
);
```

자바스크립트는 개발자가 제어할 수 없는 클라이언트에서 작동하고, 클라이언트 측의 인코딩때문에 어떤 문제가 발생할 지 예측할 수 없기 때문에 실무에서 한글 코딩은 절대 비추한다.

오늘 아침에서 Coffee 스크립트를 많이 사용하는 프레임워크 모임에 다녀왔는데, 이제 Coffee를 더 이상 쓸 이유가 없을 것 같다. 뿐만아니라 나를 괴롭히던 `Prototype`등은 이제 `class`, `constructor`, `static` 등 항상 쓰던 문법으로 완전히 교체되어 자바스크립트도 언어라는 느낌이 든다.

## 3. 결론

자고 일어나면 새로운 기술이 나오는 시대에서 풀 스택 웹 개발자로 살아 가기란 힘들다. 나처럼 서버 사이드에서 시작한 사람이 자바스크립트를 익힐 때 가장 먼저 만난 벽은 이벤트 프로그래밍이었고([블로킹 vs 논-블로킹 IO, Sync vs Async](http://laravel.io/bin/zjvNv)), 그 중에서도 프로미스였다. 어쨌든 이 포스트는 내가 프로미스를 이해한 내용에 대한 정리다.

프런트엔드를 잘 모르지만, 풀스택 개발자를 지향하는 후배들이 조언을 요청하면 요즘은 항상 이렇게 답해준다. 2016년에 배워야 할 프런트 엔드 기술은 1) [Vue.js](http://vuejs.org/), 2) [ES6](http://es6-features.org)라고.

다행히 내가 주력으로 하는 라라벨은 [Webpack](https://webpack.github.io/) 빌드시스템과, [Gulp](http://gulpjs.com/) 태스크 러너를 사용해서 다행히 두 개의 짐은 덜었다.  
