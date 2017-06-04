---
layout: post-minimal
title: '불변 밸류와 불변 엔티티'
date: 2017-06-04 00:00:00 +0900
categories:
- learn-n-think
tags:
- 개발자
---

**상수는 변하지 않는 값**, **변수는 변하는 값**이라고 배웠습니다. 객체에서도 마치 상수처럼 **한 번 생성된 이후에 상태를 변경할 수 없는 객체를 불변(Immutable) 객체**라고 합니다. 

## 1. 불변성에 대한 개념 익히기

아래 예제를 살펴 볼까요?

```php
<?php

$a = 1;
$b = $a;
$b = 3;
var_dump($a);
```

위 코드의 실행 결과는 `int(1)`입니다. 변수 `$b`에 변수 `$a`의 값을 할당한 후, `$b`에 새로운 값 `3`을 할당했습니다. 당연히 `$b`에는 `3`이 담겨 있고, `$a`에는 `1`이 담겨 있을 겁니다. 아주 쉽죠?
 
그런데, 객체 컨텍스트에서도 이 규칙이 그대로 적용될까요? 클래스는 변수와 함수로 구성된 템플릿이며, 객체란 그 템플릿에 필요한 값을 채워서 완성한 실체입니다. 여튼 위의 예제와 똑같이 동작해야 하지않을까요?

```php
<?php

$a = new stdClass;
$a->name = 'Foo';
$b = $a;
$b->name = 'Bar';
var_dump($b);
// class stdClass#696 (1) {
//   public $name =>
//   string(3) "Bar"
// }
var_dump($a);
// class stdClass#696 (1) {
//   public $name =>
//   string(3) "Bar"
// }
```

변수 `$b`에 `$a`에 담긴 객체를 그대로 할당한 후, `$b`의 `$name` 속성을 변경했습니다. `$b::name` 속성 값만 `"Bar"`로 바뀔 것이라 생각했지만, `$a::name` 속성 값도 `"Bar"`로 변경되어버렸습니다. `var_dump()`로 출력된 결과물에 객체 번호를 보면 힌트를 얻을 수 있습니다. `$a`와 `$b` 모두 `#696`으로 같습니다. 즉, 객체 `$b`는 객체 `$a`의 메모리 번지를 그냥 참조하고 있다고 볼 수 있습니다. 

해결법은 의외로 간단합니다. 복제하는거죠. `clone` 키워드와 객체 번호가 `#696`, `#697`로 서로 다름을 확인해주세요.

```php
<?php

$a = new stdClass;
$a->name = 'Foo';
$b = clone $a;
$b->name = 'Bar';
var_dump($b);
// class stdClass#697 (1) {
//   public $name =>
//   string(3) "Bar"
// }
var_dump($a);
// class stdClass#696 (1) {
//   public $name =>
//   string(3) "Foo"
// }
```

<!--more-->
<div class="spacer">• • •</div>

## 2. 불변 밸류

### 2.1. Carbon

라라벨 프로젝트에서 가장 쉽게 만날 수 있는 밸류 객체(Value Object, 값 객체)는 `Carbon` 입니다. 엘로퀀트 모델을 만들면 기본적으로 `created_at`, `updated_at`이란 속성이 추가되고, 이 속성에는 `Carbon` 객체가 할당됩니다. 

객체의 이점을 얻기 위해서 보통 원시 타입(`string`, `int`, `float`, `array`)을 밸류 객체로 바꿔서 사용하는데, 예를 들면, `string` 타입의 블로그 포스트 제목을 `Title` 객체를 만들어 사용하는 것 같은 것이죠. 예제가 현실적이지는 않지만, 앞서 말한 `Carbon`을 이용함으로써 다음과 같은 편리함이 더해집니다.

```bash
$ php artisan tinker
# Psy Shell v0.8.3 (PHP 7.1.2 — cli) by Justin Hileman
>>> $article = Article::first();
>>> $article->created_at = $article->created_at->addDays(5);
>>> $article->save();
```

**그런데 `Carbon`은 불변 밸류가 아닙니다.** 아래 예제는 무시무시합니다.

```bash
$ php artisan tinker
>>> $now = Carbon\Carbon::now();
# => Carbon\Carbon {#663
#      +"date": "2017-06-04 03:00:22.272655",
#    }
>>> $now->addMonths(1);
# => Carbon\Carbon {#663
#      +"date": "2017-07-04 03:00:22.272655",
#    }
>>> $now;
# => Carbon\Carbon {#663
#      +"date": "2017-07-04 03:00:22.272655",
#    }
```

`$now`라는 변수를 여러 곳에서 참조한다고 가정해보죠. 어떤 로직에서 `$now` 변수에 `addMonths()` API를 호출했다고 가정하죠. 그러면 그 뒤에 `$now` 변수를 참조하는 로직은 전부 한 달 뒤의 날짜 값을 사용하게 되는 겁니다. `Carbon`의 특성을 모르는 개발자가 이와 같이 코드를 짰을 때, `Carbon`의 특성에 대해 이해하고 있는 다른 개발자가 이 버그를 잡을 수 있을까요? 

