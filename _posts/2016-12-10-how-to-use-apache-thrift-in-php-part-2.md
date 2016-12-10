---
layout: post-minimal
title: 'RPC - Apache Thrift 입문 2부' 
date: 2016-12-10 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- RPC
- "Apache Thrift"
- PHP
image: https://rofildex86.files.wordpress.com/2015/02/clack-middleware-2.png
---

앞서 [1부](/work-n-play/how-to-use-apache-thrift-in-php-part-1/)에서는 다음 내용을 다루었다.

-   RPC 시스템에 대한 이해와 여러 가지 RPC 프레임워크의 특징
-   Thrift IDL(Interface Definition Language)를 이용해서 API 규격 만드는 방법
-   API 규격을 다양한 언어로 컴파일하고 라이브러리화 하는 방법
-   API 서버 프로젝트에 라이브러리를 플러그인하고 API 규격에 맞춘 서비스를 개발하는 방법
-   API 클라이언트가 서버에 접속하여 Thrift 프로토콜로 통신하는 방법

1부에서 언급했다시피, **Thrift 요청과 응답은 Thrift 프로토콜 안쪽에서 (역)직렬화** 된다. 1부의 내용만으로는 디버깅이 어려워 서비스를 개발하기가 수월치 않다. 그래서 2부에서는 다음 내용을 다룬다. 

-   **Thrift 프로토콜 안쪽에서 작동하는 미들웨어**를 만들어서 Thrift 요청을 핸들링하고 그 과정에서 발생한 예외를 잡고 소비하는 방법
-   **책임 연쇄(Chain of Responsibility) 패턴**의 이해
-   통합 테스트(Integration Test) 구현

<!--more-->
<div class="spacer">• • •</div>

## 1. 통합 테스트 작성

Thrift 클라이언트가 IDL에서 정의한 API를 호출하는 경우를 상정하고, Outside-In으로 설명하는 것이 더 쉬울 것 같다. 아래 통합 테스트는 Thrift 클라이언트를 만들고 같은 프로젝트 디렉터리에 있는 API 서버를 호출한다. 

```php
<?php // tests/ThriftClientTest.php

use App\Post as EloquentPost;
use Appkr\Thrift\Post\Post as ThriftPost;
use Appkr\Thrift\Post\PostServiceClient;
use Appkr\Thrift\Post\QueryFilter;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Thrift\Protocol\TJSONProtocol;
use Thrift\Transport\THttpClient;

/**
 * @property \Appkr\Thrift\Post\PostServiceClient client
 */
class ThriftClientTest extends TestCase
{
    // 테스트 중에 생성된 데이터를 테스트가 끝나면 롤백해주는 라라벨의 내장 Trait다.  
    use DatabaseTransactions;

    public function setUp()
    {
        parent::setUp();

        $transport = new THttpClient(
            'localhost',
            '8000',
            'api/posts'
        );

        $protocol = new TJSONProtocol($transport);

        $this->client = new PostServiceClient($protocol);

        // 테스트를 위해 레코드 20개를 만든다.
        // testAll, testFind, testStore 등 테스트 메서드가 세 개이므로 총 세 번 호출된다.
        factory(EloquentPost::class, 20)->create();
    }

    public function testAll()
    {
        $queryFilter = new QueryFilter([
            'keyword' => 'Lorem',
            'sortBy' => 'id',
            'sortDirection' => 'desc'
        ]);

        $response = $this->client->all($queryFilter, 0, 10);

        print_r($response);

        if (count($response)) {
            // Lorem이란 텍스트를 가진 레코드가 없을 수도 있어, if 절에 넣었다.
            // 응답으로 받은 컬렉션의 요소가 ThriftPost 객체인지 검사한다(IDL에 그렇게 정의했음).
            $this->assertInstanceOf(ThriftPost::class, $response[0]);
        }
    }

    public function testFind()
    {
        $response = $this->client->find(1);

        print_r($response);

        $this->assertInstanceOf(ThriftPost::class, $response);
        $this->assertEquals($response->id, 1);
    }

    public function testStore()
    {
        $response = $this->client->store(
            'foo',
            'Lorem content'
        );

        print_r($response);

        $this->assertInstanceOf(ThriftPost::class, $response);
        $this->assertEquals($response->title, 'foo');
    }
}
```

