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
image: TBD
---

[지난 포스트](https://blog.appkr.dev/work-n-play/laravel-msa-example/)에 이어 모노리틱 서비스 구조에서 마이크로 서비스 구조로 전환할 때 사용자 인증을 어떻게 통합할지에 대한 내용을 이어갑니다.

전체 예제 코드는 [https://github.com/appkr/laravel-msa-example](https://github.com/appkr/laravel-msa-example)에 있습니다.

<!--more-->
<div class="spacer">• • •</div>
<!--div class="text-center"><small>마이크로 서비스 콤포넌트</small></div-->

## 4 구현

### 4-1 프로젝트 셋업

라라벨 프로젝트를 새로 만듭니다.
```bash
$ laravel new laravel-msa-example
```

예제 소스 코드에는 PHP7.3, fpm, Nginx, MySQL 등의 런타임 환경을 docker-compose로 구동하도록 했습니다.
```bash
$ tree docker
# docker
# ├── custom-php.ini      # xdebug, opcache 등 설정
# ├── docker-compose.yml
# ├── init.sql            # (최초 실행시 자동) 데이터베이스 생성
# └── laravel.conf        # Nginx 설정
```

최종 폴더 구조 및 구현 코드는 이렇습니다.
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
│ │ └── TokenProvider.php               # 토큰을 조회하기 위한 인터페이스
│ ├── Model                             # Example 도메인
│ │ └── Example.php
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

서비스를 구동하고 작동 여부를 검증합니다.
```bash
$ docker-composer -f docker/docker-compose.yml up -d
$ open http://localhost:8000
```

### 4-2 ExampleAPI 구현

Example 리소스 등록, 목록 조회 두 개의 API만 구현했습니다; 스키마 마이그레이션, 시더, 모델, 폼 리퀘스트, 서비스 레이어 등 기타 코드는 생략합니다.
{:.linenos}
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

### 4-3 HttpMiddleware 구현

현재는 엔드포인트만 알고 있다면 아무나 ExampleAPI를 사용할 수 있는 상태입니다. Authorization HTTP 헤더에 UAA에서 받은 토큰을 제출했을 때만, Example 리소스를 사용할 수 있도록 HttpMiddleware를 구현하고 적용해 보겠습니다.
{:.linenos}
```php
<?php // routes/api.php

Route::prefix('examples')->middleware(TokenAuthenticate::class)->group(function () { /* ... */ });
```

{:.linenos}
```php
<?php // app/Http/Middleware/TokenAuthenticate.php

namespace App\Http\Middleware;

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

- `26`: `TokenExtractor`는 `Request` 객체에서 JWT `access_token`을 추출하는 역할을 한다
- `28`: 클라이언트가 토큰을 제출하지 않았다면, 예외가 발생한다
- `30`: `TokenParser::parse` 메서드는 JWT 토큰을 받아서 파싱하고 `Token`모델을 반환하는 역할을 한다 
- `32`: 이상의 과정에서 `TokenException`이 발생할 수 있으며, 이때는 사용자에게 4xx 응답코드와 예외 메시지를 응답한다
- `40`: 이상의 과정이 순조롭게 진행되었다면, UserResolver 클로저를 등록한다; `43`줄을 보면 파싱된 토큰에서 `userName:UUIDInterface`을 조회하고 응답하는 것을 볼 수 있다

작동을 검증합니다.
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

### 4-4 TokenExtractor 구현
TBD

### 4-5 TokenParser 구현
TBD

### 4-6 TokenKeyProvider 구현
TBD

### 4-7 TokenProvider 구현
TBD

## 5 요약