아참 해결방법은 `clone` 키워드를 이용하는 것입니다.

```bash
$ php artisan tinker
>>> $now = Carbon\Carbon::now();
>>> $oneMonthFromNow = (clone $now)->addMonths(1);
```

### 2.2. Money

불변 객체는 한 번 생성된 이후에 상태를 변경할 수 없는 객체입니다. 아래 `Money` 클래스 예제를 살펴보면, `add()` 메서드는 다른 `Money` 객체를 인자로 받고, `$value` 속성의 상태를 변경하는 것이 아니라, 완전 새로운 `Money` 객체를 반환합니다. 

```php
<?php // https://github.com/appkr/db-lock-poc/blob/master/core/Myshop/Common/Model/Money.php

class Money
{
    private $value;
    
    public function __construct(int $value = 0)
    {
        $this->value = $value;
    }
    
    public function add(Money $other)
    {
        return new Money($this->value + $other->getAmount());
    }
    
    public function getAmount()
    {
        return $this->value;
    }
    
    public function isEqualTo(Money $other)
    {
        return get_class() === __CLASS__
            && $this->value === $other->getAmount();
    }
}
```

아래 팅커 출력 결과에서 객체의 번호가 `#683`, `#692`, `#694`로 모두 다름에 주목해야 합니다. 매번 다른 객체가 생성된다는 뜻이죠~

```bash
$ php artisan tinker
# Psy Shell v0.8.3 (PHP 7.1.2 — cli) by Justin Hileman
>>> $baseSalary = new Money(100);
# => Money {#683}
>>> $overtimeAllowance = new Money(100);
# => Money {#692}
>>> $baseSalary === $overtimeAllowance;
# => false
>>> $baseSalary->isEqualTo($overtimeAllowance);
# => true
>>> $totalSalary = $baseSalary->add($overtimeAllowance);
# => Money {#694}
>>> $totalSalary->getAmount();
# => 200
```

밸류 객체는 객체의 속성 값이 모두 같다면 "같다"라고 할 수 있습니다. `User` 객체를 예로 들어 볼까요? 공교롭게도 어떤 `User`가 저와 같은 `$name`, `$age`를 가지고 있다고 가정해보죠? 그럼 두 `User`는 같을까요? 당연히 다르죠? 그런데, 2017-06-04 라는 값을 가진 `Date` 객체를 가정해보죠. 다른 `Date` 객체가 똑같이 2017-06-04라는 값을 가지고 있다면 둘은 같은걸까요? 예. 예로 든 `Date`는 밸류이고, `User`는 엔티티입니다. 

## 3. 불변 엔티티

도메인 모델은 앤티티(Entity)와 밸류(Value, 값 객체)로 구분됩니다. 모델, 엔티티, 밸류, ... 어려운 용어라 생각되지만, 따지고보면 결국은 클래스입니다. 앞서 클래스는 변수와 함수의 집합이라 했는데, 좀 더 구체적으로 말하면 다음과 같이 표현할 수 있습니다.

> 클래스란 Private 변수들과 그 Private 변수들을 사용하는 Public 함수들의 집합이다.

엔티티는 고유 식별자를 가지고 있습니다. 엔티티는 생성된 후 식별자를 제외한 상태가 변경될 수 있습니다. "상태"라 표현한 것이 결국 클래스의 Private 변수들의 값이며, 이 Private 변수에는 다른 엔티티, 밸류 객체, 원시 타입 값들이 담기게 됩니다. 엔티티를 사용하는 클라이언트 클래스에서 엔티티의 Public 함수(API)를 호출하여 엔티티의 상태를 변경하겠죠~ 

밸류는 식별자가 없습니다. `Carbon`처럼 상태가 변경될 수도 있지만, 앞서 살펴본 대로 불변 객체를 사용하는 것이 더 나은 설계라고 알려져 있습니다. 앞서 살펴본 `Money` 밸류처럼 말이죠. 밸류 객체 역시, 해당 밸류를 상태로 사용하는 엔티티가 대상 밸류에 포함된 Public API를 호출함으로써 엔티티 자신의 상태를 변경할 겁니다. 

객체로 생성되어 메모리에 살아 있는 동안 상태를 변경하고, 데이터베이스에 저장함으로써 다시 꺼내서 재생할 때까지 냉동 수면을 하게 됩니다.

그런데 불변 엔티티란 무엇일까요? 웹에서 정확한 정의를 찾지 못했습니다만, 앞서 살펴본 내용을 응용해보면, 최초 한번 생성후 상태가 변하지 않는 엔티티가 아닐까요? Private 변수에 담긴 값을 전혀 변경할 수 없고, 데이터베이스에서 삭제하기 전까지 돌부처 같이 처음 만든 상태를 그대로 유지하는 녀석이 아닐까요? 