## 2. 서비스 수정

1부에서는 클라이언트가 넘긴 `QueryFilter`를 이용해서 검색을 수행하거나, 정렬하는 로직을 구현하지 않았다. 본 포스트의 주제와는 크게 관련은 없지만, Thrift IDL에서 정의한 `struct`를 사용하는 법을 엿볼 수 있다. 

```php
<?php // app/Services/PostService.php

namespace App\Services;

use App\Post as EloquentPost;
use Appkr\Thrift\Post\Post as ThriftPost;
use Appkr\Thrift\Post\PostField;
use Appkr\Thrift\Post\PostServiceIf;
use Appkr\Thrift\Post\QueryFilter;

class PostService implements PostServiceIf
{
    public function all(QueryFilter $qf, $offset, $limit)
    {
        $builder = new EloquentPost;

        // $qf 변수는 QueryFilter 객체다.
        // $qf 변수는 라라벨에서 쓰던 Request 객체라고 생각하면 되는데,
        // Thrift에서는 클라이언트가 IDL에 정의한 객체(struct)를 넘기므로
        // 서버에서 $qf->keyword처럼 객체 액세스를 할 수 있다.
        if ($qf->keyword) {
            // 고급 DB를 사용한다면 Full text BOOLEAN MATCH를 사용할 수 있을 것이다.
            // 여기서는 간략히 QueryFilter를 사용하는 컨셉만 소개한다.
            $builder->where('title', 'like', "%{$qf->keyword}%");
        }

        $posts = $builder->orderBy($qf->sortBy, $qf->sortDirection)
                         ->offset($offset)
                         ->limit($limit)
                         ->get();

        return $posts->map(function ($post) {
            return new ThriftPost($post->toArray());
        })->all();
    }

    public function find($id)
    {
        // 1부와 동일 ...
    }

    public function store($title, $content)
    {
        // 1부와 동일 ...
    }
}
```

## 3. 미들웨어와 책임 연쇄 패턴 

미들웨어란 아케이드 게임에서 최종 보스를 만나기 위해서 상대해야 하는 중간 보스, 또는 최종 결재를 받기 위해 거쳐야 하는 중간 결재선에 비유할 수 있다. 중간 과정을 통과하지 못하면 최종 목적지에 도달하지 못한다. 이 프로젝트에서는 `PostService`에 도달하기 위해서 거쳐야 하는 중간 과정으로 이해하면 된다. 다음 그림을 참고하자.
   
