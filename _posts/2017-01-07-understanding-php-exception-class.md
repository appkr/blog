---
layout: post-minimal
title: 'PHP의 예외 클래스 이해하기' 
date: 2017-01-07 00:00:00 +0900
categories:
  - work-n-play
tags:
  - 개발자
  - PHP
image: 
---

국어 사전에서는 **'일반적인 규칙이나 정례에서 벗어나는 일'**을 예외라고 정의하고 있다.

컴퓨터에서 예외란 **'프로그램을 실행하는 중에 발생하는 비정상적인 상황'**으로 프로그램의 일반적인 실행 흐름을 바꾼다. 예를 들어 함수에 허용하지 않는 인자가 전달되었다거나, 디스크에서 무언가를 읽거나 써야 하는데 디스크에 접근할 수 없다거나, 메모리 공간이 부족해서 변수 값을 저장할 수 없는 경우 등을 들 수 있다. 

개발자는 프로그래밍을 할 때 발생할 수 있는 예외 상황을 미리 식별하고, 앞서 말한 상황이 발생하면 예외를 던지고(Throw 또는 Raise), 잡은 예외를 개발자 자신만의 방식으로 핸들링할 수 있다(Catch 또는 Rescue). 개발자가 예상치 못한 예외라면 런타임(PHP의 경우라면 PHP 엔진)이 프로그램의 실행을 멈추고 오류 메시지를 출력하는 등의 일을 할 것이다.

