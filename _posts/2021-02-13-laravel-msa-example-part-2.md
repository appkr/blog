---
layout: post-minimal
title: '라라벨 마이크로서비스 예제 2부'
date: 2021-02-15 00:00:00 +0900
categories:
- work-n-play
tags:
- PHP
- Laravel
- MSA
- Oauth2
image: /images/2021-02-15-uml2.png
---

[지난 포스트](https://blog.appkr.dev/work-n-play/laravel-msa-example/)에 이어 모노리틱 서비스 구조에서 마이크로 서비스 구조로 전환할 때 사용자 인증을 어떻게 통합할지에 대한 내용을 이어갑니다.

![](/images/2021-02-15-uml2.svg)
<div class="text-center"><small>UAA 연동: HttpMiddleware를 이용한 Password 그랜트</small></div>

전체 예제 코드는 [https://github.com/appkr/laravel-msa-example](https://github.com/appkr/laravel-msa-example)에 있습니다.

<!--more-->
<div class="spacer">• • •</div>

<div class="panel panel-default" style="width:100%; margin: auto;">
  <div class="panel-body text-center">
     <a><i class="material-icons">info</i> 이하 본문에서 줄번호가 있는 코드 박스는 모바일 뷰에서 깨집니다. 데스크탑 브라우저를 권장합니다.</a>
  </div>
</div>

## 4 구현#1

### 4-1 프로젝트 셋업

라라벨 프로젝트를 새로 만듭니다.
```bash
$ laravel new laravel-msa-example
$ php artisan --version
# Laravel Framework 8.21.0
```

예제 소스 코드에는 PHP7.3, Nginx, MySQL 등의 런타임 환경을 docker-compose로 구동하도록 했습니다.
```bash
$ tree docker
# docker
# ├── custom-php.ini      # xdebug, opcache 등 설정
# ├── docker-compose.yml
# ├── init.sql            # (최초 실행시 자동) 데이터베이스 생성
# └── laravel.conf        # Nginx 설정
```

최종 폴더 구조는 이렇습니다.
```bash
.
├── app                                 # 라라벨 제공 폴더
├── hello-service                       # HelloAPI (Spring, non-laravel)
├── src
│ ├── Infra                             # 인프라 레이어
│ │ ├── ExternalApi
│ │ │ └── HelloApiClient.php            # HelloAPI
│ │ ├── JhipsterUaa                     # UAA 연동 코드
│ │ │ ├── CacheableTokenKeyProvider.php
│ │ │ ├── CacheableTokenProvider.php
│ │ │ ├── TokenKey.php
│ │ │ ├── TokenKeyResponse.php
│ │ │ ├── TokenResponse.php
│ │ │ ├── UaaTokenKeyProvider.php
│ │ │ └── UaaTokenProvider.php
│ │ ├── Token.php                       # 토큰 모델
│ │ ├── TokenException.php
│ │ ├── TokenExtractor.php              # Authorization 요청 헤더에서 토큰 추출하는 유틸 
│ │ ├── TokenKeyProvider.php            # 공개 키를 조회하기 위한 인터페이스
│ │ ├── TokenParser.php                 # 토큰 유효성 검증기
│ │ └── TokenProvider.php               # (OAuth2 서버로부터) 토큰을 얻기 위한 인터페이스
│ ├── Model
│ │ └── Example.php                     # Example 도메인
│ └── Service
│     ├── Dto
│     │ ├── ExampleDto.php
│     │ ├── ExampleList.php
│     │ ├── ExampleSearchParam.php
│     │ └── Page.php
│     ├── ExampleService.php
│     └── Mapper
│         └── ExampleMapper.php
└── tests
  ├── Infra
  │ ├── JWTTest.php
  │ ├── TokenExtractorTest.php
  │ ├── TokenKeyProviderTest.php
  │ ├── TokenParserTest.php
  │ └── TokenProviderTest.php
  └── Unit
      └── ExampleTest.php
```

전체 클러스터를 구동하고 작동 여부를 검증합니다.
```bash
$ docker-compose -f docker/docker-compose.yml up -d
$ open http://localhost:8000
```

UAA는 별도로 작동시키고 작동을 검증합니다.
```bash
# 최초 한번만 실행
$ wget https://github.com/appkr/msa-starter/raw/master/jhipster-uaa.zip \
  && unzip jhipster-uaa.zip 
  && cd jhipster-uaa

# 구동할 때마다 실행; 중지하려면 Ctrl + c
$ ./gradlew clean bootRun
$ curl -s http://localhost:9999/management/health
# { "status" : "UP" }
```

### 4-2 ExampleAPI

Example 리소스에 대해 등록, 목록 조회 두 개의 API만 구현했습니다; 스키마 마이그레이션, 시더, 모델, 폼 리퀘스트, 서비스 레이어 등 기타 코드는 생략합니다.
```php
<?php // routes/api.php

Route::prefix('examples')->group(function () {
    Route::post('/', [ExampleController::class, 'createExample']);
    Route::get('/', [ExampleController::class, 'listExamples']);
});
```

{:.linenos}
```php
<?php // app/Http/Controllers/ExampleController.php

namespace App\Http\Controllers;

use App\Http\Requests\CreateExampleRequest;
use App\Http\Requests\ListExampleRequest;
use Appkr\Service\ExampleService;
use Illuminate\Http\JsonResponse;

class ExampleController extends Controller
{
    private $service;

    public function __construct(ExampleService $exampleService)
    {
        $this->service = $exampleService;
    }

    public function createExample(CreateExampleRequest $request): JsonResponse
    {
        $dto = $this->service->createExample($request->toDto());

        return new JsonResponse($dto);
    }

    public function listExamples(ListExampleRequest $request): JsonResponse
    {
        return new JsonResponse($this->service->listExamples($request->toDto()));
    }
}
```

작동을 검증합니다.
```bash
$ curl -s -H 'Accept:application/json' http://localhost:8000/api/examples
```
```json
{
  "data": [
    {
      "id": 1,
      "title": "이문세 5집",
      "created_at": "2021-02-05T02:18:46.000000Z",
      "updated_at": "2021-02-05T02:18:46.000000Z",
      "created_by": "d593f9ef-d089-44fe-abe7-05c30219bb4c",
      "updated_by": "d593f9ef-d089-44fe-abe7-05c30219bb4c"
    }
  ],
  "page": {
    "size": 10,
    "totalElements": 1,
    "totalPages": 1,
    "number": 1
  }
}
```

## 5 구현#2 Password 그랜트

### 5-1 HttpMiddleware

현재는 엔드포인트만 알고 있다면 아무나 ExampleAPI를 사용할 수 있는 상태입니다. Authorization HTTP 헤더에 UAA에서 받은 토큰을 제출했을 때만, Example 리소스를 사용할 수 있도록 HttpMiddleware를 구현하고 적용해 보겠습니다.

{:.linenos}
```php
<?php // app/Http/Middleware/TokenAuthenticate.php

namespace AppP\Http\Middleware;

use App\Models\User;
use Appkr\Infra\TokenException;
use Appkr\Infra\TokenExtractor;
use Appkr\Infra\TokenParser;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Ramsey\Uuid\Uuid;

class TokenAuthenticate
{
    private $tokenParser;

    public function __construct(TokenParser $tokenParser)
    {
        $this->tokenParser = $tokenParser;
    }

    public function handle(Request $request, Closure $next)
    {
        try {
            $jwtString = TokenExtractor::extract($request);
            if (!$jwtString) {
                throw TokenException::tokenNotProvided();
            }
            $token = $this->tokenParser->parse($jwtString);
        } catch (TokenException $e) {
            return new JsonResponse(
                ['message' => $e->getMessage(),], 
                $e->getStatusCode()
            );
        } catch (\Exception $e) {
            return new JsonResponse(['message' => 'Unknown exception',], 400);
        }

        $request->setUserResolver(function () use ($token) {
            $user = new User();
            $user->name = ($token->getUserName() instanceof Uuid) 
                ? $token->getUserName() 
                : Uuid::fromString(Uuid::NIL);
            return $user;
        });

        return $next($request);
    }
}
```

- `26` line: `TokenExtractor`는 `Request` 객체에서 JWT `access_token`을 추출하는 역할을 한다
- `28` line: 클라이언트가 토큰을 제출하지 않았다면, 예외가 발생한다
- `30` line: `TokenParser::parse` 메서드는 JWT 토큰을 받아서 파싱하고 `Token`모델을 반환하는 역할을 한다 
- `32` line: 이상의 과정에서 `TokenException`이 발생할 수 있으며, 이때는 사용자에게 4xx 응답코드와 예외 메시지를 응답한다
- `40` line: 이상의 과정이 순조롭게 진행되었다면, UserResolver 클로저를 등록한다; `43`줄을 보면 파싱된 토큰에서 `userName: UUIDInterface` 클레임 값을 조회하고 사용하는 모습을 볼 수 있다

```php
<?php // routes/api.php

Route::prefix('examples')->middleware(TokenAuthenticate::class)->group(function () {
    // 생략 ...
});
```

작동을 검증합니다. 필요한 클래스들이 아직 없어서, 예외가 발생할텐데요. 예외를 발생시키지 않도록 최소한의 클래스와 메서드만 선언하고 테스트한다면 아래와 같은 결과를 얻을 수 있습니다.
```bash
$ curl -s -i -H 'Accept:application/json' http://localhost:8000/api/examples
```

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
Access-Control-Allow-Origin: *

{"message":"Token was not provided"}
```

### 5-2 TokenExtractor

`Request` 객체에서 JWT `access_token`을 추출하는 책임을 `TokenExtractor`에게 부여했습니다.

{:.linenos}
```php
<?php // src/Infra/TokenExtractor.php

namespace Appkr\Infra;

use Illuminate\Http\Request;

class TokenExtractor
{
    public static function extract(Request $request): ?string
    {
        if (!$request->hasHeader('authorization')) {
            return null;
        }

        $authHeader = $request->header('authorization');
        $jwtString = preg_replace('/bearer\s/i', '', $authHeader);

        return $jwtString;
    }
}
```

- `16` line: `authorization` 요청 헤더를 구한후, `bearer ` 스킴 문자열을 버리는 코드입니다

### 5-3 TokenParser

1부 3절에서 `firebase/php-jwt` 패키지를 설치해습니다. [공개키를 이용하여 JWT를 파싱하는 방법은 링크를 참고](https://github.com/firebase/php-jwt#example-with-rs256-openssl)합니다.

`TokenParser`는 원본 JWT 토큰을 받아서 파싱하고 `Token`모델을 반환하는 책임을 부여했습니다. [`Token` 모델은 예제 코드를 참고](https://github.com/appkr/laravel-msa-example/blob/master/src/Infra/Token.php)합니다

{:.linenos}
```php
<?php // src/Infra/TokenExtractor.php

namespace Appkr\Infra;

use Firebase\JWT\BeforeValidException;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\SignatureInvalidException;

class TokenParser
{
    private $tokenKeyProvider;

    public function __construct(TokenKeyProvider $tokenKeyProvider)
    {
        $this->tokenKeyProvider = $tokenKeyProvider;
    }

    public function parse(string $jwtString): Token
    {
        $token = new Token();
        try {
            $token = Token::fromTokenString(
                $jwtString, 
                $this->tokenKeyProvider->getKey()
            );
        } catch (SignatureInvalidException $e) {
            throw TokenException::invalidSignature($e);
        } catch (BeforeValidException $e) {
            throw TokenException::beforeValid($e);
        } catch (ExpiredException $e) {
            throw TokenException::expired($e);
        } catch (UnexpectedValueException $e) {
            throw TokenException::invalidToken($e);
        }

        return $token;
    }
}
```

- `15` line: `TokenKeyProvider` 주입한다
- `22` line: 토큰을 파싱 및 객체 생성 책임을 `Token` 클래스에 위임함; 원본 토큰 문자열과 `TokenKeyProvider`로 조회한 공개키를 인자로 전달한다
- `26-34` line: `firebase/php-jwt` 패키지의 `\Firebase\JWT\JWT::decode` 메서드에서 던진 예외를 `TokenException`으로 치환한다

예외|설명
---|---
`SignatureInvalidException`|공개 키가 유효하지 않을 때
`BeforeValidException`|`iat`(Issued at) 값보다 현재 시각이 과거일 때
`ExpiredException`|`exp`(Expiration time) 값보다 현재 시각이 미래일 때
`UnexpectedValueException`|토큰이 변조되었거나 유효하지 않을 때

현재까지의 구현을 클래스 다이어그램으로 살펴볼까요?

![](/images/2021-02-15-uml1.svg)
<div class="text-center"><small>구현 중간 점검</small></div>

### 5-4 TokenKeyProvider

`TokenKeyProvider`는 UAA 서버로부터 공개 키를 받아오는 역할을 합니다. 간결함을 위해 인터페이스 구현, `config/oauth2.php` 설정 등의 내용은 생략합니다. [`TokenKeyResponse` 모델도 생략하니 예제 코드를 참고](https://github.com/appkr/laravel-msa-example/blob/master/src/Infra/JhipsterUaa/TokenKeyResponse.php)바랍니다.

{:.linenos}
```php
<?php

namespace Appkr\Infra\JhipsterUaa;

use Appkr\Infra\TokenKeyProvider;
use GuzzleHttp\Client as GuzzleClient;
use GuzzleHttp\Psr7\Request;
use GuzzleHttp\Psr7\Response;
use Illuminate\Support\Arr;
use Psr\Http\Client\ClientExceptionInterface;

class UaaTokenKeyProvider implements TokenKeyProvider
{
    private $httpClient;
    private $config;

    public function __construct(GuzzleClient $httpClient, array $config)
    {
        $this->httpClient = $httpClient;
        $this->config = $config;
    }

    public function getKey(): string
    {
        return $this->getTokenKey()->getKey()->getValue();
    }

    public function getTokenKey(): TokenKeyResponse
    {
        $request = new Request('GET', Arr::get($this->config, 'token_key_path'));
        $response = new Response();
        try {
            $response = $this->httpClient->sendRequest($request);
        } catch (ClientExceptionInterface $e) {
        }

        return TokenKeyResponse::fromJsonString($response->getBody());
    }
}
```

- `30` line: == `new Request('GET', '/oauth/token_key'));`
- `33` line: UAA에 요청하고 받은 응답을 `$response` 변수에 담았다
- `37` line: 응답을 파싱하는 책임을 `TokenKeyResponse`에 위임했다

### 5-5 OAuth2ServiceProvider

런타임에 `TokenParser`, `TokenKeyProvider` 등의 객체를 정상적으로 주입하기 위해서는 서비스 프로바이더에 객체 조립 공식을 등록해야 합니다.

{:.linenos}
```php
<?php // app/Providers/OAuth2ServiceProvider.php

namespace App\Providers;

use Appkr\Infra\JhipsterUaa\UaaTokenKeyProvider;
use Appkr\Infra\TokenKeyProvider;
use Appkr\Infra\TokenParser;
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
    }
    
    private function registerTokenKeyProvider()
    {
        $this->app->bind(TokenKeyProvider::class, function (Application $app) {
            $config = $app->make(ConfigRepository::class)->get('oauth2.jhipster');
            $httpClient = new GuzzleClient([
                'base_uri' => Arr::get($config, 'base_uri'),
                'timeout' => 0,
            ]);
            return new UaaTokenKeyProvider($httpClient, $config);
        });
    }

    private function registerTokenParser()
    {
        $this->app->bind(TokenParser::class, function (Application $app) {
            return new TokenParser($app->make(TokenKeyProvider::class));
        });
    }   
}
```

- `30` line: `UaaTokenKeyProvider` 생성자가 요구하는 `GuzzleClient,` `$config: string[]`을 주입했다
- `37` line: `TokenParser` 생성자가 요구하는 `TokenKeyProvider`를 주입했다

뿐만아니라 `config/app.php`의 `providers` 배열에 방금 만든 서비스 프로바이더를 등록해줘야 합니다. 오랜만에 하는 라라벨 프로젝트라 이 부분을 놓치고 삽질을 했는데요, [슬랙에서 여러 분들께서 같이 봐주셔서 해결](https://modernpug.slack.com/archives/C0MGYSQ0L/p1612766800053200)했습니다.

작동하는지 검증해볼까요? UAA를 포함한 전체 클러스터가 작동하고 있다고 가정합니다.

```bash
$ RESPONSE=$(curl -s -X POST --data "username=user&password=user&grant_type=password&scope=openid" http://web_app:changeit@localhost:9999/oauth/token)
$ ACCESS_TOKEN=$(echo $RESPONSE | jq .access_token | xargs)
$ curl -s -i -H 'Accept:application/json' -H "Authorization: bearer ${ACCESS_TOKEN}" http://localhost:8000/api/examples
```

```http
HTTP/1.1 200 OK
Content-Type: application/json
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
Access-Control-Allow-Origin: *

{"data":[{"id":1,"title":"\uc774\ubb38\uc138 5\uc9d1","created_at":"2021-02-05T02:18:46.000000Z","updated_at":"2021-02-05T02:18:46.000000Z","created_by":"d593f9ef-d089-44fe-abe7-05c30219bb4c","updated_by":"d593f9ef-d089-44fe-abe7-05c30219bb4c"},"page":{"size":10,"totalElements":1,"totalPages":1,"number":1}}
```

### 5-5 CacheableTokenKeyProvider

현재까지 구현은 공개 키가 필요할 때마다 매번 UAA에 HTTP 요청을 해야 합니다. 한번 받은 공개 키는 24시간 동안 캐시에 저장하고 꺼내쓸 수 있도록 구현을 변경했습니다.

{:.linenos}
```php
<?php // src/Infra/JhipsterUaa/CacheableTokenKeyProvider.php

namespace Appkr\Infra\JhipsterUaa;

use Appkr\Infra\TokenKeyProvider;
use Illuminate\Contracts\Cache\Repository;

class CacheableTokenKeyProvider implements TokenKeyProvider
{
    const CACHE_KEY = 'oauth2.token_key';
    const CACHE_TTL_SECONDS = 60 * 60 * 24; // 24시간

    private $delegate;
    private $cacheRepository;

    public function __construct(
        TokenKeyProvider $delegate, 
        Repository $cacheRepository
    ) {
        $this->delegate = $delegate;
        $this->cacheRepository = $cacheRepository;
    }

    public function getKey(): string
    {
        return $this->getTokenKey()->getKey()->getValue();
    }

    public function getTokenKey(): TokenKeyResponse
    {
        $self = $this;
        return $this->cacheRepository->remember(
            self::CACHE_KEY, 
            self::CACHE_TTL_SECONDS, 
            function () use ($self) {
                return $self->delegate->getTokenKey();
            }
        );
    }
}
```

- `32` line: `$delegate: UaaTokenKeyProvider`로부터 받은 응답을 24시간 동안 `oauth2.token_key`라는 캐시 키의 값으로 저장한다 
- `36` line: `$delegate: UaaTokenKeyProvider`에게 위임한다; 데코레이터 패턴을 적용함

데코레이터가 정상 작동할 수 있도록 서비스 프로바이더에 객체 조립 공식을 변경 등록해야 합니다.

{:.linenos}
```php
<?php // app/Providers/OAuth2ServiceProvider.php

use Appkr\Infra\JhipsterUaa\CacheableTokenKeyProvider;
use Illuminate\Contracts\Cache\Repository as CacheRepository;
// 생략 ...

class OAuth2ServiceProvider extends ServiceProvider
{
    public function register()
    {
        // 생략 ...
    }
    
    private function registerTokenKeyProvider()
    {
        $this->app->bind(TokenKeyProvider::class, function (Application $app) {
            $config = $app->make(ConfigRepository::class)->get('oauth2.jhipster');
            $httpClient = new GuzzleClient([
                'base_uri' => Arr::get($config, 'base_uri'),
                'timeout' => 0,
            ]);
            $innerProvider = new UaaTokenKeyProvider($httpClient, $config);
            $cacheRepository = $app->make(CacheRepository::class);

            return new CacheableTokenKeyProvider($innerProvider, $cacheRepository);
        });
    }
}
```

- `25` line: `CacheableTokenKeyProvider` 생성자가 필요로하는 `TokenKeyProvider` 타입으로 기존에 사용하던 `UaaTokenKeyProvider`를 주입하고, 캐시 저장소를 사용할 수 있도록 `CacheRepository`를 주입했다

Password 그랜트가 완성됐습니다. 클래스 다이어그램을 살펴볼까요?

![](/images/2021-02-15-uml2.svg)
<div class="text-center"><small>UAA 연동: HttpMiddleware를 이용한 Password 그랜트</small></div>
<!--
## 6 구현#3 ClientCredentials 그랜트 

### 6-1 TokenProvider 구현
TBD

## 7 요약
-->
3부에서 이어집니다