[![Http Middleware](https://rofildex86.files.wordpress.com/2015/02/clack-middleware-2.png)](https://rofildex86.files.wordpress.com/2015/02/clack-middleware-2.png)

 <small>그림 출처: [Laravel/5 Series 4: Middleware](https://rofildex86.wordpress.com/2015/02/20/laravel5-series-4-middleware/)</small>
 
미들웨어를 구현하는데 적합한 패턴은 책임 연쇄 패턴(Chain of Responsibility)이다.

### 3.1. 서비스에 미들웨어 적용하기

글로 설명하기 너무 힘들다, 즉 설명할 수 없다는 것은 필자도 잘 모른다는 의미이기도 하다ㅜㅜ. 코드에 인라인 주석을 참고한다.

```php
<?php // app/Http/Controllers/PostsController

namespace App\Http\Controllers;

use App\Services\PostService;
use App\Thrift\BarMiddleware;
use App\Thrift\FooMiddleware;
use App\Thrift\ThriftResponse;
use App\Thrift\ThriftServiceHandler;
use Appkr\Thrift\Post\PostServiceProcessor;
use Illuminate\Http\Request;

class PostsController extends Controller
{
    public function handle(Request $request, $format = 'json')
    {
        // 그림에서 본 것처럼 Thrift 요청은 바깥쪽에 있는 FooMiddleware를 먼저 거치게 된다.
        $middleware = new FooMiddleware(
            new BarMiddleware
        );

        $service = new PostService();
        // PostService를 앞서 만든 미들웨어로 싸서 ThriftServiceHandler를 만들었다. 
        $handler = new ThriftServiceHandler($service, $middleware);
        // 이제 Thrift 컴파일러가 만들어준 프로세서에 미들웨어로 여러겹 포장한 서비스를 넘겨서 처리를 위임한다.
        $processor = new PostServiceProcessor($handler);

        return ThriftResponse::make($request, $processor, $format);
    }
}
```

### 3.2. 서비스 핸들러 만들기

서비스를 미들웨어로 감싸 줄 `ThriftServiceHandler`를 만들 차례다. 핸들러의 개념을 이해하기 어려운데 미들웨어가 있으면 미들웨어를 구동시키고, 없으면 서비스를 바로 호출해 주는 녀석이다. 진짜 서비스가 아니지만 자신이 서비스인 양 행세해서, 프로세서가 서비스로 간주하고 호출하는 녀석이다.

```php
<?php // app/Thrift/ThriftServiceHandler.php

namespace App\Thrift;

/**
 * @property service
 * @property \App\Thrift\ThriftMiddleware|null middleware
 */
class ThriftServiceHandler
{
    public function __construct($service, ThriftMiddleware $middleware = null)
    {
        $this->service = $service;
        $this->middleware = $middleware;
    }
    
    // 가령 클라이언트가 all API를 호출했다면, PostServiceProcessor가 PostService::all()
    // 메서드를 호출할 때 클라이언트가 제시한 인자인 QueryParameter 객체와, offset 0, limit 10을
    // 넘겨준다. 그런데, 앞 절에서 PostServiceProcessor에 넘겨 준 것은 PostService가 아니라
    // 이 서비스를 미들웨어로 몇 꺼풀 싸 놓은 ThriftServiceHandler를 넘겼다.
    // ThriftServiceHandler에는 all 메서드가 없다. 일치하는 메서드가 없으므로 __call 메서드가 호출된다. 
    public function __call($method, $arguments)
    {
        // 생성자를 통해 초기화한 미들웨어가 있으면 이 로직을 수행한다.
        if ($this->middleware) {
            // 등록된 미들웨어의 handle 메서드를 호출한다. 1절의 테스트를 가정하면,
            // 이 때 PostService 객체, all, [QueryFilter 객체, 0, 10] 등을 인자로 넘기게 된다.
            return $this->middleware->handle($this->service, $method, $arguments);
        }

        // 등록된 미들웨어가 없으면 클라이언트가 전달한 인자로 PostService::all 메서드를 바로 호출한다. 
        return call_user_func_array([$this->service, $method], $arguments);
    }
}
```

### 3.3. 미들웨어 만들기

`PostService`를 감쌌던 `FooMiddleware`를 만들어 보자(`BarMiddleware`는 생략한다). 역시 인라인으로 주석을 달았다.

```php
<?php // app/Thrift/FooMiddleware.php

namespace App\Thrift;

use Appkr\Thrift\Errors\ErrorCode;
use Appkr\Thrift\Errors\SystemException;
use Appkr\Thrift\Errors\UserException;
use Log;

class FooMiddleware extends ThriftMiddleware
{
    // ThriftServiceHandler::__call에서 이 메서드를 호출했다. 
    public function handle($service, $method, $arguments)
    {
        try {
            // 컨셉만 보여 주기 위해서 로그에 메시지를 쓰는 것으로 대신한다.
            Log::info('handling thrift request', [func_get_args(), __METHOD__]);

            // 책임 연쇄 패턴에서 가장 중요한 부분이다. next 메서드는 다음 절에서 살펴본다.
            // 우리 예제에서 next는 BarMiddleware다.
            return $this->next($service, $method, $arguments);
        } catch (SystemException $e) {
            // 추가적인 예외 처리를 여기서 한다.
            // SystemException은 Thrift IDL에 정의한 struct므로 클라이언트와 연결된 프로토콜을 통해
            // 안전하게 전달된다. 클라이언트 측에서도 SystemException으로 역 직렬화되어 바로 사용할 수 있다.
            throw $e;
        } catch (UserException $e) {
            throw $e;
        } catch (\Exception $e) {
            // SystemException 및 UserException을 제외한 라라벨의 일반적인 예외를 핸들링한다.
            // 이 예제에서는 로그에 디버그 메시지를 쓴다. Thrift가 없는 라라벨 프로젝트라면
            // app/Exceptions/Handler.php의 전역 예외 처리기가 예외를 소비했을 것이다.
            // 라라벨의 Handler::report 메서드를 대신하는 역할을 한다.
            Log::debug(sprintf(
                "%s \n\n%s \n%s:%d \n\n%s",
                get_class($e),
                $e->getMessage(),
                $e->getFile(),
                $e->getLine(),
                $e->getTraceAsString()
            ));

            // Thrift 클라이언트가 이해할 수 있는 SystemException으로 변경하여 클라이언트에게 돌려준다.
            // 라라벨의 Handler::render 메서드를 대신하는 역할을 한다.
            throw new SystemException([
                'code' => ErrorCode::INTERNAL_SERVER_ERROR,
                'message' => $e->getMessage()
            ]);
        }
    }
}
```

### 3.4. 추상 미들웨어

앞 절의 인라인 주석에서 책임 연쇄 패턴에 가장 중요한 메서드가 `next()`라고 말한 바 있다. 이 절에서는 이 `next()` 메서드의 작동 원리를 파헤쳐본다.  

```php
<?php // app/Thrift/ThriftMiddleware.php

namespace App\Thrift;

abstract class ThriftMiddleware
{
    protected $successor = null;

    public function __construct(ThriftMiddleware $successor = null)
    {
        // 3.1.절에서 new FooMiddleware(new BarMiddleware)처럼
        // 미들웨어 생성자에 다른 미들웨어를 넣은 것을 기억할 것이다. 바로 이 부분이다.
        // $successor는 이번 미들웨어를 통과하고 나면, 그 다음에 통과해야 할 미들웨어다.
        // 이제 FooMiddleware의 $successor는 BarMiddleware다.
        $this->successor = $successor;
    }

    abstract public function handle($service, $method, $arguments);

    public function next($service, $method, $arguments)
    {
        if ($this->successor) {
            // 구체 미들웨어 클래스의 handle 메서드에서 항상 next 메서드를 호출했던 것을 기억할 것이다.
            // FooMiddleware는 BarMiddleware라는 $successor를 가지고 있으므로
            // BarMiddlware::handle 메서드가 호출될 것이다.
            return $this->successor->handle($service, $method, $arguments);
        }

        // 반면 BarMiddlware는 $succesor가 없으므로 아래 구문이 호출된다.
        // 이 예제에서는 PostService::all 메서드가 호출되는 것이다.
        return call_user_func_array([$service, $method], $arguments);
    }
}
```

## 4. 테스트

테스트를 위해 로컬 서버를 기동하고, `phpunit` 테스트를 실행한다.

```sh
~/thrift-example-project $ php artisan serve
# Laravel development server started on http://localhost:8000/
```

```
~/thrift-example-project $ vendor/bin/phpunit
# PHPUnit 5.6.2 by Sebastian Bergmann and contributors.
# ...
# OK (3 tests, 5 assertions)
```

다음 로그를 보면 `FooMiddleware` 및 `BarMiddlware`에서 Thrift 요청을 처리한 흔적을 볼 수 있다. `all`, `find`, `store` 총 세 개의 API를 테스트 했으므로 총 여섯 개의 로그가 찍혔다.

```sh
# storage/logs/laravel.log

[2016-12-10 14:59:53] local.INFO: handling thrift request [["[object] (App\\Services\\PostService: {})","all",["[object] (Appkr\\Thrift\\Post\\QueryFilter: {\"keyword\":\"Lorem\",\"sortBy\":\"id\",\"sortDirection\":\"desc\"})",0,10]],"App\\Thrift\\FooMiddleware::handle"] 
[2016-12-10 14:59:53] local.INFO: handling thrift request [["[object] (App\\Services\\PostService: {})","all",["[object] (Appkr\\Thrift\\Post\\QueryFilter: {\"keyword\":\"Lorem\",\"sortBy\":\"id\",\"sortDirection\":\"desc\"})",0,10]],"App\\Thrift\\BarMiddleware::handle"] 
[2016-12-10 14:59:53] local.INFO: handling thrift request [["[object] (App\\Services\\PostService: {})","find",[1]],"App\\Thrift\\FooMiddleware::handle"] 
[2016-12-10 14:59:53] local.INFO: handling thrift request [["[object] (App\\Services\\PostService: {})","find",[1]],"App\\Thrift\\BarMiddleware::handle"] 
[2016-12-10 14:59:53] local.INFO: handling thrift request [["[object] (App\\Services\\PostService: {})","store",["foo","Lorem content"]],"App\\Thrift\\FooMiddleware::handle"] 
[2016-12-10 14:59:53] local.INFO: handling thrift request [["[object] (App\\Services\\PostService: {})","store",["foo","Lorem content"]],"App\\Thrift\\BarMiddleware::handle"] 
```

`FooMiddlware`가 예외를 잘 소비하는 지 확인하기 위해서 통합 테스트를 다음과 같이 수정하고 테스트했다. 100번 아이디를 가진 레코드는 없어서 라라벨에서 `ModelNotFoundException`이 나야하고, `FooMiddleware`에 의해서 Thrift 클라이언트에게 `SystemException`으로 전달되어야 한다.

```php
<?php // tests/ThriftClientTest.php

class ThriftClientTest extends TestCase
{
    // ...
    
    public function testFind()
    {
        $response = $this->client->find(100);

        print_r($response);

        $this->assertInstanceOf(ThriftPost::class, $response);
        $this->assertEquals($response->id, 100);
    }
    
    // ...
}
```

아래 그림에서 `Appkr\Thrift\Errors\SystemException: No query results for model [App\Post] 100`처럼 예외 객체가 클라이언트에게 정확하게 전달된 것을 확인할 수 있다.

```sh
# PHPUnit에서 특정 테스트 메서드만 필터링해서 실행하고 싶을 때 --filter 옵션을 사용한다.
~/thrift-example-project $ vendor/bin/phpunit --filter testFind
```

[![ModelNotFoundException](/images/2016-12-10-img-01.png)](/images/2016-12-10-img-01.png)

## 5. 결론

Thrift를 사용하는 동안 디버깅의 괴로움에 스트레스를 받아야 했다. 그럼에도 불구하고 좋았던 점은 서버와 클라이언트간의 약속을 코드로 표현하고, 그 코드를 문서로 즉시 변환해 공유할 수 있다는 점이었다. 클라이언트 개발자가 서버 코드가 개발되고 문서가 나오기까지 멍 때리고 있는 것이 아니라, 서버와 클라이언트가 병렬로 개발을 시작할 수 있었다.

책임 연쇄 패턴을 한 번에 이해했다면 거짓말이다. 이 예제에서 사용한 Thrift 미들웨어의 콜 스택을 이해하기 쉽도록 아래 그림으로 표현했다.

[![Thrift Middleware Call Stack](/images/2016-12-10-img-02.png)](/images/2016-12-10-img-02.png)

이번 포스트의 예제 프로젝트는 
 
-   [https://github.com/appkr/thrift-example-idl](https://github.com/appkr/thrift-example-idl)
-   [https://github.com/appkr/thrift-example-project](https://github.com/appkr/thrift-example-project)

에 공개되어 있다.