### 3.1. 필요성

지난 번 회사 프로젝트를 하면서 불변 엔티티의 필요성을 느꼈습니다.
 
- 생성 시점의 정보를 참조해서 계산한 값으로 채워진 모델일 때 (e.g. 청구서)
- 그리고 한 번 생성된 후, 상태가 변경된다면 변경 이력을 추적해야 할 때
- 시간이 지남에 따라 변경될 수 있는 값을 생성 시점의 값으로 고정시키고자 할 때 (e.g. 청구서 발행 시점의 피청구자 정보)

### 3.2. 리서치

조사 결과 세 가지 정도의 구현 방식으로 정리됐습니다.

#### 3.2.1. 상태 테이블과 변경 내역 저장 테이블 분리

최종 상태를 저장하는 메인 테이블과 변경 이력을 기록하는 테이블을 별도로 구성하는 방식입니다.

```bash
Table: bills
+-------------------------------+
| 1 Bill for User#1 for 2017-06 |
+-------------------------------+
| 2 Bill for User#2 for 2017-06 |
+-------------------------------+

UPDATE bills SET base_charge = 100 WHERE id = 1;

Tables:bill_history
+-------------------------------+
| History for bill_id#1 {...}   |
+-------------------------------+
| History for bill_id#1 {...}   |
+-------------------------------+

INSERT INTO bill_history (bill_id, changed, changed_by, changed_at, ...) 
VALUES (1, "{original:{base_charge:90}, changed:{base_charge:100}}", "Foo", NOW(), ...);
```

#### 3.2.2. 하나의 엔티티에 대해 여러 레코드를 기록

3.2.1의 두 개 테이블을 하나로 합쳐서 상태를 저장하는 방식입니다. `UPDATE` 쿼리는 없고, 오직 `INSERT`만 허용합니다.

```bash
Table: bills
+-------------------------------+
| Last state of Bill#1          |
+-------------------------------+
| Past state of Bill#1          |
+-------------------------------+
| Last state of Bill#2          |
+-------------------------------+
SELECT * FROM bills WHERE entity_id = 1 ORDER BY version DESC LIMIT 1;

INSERT INTO bills (entity_id, version, subscriber_id, term, base_charge, 
    valud_added_charge, discount_amout, fulfilled, last_modified_by, ...)
VALUES (1, 2, 1, "2017-06", 100, 100, 50, false, "Foo", ...);
```

#### 3.2.3. 이벤트 소싱

이벤트를 데이터 소스로 사용하는 디자인 패턴입니다. 이벤트 데이터를 스택에 쌓아 놓고, 이벤트 리플레이를 통해 현재 상태를 계산해 냅니다. 핵심 함수와 전체 개념은 아래와 같습니다.

```scala
decide(command, state) => ListEvent
apply(state, event) => state
replay(initialState, ListEvent) => (state, version)
```

![](http://blog.leifbattermann.de/wp-content/uploads/2017/04/event-sourcing.svg)

웹에서 만난 전문가들도 이벤트 소싱의 이점을 충분히 누릴 수 있는 도메인에만 도입할 것을 권장합니다. 포스트 끝에 참고 자료들을 기록해 두었습니다.

### 3.3. 예제 프로젝트

매월 주기적으로 핸드폰 청구서를 발행하는 예제를 통해서 불변 엔티티를 구현해 보고자 합니다. 데이터를 자주 변경하는 도메인이 아니므로 3.2.2 방식으로 구현하려고 합니다.   

틈틈이 작업 중인 저장소입니다. [https://github.com/appkr/immutable-entity-poc](https://github.com/appkr/immutable-entity-poc)

---

## 읽어보면 좋을만한 자료들

- [doctrine-best-practices](https://ocramius.github.io/doctrine-best-practices)
- [About Entities, Aggregates and Data Duplication.](http://ziobrando.blogspot.kr/2010/06/about-entities-aggregates-and-data.html)
- [Why I Don’t Use Value Objects in Laravel Anymore](http://www.ntaso.com/why-i-dont-use-value-objects-in-laravel-anymore/)
- [Value Objects in Laravel 5 with Eloquent Done Right](http://www.ntaso.com/value-objects-laravel-eloquent/)
- [이벤트 소싱 학습 내용 공유 by 최범균](https://www.slideshare.net/madvirus/event-source)
- [12 Things You Should Know About Event Sourcing](http://blog.leifbattermann.de/2017/04/21/12-things-you-should-know-about-event-sourcing/)
- [Cutting Edge - Event Sourcing for the Common Application](https://msdn.microsoft.com/magazine/mt422577)
- [이벤트 소싱 패턴과 CQRS 패턴을 적용해서 클라우드상에서 유연하게 앱 개발하기](http://blog.aliencube.org/ko/2015/11/12/building-applications-on-cloud-with-event-sourcing-pattern-and-cqrs-pattern/)
- [Laravel adapter for Broadway.](https://github.com/nWidart/Laravel-broadway)
