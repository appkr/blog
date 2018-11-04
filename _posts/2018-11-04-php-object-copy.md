---
layout: post-minimal
title: 'PHP 객체의 복제 특성'
date: 2018-11-04 00:00:00 +0900
categories:
- learn-n-think
tags:
- PHP
image: /images/2018-11-04-img-02.png
---

PHP 객체를 다른 변수에 할당(대입)하면, 객체 자체가 메모리 복제되어 새로운 변수에 할당되는 것이 아니라, 원본 객체가 담긴 메모리 번지만 참조됩니다(Like Pointer in C language).

- `$foo`와 `$foo2`은 `Foo` 클래스의 인스턴스가 담긴, 같은 메모리 번지를 가리킵니다.
- `$foo3`는 `$foo` 인스턴스로 부터 복제했으므로, 복제 시점의 `$foo`의 상태를 그대로 가져오지만, 서로 다른 객체입니다.
- `$foo4`는 `Foo` 클래스의 새로운 인스턴스이므로, 당연히 `$foo`, `$foo2`, `$foo3`와 다른 객체입니다.

[![](/images/2018-11-04-img-01.png)](/images/2018-11-04-img-01.png)

<!--more-->

[![](/images/2018-11-04-img-02.png)](/images/2018-11-04-img-02.png)

<div class="spacer">• • •</div>

`Carbon` 사용할 때 실수한 적이 있는데요. [불변 객체](/learn-n-think/immutable-object-and-immutalbe-entity/)가 아니므로, 주의해서 사용해야 합니다.
- `$now` 변수는 최초 `Carbon` 인스턴스 생성시에만 현재 시각의 의미를 담고 있습니다.
- `addDays()` 함수를 호출하는 순간, `$now`는 이미 현재 시각이 아니라 24시간 뒤의 의미를 가지게 됩니다.
- `$now` 변수에 `Carbon` 인스턴스 생성시에만 현재 시각이 담겨있다고 착각하고, 다른 변수에 담아서 사용하는 등의 실수를 조심해야 합니다.
- 가장 안전한 방법은 새로운 객체를 만드는 겁니다.

```bash
>>> $now = Carbon\Carbon::now();
=> Carbon\Carbon @1541322917 {#2894
     date: 2018-11-04 09:15:17.094112 UTC (+00:00),
   }
>>> $now->addDays(1);
=> Carbon\Carbon @1541409317 {#2894
     date: 2018-11-05 09:15:17.094112 UTC (+00:00),
   }
>>> $now2 = $now;
=> Carbon\Carbon @1541409317 {#2894
     date: 2018-11-05 09:15:17.094112 UTC (+00:00),
   }
```

#### References
- [php.net/manual/en/features.gc.refcounting-basics.php](//php.net/manual/en/features.gc.refcounting-basics.php)
- [php.net/manual/en/class.datetimeimmutable.php](//php.net/manual/en/class.datetimeimmutable.php)
- [laravel-news.com/mutable-and-immutable-date-time-php](//laravel-news.com/mutable-and-immutable-date-time-php)
