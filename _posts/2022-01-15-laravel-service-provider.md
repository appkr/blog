---
layout: post-minimal
title: '라라벨 서비스프로바이더에 바인드된 로직은 언제 실행될까요?'
date: 2022-01-15 00:00:00 +0900
categories:
- work-n-play
tags:
- PHP
- Laravel
image: /images/2022-01-15-laravel-service-provider.png
---

19~24 라인은 언제 실행될까요?

![](/images/2022-01-15-laravel-service-provider.png)

- 프레임워크 부트 시점에 실행될까요?
- 서비스 컨테이너에 `Closure`로 등록되고, 사용하는 시점에 실행될까요?

{:.linenos}
```php
<?php // routes/web.php

Route::get('injection/ok', function (\App\HttpBinService $service) {
    throw new RuntimeException("STOP");
    return $service->ok();
});

Route::get('resolve/ok', function () {
    throw new RuntimeException("STOP");
    $service = \Illuminate\Support\Facades\App::make(\App\HttpBinService::class);
    return $service->ok();
});
```

- 위 코드의 3 라인에서 예외를 던지기 전에, 서두에 언급한 19~24 라인이 실행될까요?
- 위 코드의 9 라인에서 예외를 던지기 전에, 서두에 언급한 19~24 라인이 실행될까요?

Guzzle Client를 품고 있는 서비스 객체를 필요한 시점에 생성하는 방법을 찾기 위한 실험입니다(lazy load). 저도 답을 찾고 있는 중입니다. 실험 프로젝트에서 각자 답을 찾아보세요.
https://github.com/appkr/laravel-service-provider-test