[![](http://rypress.com/tutorials/objective-c/media/exceptions/exceptions-vs-errors.png)](http://rypress.com/tutorials/objective-c/media/exceptions/exceptions-vs-errors.png)

위 그림은 Objective-C 쪽 얘긴데, 사실 PHP에서 완전 반대다. 어쨌든 PHP 7부터는 `try {...} catch {...}` 구문에서 예외(Exception) 뿐만 아니라, 오류(Error)도 캐치할 수 있도록 지원하고 있다.

이 포스트에서는 PHP의 예외 클래스(Exception Class)를 사용하는 기본적인 방법을 설명한다.
 
<!--more-->
<div class="spacer">• • •</div>

다음 PHP 예제 코드는 예외 클래스의 기본적인 사용법을 담고 있다. 

```php
<?php // exceptions.php

/**
 * 개발자가 직접 소비하지 않은 예외를 처리하기 위한 전역 예외 처리기.
 */
function exception_handler($e)
{
    var_dump(
        $e->getMessage(),
        get_class($e->getPrevious())
    );
}

/**
 * 전역 예외 처리기를 설정한다.
 * 여기까지가 일종의 프레임워크 부트스트랩 부분이다.
 */
set_exception_handler('exception_handler');

/**
 * 실행할 때 예외를 식별하고 예외를 던지도록 구현해 놓은 함수. 
 * 외부에서 가져온 라이브러리나 직접 구현한 서비스라고 가정 하자. 
 */
function foo($arg)
{
    if (is_int($arg) === false) {
        throw new InvalidArgumentException('입력한 인자가 정수가 아닙니다.');
    }

    return "함수가 받은 인자는 {$arg}입니다.";
}

/**
 * 여기서 부터 클라이언트 코드(우리가 짠 애플리케이션)라고 가정하자.
 */ 
try {
    var_dump(foo(1));
} catch (Throwable $e) {
    var_dump(
        $e->getMessage(), 
        $e->getCode(), 
        $e->getFile(), 
        $e->getLine(), 
        $e->getTrace(), 
        $e->getPrevious(), 
        $e->getTraceAsString()
    );

    throw new Exception(
        '예외 체인을 따라 버블 업 합니다.' . $e->getMessage(),
        $e->getCode(),
        $e
    );
} finally {
    var_dump('Finally 안쪽의 문장은 무조건 실행됩니다.');
}

var_dump('마지막 문장입니다.');
```

PHP에서 예외를 던질 때는 `throw` 키워드를 사용하고, 그 다음에 던질 예외 클래스의 객체를 제공하면 된다. 

```php
<?php

throw new FooException('메시지');
```

예외 클래스의 프로토타입(생성자의 인자)은 다음과 같다. 대괄호는 배열 문법이 아니고, 선택사항(optional)이란 뜻이다. 즉 생성자에 아무런 인자를 안 넣어도 된다.
  
```bash
Exception::__construct ([ string $message = "" [, int $code = 0 [, Throwable $previous = NULL ]]] )
```

`Exception`은 PHP의 SPL(Standard PHP Library, PHP 바이너리에 내장)이 제공하는 최상위 예외 클래스다. 우리 예제 코드에서 사용한 `InvalidArgumentException`과 `Exception`과의 상속 관계는 다음과 같다. 살짝 스포일링하자면, SPL 또는 프레임워크가 제공하는 예외 클래스를 상속하여 우리만의 커스컴 예외 클래스를 만들 수 있다.

```
InvalidArgumentException -> LogicException -> Exception
```

## 1. 정상 실행

이 코드의 실행 결과는 다음과 같다.

```bash
~/working-with-exceptions $ php exceptions.php
```

```bash
~/working-with-exceptions/exceptions.php:33:
string(38) "함수가 받은 인자는 1입니다."

~/working-with-exceptions/exceptions.php:51:
string(54) "Finally 안쪽의 문장은 무조건 실행됩니다."

~/working-with-exceptions/exceptions.php:54:
string(26) "마지막 문장입니다."
```

-   `foo()` 함수를 `try {}` 블록 안에서 호출하고 있다. 
-   `foo()` 함수는 정수 `1`을 인자로 받았으므로, `if (is_int($arg) === false) {...}` 부분을 통과하고 정상적으로 값을 반환한다.
-   `finally {}` 블록 안의 내용은 예외가 발생하든 하지 않든 무조건 실행된다.
-   `try {} catch {}` 블록에서 `throw` 또는 `return` 구문을 만나지 않았으므로 마지막 문장은 실행된다. 

## 2. 예외 상황

예외 상황을 만들어 보자.

```php
<?php // exceptions.php

// ...

try {
    var_dump(foo('string'));
} catch (Throwable $e) {
    // ...
}

// ...
```

수정한 코드의 실행 결과는 다음과 같다.

```bash
~/working-with-exceptions $ php exceptions.php
```

```bash
~/working-with-exceptions/exceptions.php:42:
string(43) "입력한 인자가 정수가 아닙니다."

~/working-with-exceptions/exceptions.php:42:
int(0)

~/working-with-exceptions/exceptions.php:42:
string(37) "~/working-with-exceptions/exceptions.php"

~/working-with-exceptions/exceptions.php:42:
int(25)

~/working-with-exceptions/exceptions.php:42:
array(1) {
  [0] =>
  array(4) {
    'file' =>
    string(37) "~/working-with-exceptions/exceptions.php"
    'line' =>
    int(33)
    'function' =>
    string(3) "foo"
    'args' =>
    array(1) {
      [0] =>
      string(6) "string"
    }
  }
}

~/working-with-exceptions/exceptions.php:42:
NULL

~/working-with-exceptions/exceptions.php:42:
string(69) "#0 ~/working-with-exceptions/exceptions.php(33): foo('string')
#1 {main}"

~/working-with-exceptions/exceptions.php:51:
string(54) "Finally 안쪽의 문장은 무조건 실행됩니다."

~/working-with-exceptions/exceptions.php:10:
string(88) "예외 체인을 따라 버블 업 합니다.입력한 인자가 정수가 아닙니다."

~/working-with-exceptions/exceptions.php:10:
string(24) "InvalidArgumentException"
```

-   `foo()` 함수는 문자열 `'string'`을 인자로 받았으므로, `if (is_int($arg) === false) {...}` 부분에 걸려 `InvalidArgumentException`을 던진다. 프로그램의 실행 제어 측면에서 `throw` 키워드는 해당 블록에서 `throw` 다음 문장을 실행하지 않는다는 점에서 `return`과 같다.
-   `foo()` 함수에서 던진 예외는 `catch (Throwable $e) {...}`에서 잡는다. 예외를 잡을 때는 잡을 예외 별로 `catch` 블록을 쓸 수 있다. 우리 예제에서는 `Throwable`이란 녀석을 전부 잡겠다고 선언하고 있는데, 이는 PHP 7이상의 기능으로 모든 예외와 모든 오류를 전부 잡겠다는 의미다.
-   우리의 `catch` 블록에서는 잡은 예외 객체가 제공하는 다양한 메서드를 보여주고 있다. 즉, 이 예외 메서드들을 이용하여 로깅을 하거나 슬랙을 보내는 등의 예외 처리를 할 수 있다. 해당 내용은 다음 포스트를 참고 하시기 바란다. 
    -   [Monolog를 이용한 애플리케이션 로깅](http://blog.appkr.kr/work-n-play/php-application-logging-to-elasticsearch-using-monolog/)
    -   [엄청나게 빠른 버그 감지, 디버그, 코드 배포](http://blog.appkr.kr/work-n-play/super-fast-debug-deploy/)
-   예외 처리를 끝내고 다시 예외를 던질 수도 있는데, 이때는 `try {...} catch {...}` 블록 밖으로 예외를 던지는 것이고, 이 녀석을 다시 잡는 부분이 없으므로, 코드 시작 부분에 등록한 전역 예외 처리기(`exception_handler()`) 함수가 작동한다. 전역 예외 처리기에서 `getPrevious()` 메서드를 이용해서 예외 발생의 선후 관계를 확인할 수 있다는 점을 유심히 봐두기 바란다. 실무에서 디버깅할 때 엄청난 도움이 될 수 있다.
-   `finally {}` 블록 안의 내용은 예외가 발생하든 하지 않든 무조건 실행된다.
-   `catch` 블록에서 예외를 다시 던졌으므로, 그 이하의 내용, 즉 마지막 문장은 실행되지 않는다.

## 3. 예외 처리 로직 분기

우리 예제에서는 `foo()` 함수를 실행할 때 `InvalidArgumentException`만 발생하지만, 실제로는 `try` 블록 안쪽의 코드를 실행하는 동안 다양한 예외가 발생할 수 있다. 이 때 `catch` 블록에 딱 정확한 예외 이름을 타입 힌트로 제공해서 예외 처리 로직을 분기할 수 있다. 예제 코드를 다음과 같이 수정했다.

```php
<?php // exceptions.php

// ...

try {
    var_dump(foo('string'));
} catch (InvalidArgumentException $e) {
    var_dump('첫번째 catch 블록');
} catch (UnexpectedValueException $e) {
    var_dump('두번째 catch 블록');
} catch (Exception $e) {
    var_dump('세번째 catch 블록');
}

// ...
```

실행하면 다음 결과를 볼 수 있다.

```bash
~/working-with-exceptions $ php exceptions.php
```

```bash
~/working-with-exceptions/exceptions.php:36:
string(22) "첫번째 catch 블록"

~/working-with-exceptions/exceptions.php:64:
string(26) "마지막 문장입니다."
```

`catch`에서 잡는 예외의 순서는 중요하다. 예제를 보자.

```php
<?php // exceptions.php

// ...

try {
    var_dump(foo('string'));
} catch (Exception $e) {
    var_dump('엉뚱한 예외 처리 로직');
} catch (InvalidArgumentException $e) {
    var_dump('우리가 기대하던 내용');
}

// ...
```

실행 결과는 이렇다. 항상 구체적인 예외, 즉 자식 예외에서 부모 예외 순으로 잡아야 한다.

```bash
~/working-with-exceptions $ php exceptions.php
```

```bash
~/working-with-exceptions/exceptions.php:36:
string(30) "엉뚱한 예외 처리 로직"

~/working-with-exceptions/exceptions.php:65:
string(26) "마지막 문장입니다."
```

## 4. 결론

예외를 처리하지 않는 경우를 상상해 보자. `foo()` 함수에 타입 힌트를 써서 예외 상황을 만들었다.

```php
<?php

function foo(int $arg)
{
    return "함수가 받은 인자는 {$arg}입니다.";
}

var_dump(foo('string'));
```

이 코드의 실행 결과는 다음과 같다. 전역 예외 처리기 또는 에러 처리가가 없으므로, PHP 런타임이 치명적 오류(Fatal error)를 내 뱉고 있는 상황이다. 운영 중인 웹 사이트에서 이런 메시지가 나온 적이 있는가? 그런데, 이 상황을 몇 시간째 모르고 있었던 경우는 없는가? 아찔하다~

```bash
PHP Fatal error:  Uncaught TypeError: Argument 1 passed to foo() must be of the type integer, string given, called in /Users/appkr/workspace/exceptions.php on line 31 and defined in /Users/appkr/workspace/exceptions.php:22
Stack trace:
#0 /Users/appkr/workspace/exceptions.php(31): foo('string')
#1 {main}
  thrown in /Users/appkr/workspace/exceptions.php on line 22

Call Stack:
    0.0002     355912   1. {main}() /Users/appkr/workspace/exceptions.php:0
    0.0002     355912   2. foo() /Users/appkr/workspace/exceptions.php:31
```

다음 편에서는 라라벨 프레임워크를 이용해서 커스텀 예외 클래스를 만들고 프로그램 실행 흐름을 안전하게 제어하는 방법을 살펴 보기로 하자.
