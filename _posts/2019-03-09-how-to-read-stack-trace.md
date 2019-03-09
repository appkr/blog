---
layout: post-minimal
title: '스택 트레이스 읽는 법'
date: 2019-03-09 00:00:00 +0900
categories:
- learn-n-think
tags:
- Programming
image: https://i.stack.imgur.com/HOY4C.png
---

이번 포스트는 프로그램 실행 중에 만나는 스택 트레이스, 즉 예외 또는 에러 메시지를 읽는 법을 다루려고 합니다. 메모리의 스택 영역에 기록된 프로그램의 실행 이력을 역 추적하기때문에 스택 트레이스, 스택 백트레이스, 스택 트랙백이라 부른다는군요([위키피디아](https://en.wikipedia.org/wiki/Stack_trace)). 

[![메모리 다이어그램](https://i.stack.imgur.com/HOY4C.png)](https://i.stack.imgur.com/HOY4C.png)

<small>그림출처: https://i.stack.imgur.com/HOY4C.png</small>

<!--more-->
<div class="spacer">• • •</div>

## 1 실행 흐름

사전에서 프로그램을 찾아 보면, "진행 계획이나 순서, 또는 그 목록"이라 나옵니다. 연주회, 연극등의 편성표를 프로그램이라 하지요. 즉 순서대로 실행되는 일련의 작업 목록을 프로그램이라고 부릅니다.  

그럼, 일반적으로 컴퓨터 프로그램은 어떻게 실행되지는지 살펴볼까요?

```php
1  <?php
2 
3  foo();
4 
5  function foo() { 
6      echo '1', PHP_EOL;
7      bar();
8      echo '5', PHP_EOL;
9  }
10
11 function bar() { 
12     echo '2', PHP_EOL;
13     baz();
14     echo '4', PHP_EOL;
15 }
16 
17 function baz() { 
18     echo '3', PHP_EOL;
19 }
```

실행 결과는 이렇습니다.

```bash
$ php main.php
1
2
3
4
5
```

- 3번 줄에서 `foo()` 함수를 호출합니다.
- 6번 줄에서 "1"을 출력합니다.
- 7번 줄에서 `bar()` 함수를 호출합니다.
- 12번 줄에서 "2"를 출력합니다.
- 13번 줄에서 `baz()` 함수를 호출합니다.
- 18번 줄에서 "3"을 출력합니다.
- 14번 줄에서 "4"를 출력합니다.
- 8번 줄에서 "5"를 출력합니다.

어렵지 않죠?

## 2 예외 상황

`baz()` 함수에서 예외를 만들고 결과를 살펴보겠습니다.

```php
1  <?php
2  
3  foo();
4
5  function foo() { 
6      bar();
7  }
8
9  function bar() { 
10     baz();
11 }
12
13 function baz() { 
14     throw new RuntimeException('런타임 예외가 발생했습니다');
15     echo '이 라인은 출력되지 않습니다'; 
16 }
```

```bash
$ php exception.php
PHP Fatal error:  Uncaught RuntimeException: 런타임 예외가 발생했습니다 in /Users/appkr/workspace/stack-trace/php/exception.php:14
Stack trace:
#0 /Users/appkr/workspace/stack-trace/php/exception.php(10): baz()
#1 /Users/appkr/workspace/stack-trace/php/exception.php(6): bar()
#2 /Users/appkr/workspace/stack-trace/php/exception.php(3): foo()
#3 {main}
  thrown in /Users/appkr/workspace/stack-trace/php/exception.php on line 14
```

스택 트레이스를 하나씩 뜯어 보겠습니다.

- 첫 줄을 통해 `/Users/appkr/workspace/stack-trace/php/exception.php` 파일의 14번 줄에서 `RuntimeException`이 발생했고, 메시지는 `런타임 예외가 발생했습니다`라는 사실을 알 수 있습니다. 
- 첫 줄에서 문제의 원인을 알 수 있다면 아래 내용은 읽을 필요가 없습니다.
- 총 4 개의 스택 프레임이 잡혔는데, 시간 역순으로 기록되어 있습니다. 
- `#2 exception.php` 3번 줄에서 `foo()` 함수를 호출했네요.
- `#1 exception.php` 6번 줄에서 `bar()` 함수를 호출했네요.
- `#0 exception.php` 10번 줄에서 `baz()` 함수를 호출했네요.

어떤가요, 1절에서 본 내용과 전혀 다르지 않죠?

## 3 사용자 정의 예외 및 처리

시스템에서 제공하는 예외를 그대로 사용하기 보다는, 비즈니스에서 사용하는 보편 언어를 사용하여 의미를 담은 예외를 정의하여 던지는 것이 더 좋은 구현이라고 알려져있습니다. 아래 예제처럼요.

```php
1  <?php
2  
3  try {
4      foo();
5  } catch (RuntimeException $e) {
6      throw new CustomException('사용자 정의 예외가 발생했습니다');
7  }
8
9  class CustomException extends RuntimeException {}
10
11 function foo() { 
12     bar();
13 }
14
15 function bar() { 
16     baz();
17 }
18
19 function baz() { 
20     throw new RuntimeException('런타임 예외가 발생했습니다');
21     echo '이 라인은 출력되지 않습니다'; 
22 }
```
```bash
$ php custom_exception.php
PHP Fatal error:  Uncaught CustomException: 사용자 정의 예외가 발생했습니다 in /Users/appkr/workspace/stack-trace/php/custom_exception.php:6
Stack trace:
#0 {main}
  thrown in /Users/appkr/workspace/stack-trace/php/custom_exception.php on line 6
``` 

그런데 위 스택 트레이스는 문제를 일으킨 근본 원인(Root Cause)이 무엇인지 보이지 않는다는 문제가 있습니다.

`catch` 블록에서 `CustomException`을 던질 때, 직전 예외를 생성자에 넣어 주는 것 만으로 쉽게 해결할 수 있습니다.

```php
1  <?php
2
3  try {
4      foo();
5  } catch (RuntimeException $e) {
6      throw new CustomException('사용자 정의 예외가 발생했습니다', null, $e);
7  }
8  // 생략
```
```bash
$ php handle_exception.php
PHP Fatal error:  Uncaught RuntimeException: 런타임 예외가 발생했습니다 in /Users/appkr/workspace/stack-trace/php/handle_exception.php:20
Stack trace:
#0 /Users/appkr/workspace/stack-trace/php/handle_exception.php(16): baz()
#1 /Users/appkr/workspace/stack-trace/php/handle_exception.php(12): bar()
#2 /Users/appkr/workspace/stack-trace/php/handle_exception.php(4): foo()
#3 {main}

Next CustomException: 사용자 정의 예외가 발생했습니다 in /Users/appkr/workspace/stack-trace/php/handle_exception.php:6
Stack trace:
#0 {main}
  thrown in /Users/appkr/workspace/stack-trace/php/handle_exception.php on line 6
```

## 4 현실 세계

현실 세계의 코드는 예제처럼 간단하지는 않습니다. 그럼에도 불구하고 다음 두 가지만 기억하면 디버깅할 때 도움이 됩니다.

- **첫 줄**을 잘 보라.
- 첫 줄에서 힌트를 찾을 수 없을 때는, 전체 스택 트레이스를 따라가면서 **내가 짠 코드**에서 원인을 찾아라.

현실 세계의 예제를 한번 볼까요? 라라벨 프레임워크를 사용하는 프로젝트에서 사용자 인증을 위해 JWT 발급했는데, 사용자가 블랙리스트에 등록된 JWT를 제출한 케이스입니다.

```bash
| ---------------------------------------> |
| GET /protected_resource                  |
| Authorization: Bearer ey..OE             |
|                                          |
| <--------------------------------------- |
| 401 Unauthorized                         |
| {                                        |
|   "error": "UnauthorizedTokenException", |
|   "message": "Invalid token, please .."  |
| }                                        |
```
```bash
# /var/www/html/storage/logs/laravel.log
[2019-03-09 23:10:02] local.NOTICE: Tymon\JWTAuth\Exceptions\TokenBlacklistedException: The token has been blacklisted in /var/www/html/vendor/tymon/jwt-auth/src/Manager.php:109
Stack trace:
#0 /var/www/html/vendor/tymon/jwt-auth/src/JWT.php(200): Tymon\JWTAuth\Manager->decode(Object(Tymon\JWTAuth\Token))
#1 /var/www/html/vendor/tymon/jwt-auth/src/JWTAuth.php(64): Tymon\JWTAuth\JWT->getPayload()
#2 /var/www/html/app/Http/Middleware/JWTAuthenticate.php(61): Tymon\JWTAuth\JWTAuth->authenticate()
#3 /var/www/html/app/Http/Middleware/JWTAuthenticate.php(26): App\Http\Middleware\JWTAuthenticate->authenticate(Object(Illuminate\Http\Request))
#4 [internal function]: App\Http\Middleware\JWTAuthenticate->handle(Object(Illuminate\Http\Request), Object(Closure))
#...
#51 {main}

Next My\Domain\Auth\Exceptions\UnauthorizedTokenException: Invalid token, please sign in again in /var/www/html/app/Http/Middleware/JWTAuthenticate.php:66
Stack trace:
#0 /var/www/html/app/Http/Middleware/JWTAuthenticate.php(26): App\Http\Middleware\JWTAuthenticate->authenticate(Object(Illuminate\Http\Request))
#...
#48 {main}  {
    "app_version": "UNKNOWN",
    "instance_id": "acb25dd1a048",
    "transaction_id": "766ffefe-ac00-47ef-bc68-4cd7553decea",
    "trace_number": 0
}
```

다음의 정보를 얻을 수 있습니다.

- 사용자가 제출한 JWT 토큰이 블랙리스트되서 발생한 `NOTICE` 레벨의 예외.
- 블랙리스트 여부를 검사하고 예외를 던진 위치는 `/var/www/html/vendor/tymon/jwt-auth/src/Manager.php` 파일의 109 줄.
- 예외가 발생시킨 함수는 `Tymon\JWTAuth\Manager::decode()`이며, 이 함수를 `/var/www/html/vendor/tymon/jwt-auth/src/JWT.php` 200 줄에서 호출.
- `My\Domain\Auth\Exceptions\UnauthorizedTokenException` 라는 도메인 예외가 발생했고, (핸들링 로직에 따라) 사용자는 "Invalid token, please sign in again"라는 메시지를 담은 JSON 예외 응답을 받았을 것.

<!--more-->
<div class="spacer">• • •</div>

## 5 다른 프로그래밍 언어

### 5.1 Java

```java
1  class CustomException extends RuntimeException {
2      public CustomException(String message, Throwable previous) {
3          super(message, previous);
4      }
5  }
6 
7  public class main {
8      static void foo() {
9          bar();
10     }
11
12     static void bar() {
13         baz();
14     }
15
16     static void baz() {
17         throw new RuntimeException("런타임 예외가 발생했습니다");
18         // System.out.println("이 라인은 컴파일 오류를 일으킵니다");
19     }
20 
21     public static void main(String[] args) {
22         try {
23             foo();
24         } catch (RuntimeException e) {
25             throw new CustomException("사용자 정의 예외가 발생했습니다", e);
26         }
27     }
28 }
```
```bash
$ javac main.java && java main
Exception in thread "main" CustomException: 사용자 정의 예외가 발생했습니다
    at main.main(main.java:25)
Caused by: java.lang.RuntimeException: 런타임 예외가 발생했습니다
    at main.baz(main.java:17)
    at main.bar(main.java:13)
    at main.foo(main.java:9)
    at main.main(main.java:23)
```

예외의 근본원인을 `Caused by:` 로 표시하는 부분을 제외하면 거의 똑같습니다.

### 5.2 Ruby

```ruby
1  class CustomError < RuntimeError
2  end
3 
4  def foo()
5      bar()
6  end
7
8  def bar()
9      baz()
10 end
11
12 def baz()
13     raise RuntimeError.new('런타임 예외가 발생했습니다')
14     p '이 라인은 출력되지 않습니다'
15 end
16 
17 begin
18     foo()    
19 rescue 
20     raise CustomError.new('사용자 정의 예외가 발생했습니다')
21 end
```
```bash
$ ruby main.rb
Traceback (most recent call last):
  	3: from main.rb:18:in `<main>'
  	2: from main.rb:5:in `foo'
  	1: from main.rb:9:in `bar'
main.rb:13:in `baz': 런타임 예외가 발생했습니다 (RuntimeError)
  	1: from main.rb:17:in `<main>'
main.rb:20:in `rescue in <main>': 사용자 정의 예외가 발생했습니다 (CustomError)
```

크게 다르지 않습니다. 다만 시간 역순이 아니라 시간순으로 표현하고 있으며, 예외 메시지를 중간에 찍어 주고 있습니다.
