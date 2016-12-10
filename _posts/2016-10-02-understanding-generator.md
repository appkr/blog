---
layout: post-minimal
title: '제너레이터 이해하기' 
date: 2016-10-02 00:00:00 +0900
categories:
- learn-n-think
tags:
- 개발자
- Generator
image: /images/2016-08-10-img-01.png
---

제너레이터(generator)는 대용량 데이터를 순회하며 작업할 때 유용한 기능이며, 대부분의 프로그래밍 언어에서 찾아볼 수 있다. 언어만 다를 뿐 개념은 모두 같다. 이 포스트는 자바스크립트 및 PHP 제너레이터에 대한 필자 나름의 이해 방식을 기록한 것이다. 

<!--more-->
<div class="spacer">• • •</div>

## 1. 예제 - ES6

```javascript
1 | function * numbers(){
2 |   console.log('Hello Generator!');
3 |   yield 1;
4 |   yield 2;
5 | }

let iterator = numbers();
```

ES6에서는 함수 선언에 별표(`*`)를 붙여서 함수가 아니라 제너레이터임을 표시한다. `iterator` 변수에 방금 만든 제너레이터를 할당했다. 변수 이름에서 알 수 있듯이 함수의 모양을 빌렸지만, 개념적으로는 이터레이터(반복기)다.

함수 시작부에 `console.log('Hello Generator!');`를 찍었지만 아무일도 일어나지 않았다. 지금은 대기 상태라 할 수 있다. 제너레이터를 실행하려면 `next()` 메서드를 호출하면 된다.

```javascript
console.log(iterator.next());
// Hello Generator!
// Object {value: 1, done: false}
```

이제 제너레이터 객체를 생성하고 첫번째 `yield` 키워드까지 실행한다. `yield` 키워드는 값을 반환한다는 측면에서 `return` 키워드와 비슷하면서도 다르다. `return`은 뒤에 나오는 로직을 전부 무시하지만, `yield`는 `iterator`가 불러주면 또 다시 동작한다. `done: false`를 주목한다.

또 실행한다.

```javascript
console.log(iterator.next());
// Object {value: 2, done: false}
```

`console.log(...)`와 첫번째 `yield` 키워드는 건너뛰었다. 두번째 `yield` 키워드에 의해 `value`는 2로 바뀌었지만 아직 `done: flase`이다.

한번 더 실행한다.

```javascript
console.log(iterator.next());
// Object {value: undefined, done: true}
```

이제 더 이상 실행할 `yield` 키워드가 없다. `done: true`로 바뀌었다.

[![Generator in action](/images/2016-08-10-img-01.png)](/images/2016-08-10-img-01.png)

## 2. 해부하기

앞 절에서 실험한 내용을 그림으로 정리하면 다음과 같다.

```
iterator                                numbers(generator instance)
|                                       |
|next();───────────────────────────────>|console.log(...); 실행
|                                       |yield 1; 실행하고 상태 저장
|                       Hello Generator!|
|                {value: 1, done: false}|
|<──────────────────────────────────────|
|next();───────────────────────────────>|yield 2; 실행하고 상태 저장
|                {value: 2, done: false}|
|<──────────────────────────────────────|
|next();───────────────────────────────>|더 이상 실행할 로직이 없음
|         {value: undefined, done: true}|
|<──────────────────────────────────────|
|                                       |
```

전부 정리해 보면 제너레이터는(개인적인 이해일 뿐이다)

- 일회용 이터레이터다.
- 호출하는 쪽에서 이터레이션의 시작과 다음 이터레이션을 제어할 수 있다(On-demand Iteration).
- 어디까지 실행했는지 상태를 가진 객체다.

## 3. 예제 - PHP

실전에 사용한 예제는 AWS PHP SDK에서 찾아 볼 수 있다. AWS SDK에서 이터레이션은 거의 대부분 제너레이터를 사용하는 것을 볼 수 있다.

```php
<?php
// https://github.com/aws/aws-sdk-php/blob/master/src/functions.php#L49

namespace Aws;

/**
 * Applies a map function $f to each value in a collection.
 *
 * @param mixed    $iterable Iterable sequence of data.
 * @param callable $f        Map function to apply.
 *
 * @return \Generator
 */
function map($iterable, callable $f)
{
    foreach ($iterable as $value) {
        yield $f($value);
    }
}
```

이렇게 사용할 수 있다. 

```php
<?php

$generator = Aws\map(range(1, 1000000), function ($value) {
    return $value * 2;
});

foreach ($generator as $number) {
    echo $number, PHP_EOL;
}
```

이 예제에서는 큰 차이를 못 느낄 수 있지만, 배열 요소 하나가 큰 데이터를 가지고 있을 때는 제너레이터를 쓰지 않고는 `php.ini` 설정에서 `memory_limit` 값을 엄청 늘려야 할 것이다. 배열 순회에 필요한 모든 데이터를 메모리에 적재한 후 실행하는 것과, 이번 순회에 필요한 데이터만 읽어오는 차이가 있다.
