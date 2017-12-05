---
layout: post-minimal
title: '라라벨 엘로퀀트 모델 이벤트 고찰'
date: 2017-10-22 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- Laravel
---

라라벨 엘로퀀트에서 발생하는 모델 이벤트를 실험한 결과 입니다. [선점 잠금과 비선점 잠금 실험을 위한 프로젝트](https://github.com/appkr/db-lock-poc)에 이벤트 리스너를 등록하고 엘로퀀트 모델을 DB에 저장하고, 변경한 후 DB에 저장하고, 삭제할 때 어떤 이벤트가 발생하는지 살펴 봤습니다.

이벤트를 잡기 위한 리스너 클로저는 아래와 같습니다.

```php
<?php // https://github.com/appkr/db-lock-poc/blob/master/app/Providers/EventServiceProvider.php

class EventServiceProvider extends ServiceProvider
{
    public function boot()
    {
        Event::listen('eloquent.*', function ($event) {
            Log::info($event);
        });
    }
}
```

[관찰자(Observer) 패턴](https://github.com/appkr/pattern/tree/master/Behavioral/Observer2)은 관찰의 대상이 되는 타입에, 대상을 관찰하려는 타입을 등록해두고, 특정 사건(Event)이 발생하면 등록된 관찰자의 함수를 호출하는 겁니다. 쉽게 말하면, "밥 다되면 불러줘~"라고 미리 말해두고, 밥이 다 되면 알려주는 거죠. 

"관찰자를 등록하고 사건이 발생하면 등록된 관찰자들에게 알려준다"는 큰 개념은 같지만, 라라벨의 엘로퀀트 모델은 `$observables` 변수에 객체가 아닌 문자열로 관찰자를 등록합니다. 그리고 엘로퀀트에서는 `save()`와 같은 퍼블릭 함수가 작동할 때, 자신의 `fireModelEvent('created')` 함수를 호출하고, 이 함수가 다시 관찰자에서 이벤트와 같은 이름을 가진 함수, 예를 들어 `created($this)`를 호출하는 식으로 작동합니다.

<!--more-->
<div class="spacer">• • •</div>

## 1. Insert

`$model->update()`, `$model->push()`, `$model->touch()` 등의 API도 결국에는 `save()` 함수를 거치게 됩니다. `save()` 함수는 `saving` 이벤트를 던진 후, 다시 Insert를 해야할지 Update를 해야할지 판단하고, `performInsert()` 또는 `performUpdate()` 함수를 선택적으로 호출합니다. 분기된 함수 안에서 다시 `creating`, `created`, `..` 등의 이벤트를 던집니다. 분기된 함수 오퍼레이션이 끝나면 `save()` 함수는 `saved` 이벤트를 던지고 수명을 다합니다.   

따라서, `saving` -> `creating` -> `created` -> `saved` 순서로 이벤트가 발생합니다. 

```bash
# https://github.com/appkr/db-lock-poc/blob/master/app/Http/Controllers/ProductController.php#L42

[...] local.INFO: eloquent.booting: Myshop\Domain\Model\User
[...] local.INFO: eloquent.booted: Myshop\Domain\Model\User
[...] local.INFO: select * from `users` where `email` = ? limit 1 ["admin@foo.com"]
[...] local.INFO: eloquent.booting: Myshop\Domain\Model\Product
[...] local.INFO: eloquent.booted: Myshop\Domain\Model\Product
[...] local.INFO: eloquent.saving: Myshop\Domain\Model\Product
[...] local.INFO: eloquent.creating: Myshop\Domain\Model\Product
[...] local.INFO: insert into `products` (`title`, `stock`, `price`, `description`, `updated_at`, `created_at`) values (?, ?, ?, ?, ?, ?) ["TEST TITLE",10,1000,"TEST DESCRIPTION","2017-10-22 10:21:53","2017-10-22 10:21:53"]
[...] local.INFO: eloquent.created: Myshop\Domain\Model\Product
[...] local.INFO: eloquent.saved: Myshop\Domain\Model\Product
[...] local.INFO: select * from `products` where `id` = ? limit 1 [12]
[...] local.INFO: eloquent.booting: Myshop\Domain\Model\Review
[...] local.INFO: eloquent.booted: Myshop\Domain\Model\Review
[...] local.INFO: select * from `reviews` where `reviews`.`product_id` in (?) and `reviews`.`deleted_at` is null [12]
```

## 2. Update

`saving` -> `updating` -> `updated` -> `saved` 순.

```bash
# https://github.com/appkr/db-lock-poc/blob/master/app/Http/Controllers/ProductController.php#L59

[...] local.INFO: eloquent.booting: Myshop\Domain\Model\User
[...] local.INFO: eloquent.booted: Myshop\Domain\Model\User
[...] local.INFO: select * from `users` where `email` = ? limit 1 ["admin@foo.com"]
[...] local.INFO: eloquent.booting: Myshop\Domain\Model\Product
[...] local.INFO: eloquent.booted: Myshop\Domain\Model\Product
[...] local.INFO: select * from `products` where `products`.`id` = ? and `products`.`deleted_at` is null limit 1 for update [12]
[...] local.INFO: eloquent.booting: Myshop\Domain\Model\Review
[...] local.INFO: eloquent.booted: Myshop\Domain\Model\Review
[...] local.INFO: select * from `reviews` where `reviews`.`product_id` in (?) and `reviews`.`deleted_at` is null [12]
[...] local.INFO: select * from `products` where `id` = ? limit 1 [12]
[...] local.INFO: select * from `reviews` where `reviews`.`product_id` in (?) and `reviews`.`deleted_at` is null [12]
[...] local.INFO: eloquent.saving: Myshop\Domain\Model\Product
[...] local.INFO: eloquent.updating: Myshop\Domain\Model\Product
[...] local.INFO: update `products` set `title` = ?, `description` = ?, `version` = ?, `updated_at` = ? where `id` = ? ["새 상품 (상품명 수정됨)","...",2,"...",12]
[...] local.INFO: eloquent.updated: Myshop\Domain\Model\Product
[...] local.INFO: eloquent.saved: Myshop\Domain\Model\Product
[...] local.INFO: select * from `products` where `id` = ? limit 1 [12]
[...] local.INFO: select * from `reviews` where `reviews`.`product_id` in (?) and `reviews`.`deleted_at` is null [12]
```

## 3. Delete

`deleting` -> `deleted` 순.

```bash
# https://github.com/appkr/db-lock-poc/blob/master/app/Http/Controllers/ProductController.php#L96

[...] local.INFO: eloquent.booting: Myshop\Domain\Model\Product
[...] local.INFO: eloquent.booted: Myshop\Domain\Model\Product
[...] local.INFO: select * from `products` where `id` = ? and `products`.`deleted_at` is null limit 1 ["12"]
[...] local.INFO: eloquent.booting: Myshop\Domain\Model\Review
[...] local.INFO: eloquent.booted: Myshop\Domain\Model\Review
[...] local.INFO: select * from `reviews` where `reviews`.`product_id` in (?) and `reviews`.`deleted_at` is null [12]
[...] local.INFO: eloquent.booting: Myshop\Domain\Model\User
[...] local.INFO: eloquent.booted: Myshop\Domain\Model\User
[...] local.INFO: select * from `users` where `email` = ? limit 1 ["admin@foo.com"]
[...] local.INFO: select * from `reviews` where 0 = 1 and `reviews`.`deleted_at` is null
[...] local.INFO: eloquent.deleting: Myshop\Domain\Model\Product
[...] local.INFO: update `products` set `deleted_at` = ?, `updated_at` = ? where `id` = ? ["...","...",12]
[...] local.INFO: eloquent.deleted: Myshop\Domain\Model\Product
```
