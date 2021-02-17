---
layout: post-minimal
title: '라라벨 마이크로서비스 예제 3부'
date: 2021-02-17 00:00:00 +0900
categories:
- work-n-play
tags:
- PHP
- Laravel
- MSA
- Oauth2
image: /images/2021-02-17-uaa.png
---

모노리틱 서비스 구조에서 마이크로 서비스 구조로 전환할 때 사용자 인증을 어떻게 통합할지에 대한 내용을 계속 이어갑니다. 이번 포스트에서는 아래 그림처럼 한 마이크로 서비스가 다른 마이크로 서비스를 호출하는 경우를 살펴볼 겁니다.

![](/images/2021-02-17-uaa.svg)
<div class="text-center"><small>UAA 연동 시나리오</small></div>

전체 예제 코드는 [https://github.com/appkr/laravel-msa-example](https://github.com/appkr/laravel-msa-example)에 있습니다.

<!--more-->
<div class="spacer">• • •</div>

<div class="panel panel-default" style="width:100%; margin: auto;">
  <div class="panel-body text-center">
     <a><i class="material-icons">info</i> 이하 본문에서 줄번호가 있는 코드 박스는 모바일 뷰에서 깨집니다. 데스크탑 브라우저를 권장합니다.</a>
  </div>
</div>

## 6 구현#3 ClientCredentials 그랜트 

`Client`가 `HelloAPI`를 직접 사용할 수 있습니다. 또는 라라벨 서비스의 `GuzzleClient`가 `HelloAPI`를 사용할 수도 있습니다. 이 예제에서는 후자만 다루긴합니다만, 여튼 `ExampleAPI` 뿐만아니라 `HelloAPI`도 보호해야 합니다. 이때 서버간 통신을 하게되는데, 사용할 그랜트가 `ClientCredentials`인거죠.

### 6-1 Hello Proxy

Hello 리소스는 라라벨 서비스의 도메인이 아닙니다. `Client`가 직접 접근할 수 있음에도 불구하고, 편의를 위해 라라벨 서비스가 게이트웨이 역할을 대신해주는 거죠. 이런 이유로 프록시라는 용어를 썼습니다. 

```php
<?php // routes/api.php

Route::prefix('hello')->middleware(TokenAuthenticate::class)->group(function () {
    Route::get('/', [HelloController::class, 'hello']);
});
```

```php
<?php // app/Http/Controllers/HelloController.php

namespace App\Http\Controllers;

use Appkr\Infra\ExternalApi\HelloApiClient;
use Illuminate\Http\JsonResponse;

class HelloController extends Controller
{
    private $helloApiClient;

    public function __construct(HelloApiClient $helloApiClient)
    {
        $this->helloApiClient = $helloApiClient;
    }

    public function hello(): JsonResponse
    {
        return new JsonResponse($this->helloApiClient->hello());
    }
}
```

{:.linenos}
```php
<?php // src/Infra/ExternalApi/HelloApiClient.php

namespace Appkr\Infra\ExternalApi;

use Appkr\Infra\TokenProvider;
use GuzzleHttp\Client as GuzzleClient;
use GuzzleHttp\Psr7\Request;
use GuzzleHttp\Psr7\Response;
use Psr\Http\Client\ClientExceptionInterface;

class HelloApiClient
{
    private $httpClient;
    private $tokenProvider;

    public function __construct(
        GuzzleClient $httpClient, 
        TokenProvider $tokenProvider
    ) {
        $this->httpClient = $httpClient;
        $this->tokenProvider = $tokenProvider;
    }

    public function hello(): string
    {
        $request = new Request('GET', 'http://localhost:8080/hello', [
            'Authorization' => "bearer {$this->tokenProvider->getToken()}",
        ]);
        $response = new Response();
        try {
            $response = $this->httpClient->sendRequest($request);
        } catch (ClientExceptionInterface $e) {
        }

        return $response->getBody();
    }
}
```

- `17` line: 스프링 서비스(==`HelloAPI`)와 통신하기 위해 `GuzzleClient`를 주입 받는다
- `18` line: Hello 리소스를 요청할 때 스프링 서비스에 제출할 `access_token`을 얻기 위해 `TokenProvider`를 주입받는다
- `27` line: Authorization 요청 헤더를 셋팅한다
- `31` line: HelloAPI를 호출한다

### 6-2 UaaTokenProvider

간결함을 위해 `TokenProvider` 인터페이스는 생략합니다. [TokenResponse도 생략하니 예제 코드를 참고](https://github.com/appkr/laravel-msa-example/blob/master/src/Infra/JhipsterUaa/TokenResponse.php)바랍니다.

{:.linenos}
```php
<?php // src/Infra/JhipsterUaa/UaaTokenProvider.php

namespace Appkr\Infra\JhipsterUaa;

use Appkr\Infra\TokenKeyProvider;
use Appkr\Infra\TokenProvider;
use GuzzleHttp\Client as GuzzleClient;
use GuzzleHttp\Psr7\Query;
use GuzzleHttp\Psr7\Request;
use GuzzleHttp\Psr7\Response;
use Illuminate\Support\Arr;
use Psr\Http\Client\ClientExceptionInterface;

class UaaTokenProvider implements TokenProvider
{
    private $httpClient;
    private $config;
    private $tokenKeyProvider;

    public function __construct(
        GuzzleClient $httpClient, 
        array $config, 
        TokenKeyProvider $tokenKeyProvider
    ) {
        $this->httpClient = $httpClient;
        $this->config = $config;
        $this->tokenKeyProvider = $tokenKeyProvider;
    }

    public function getToken(): string
    {
        return $this->getTokenResponse()->getAccessToken()->getTokenString();
    }

    public function getTokenResponse(): TokenResponse
    {
        $request = new Request('POST', Arr::get($this->config, 'access_token_path'), [
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Authorization' => "basic {$this->getBasicAuthHeader()}"
        ], Query::build([
            'grant_type' => 'client_credentials',
        ]));
        $response = new Response();
        try {
            $response = $this->httpClient->sendRequest($request);
        } catch (ClientExceptionInterface $e) {
        }

        return TokenResponse::fromJsonString(
            $response->getBody(), 
            $this->tokenKeyProvider->getKey()
        );
    }

    private function getBasicAuthHeader(): string
    {
        $clientId = Arr::get($this->config, 'client_id');
        $clientSecret = Arr::get($this->config, 'client_secret');
        return base64_encode("{$clientId}:{$clientSecret}");
    }
}
```

- `23` line: UAA 서버에서 받은 토큰을 파싱하기 위해 `TokenKeyProvider`를 주입 받는다
- `45` line: UAA 서버에 토큰을 요청한다
- `49-52` line: UAA 서버에서 받은 응답 파싱을 `TokenResponse` 모델에게 위임한다
- `55-60` line: basic 인증 스킴으로 클라이언트 정보를 제출한다(이렇게 제출할 수도 있다 `http://internal:internal@localhost:9999/oauth/token`). `base64_encode("internal:internal")`의 결과값은 `aW50ZXJuYWw6aW50ZXJuYWw=`이다

서비스 프로바이더도 수정해야 합니다.

```php
<?php // app/Providers/OAuth2ServiceProvider.php

namespace App\Providers;

use Appkr\Infra\JhipsterUaa\UaaTokenProvider;
use Appkr\Infra\TokenProvider;
use GuzzleHttp\Client as GuzzleClient;
use Illuminate\Contracts\Config\Repository as ConfigRepository;
use Illuminate\Contracts\Foundation\Application;
use Illuminate\Support\Arr;
use Illuminate\Support\ServiceProvider;

class OAuth2ServiceProvider extends ServiceProvider
{
    public function register()
    {
        $this->registerTokenKeyProvider();
        $this->registerTokenParser();
        $this->registerTokenProvider();
    }

    private function registerTokenKeyProvider() { /* 생략 */ }

    private function registerTokenParser() { /* 생략 */ }

    private function registerTokenProvider()
    {
        $this->app->bind(TokenProvider::class, function (Application $app) {
            $config = $app->make(ConfigRepository::class)->get('oauth2.jhipster');
            $httpClient = new GuzzleClient([
                'base_uri' => Arr::get($config, 'base_uri'),
                'timeout' => 0,
            ]);
            $tokenKeyProvider = $app->make(TokenKeyProvider::class);
            
            return new UaaTokenProvider($httpClient, $config, $tokenKeyProvider);
        });
    }
}
```

현재까지의 구현을 클래스 다이어그램으로 살펴볼까요?

![](/images/2021-02-17-uml1.svg)
<div class="text-center"><small>구현 중간 점검</small></div>

### 6-3 CacheableTokenProvider

HelloAPI를 요청할 때마다 `ClientCredentials` 그랜트로 토큰을 얻는 것은 네트워크 IO가 매번 발생해서 비효율적입니다. 2부에서 `TokenKeyProvider`에서 얻은 공개키를 캐시하고 사용했듯이, `TokenProvider`도 똑같이 구현했습니다. 다만 2부에서 24시간 동안 캐시했다면, 여기서는 `access_token`의 `exp` 클레임까지만 캐시를 유지하도록 구현합니다.

{:.linenos}
```php
<?php

namespace Appkr\Infra\JhipsterUaa;

use Appkr\Infra\TokenProvider;
use Carbon\Carbon;
use Illuminate\Contracts\Cache\Repository;

class CacheableTokenProvider implements TokenProvider
{
    const CACHE_KEY = 'oauth2.token';

    private $delegate;
    private $cacheRepository;

    public function __construct(TokenProvider $delegate, Repository $cacheRepository)
    {
        $this->delegate = $delegate;
        $this->cacheRepository = $cacheRepository;
    }

    public function getToken(): string
    {
        return $this->getTokenResponse()->getAccessToken()->getTokenString();
    }

    public function getTokenResponse(): TokenResponse
    {
        $self = $this;
        return $this->cacheRepository->rememberForever(
            self::CACHE_KEY, 
            function () use ($self) {
                return $self->delegate->getTokenResponse();
            }
        );
    }
}
```

이번에도 서비스 프로바이더는 수정해야 합니다만, 간결함을 위해 생략했으니, [예제 코드를 참고](https://github.com/appkr/laravel-msa-example/blob/master/app/Providers/OAuth2ServiceProvider.php)바랍니다.

## 7 정리

- 마이크로 서비스를 구성할 때 가장 먼저 고려해야할 모듈은 사용자 인증(`UAA`)이다
- `Client`는 `UAA`에서 얻은 토큰을 제출함으로써 마이크로 서비스의 보호된 리소스를 사용할 수 있다
- 마이크로 서비스는 클라이언트가 제출한 토큰을 검증하여 유효할 때만 요청을 처리한다
- JWT를 토큰으로 사용하면 여러 가지 면에서 편리하다
- 마이크로 서비스끼리 통신하는 경우에도 `UAA`로 부터 얻은 토큰을 제출해야 하며, 토큰의 유효성을 검증하고, 유효할 때만 요청을 처리한다

끝.
