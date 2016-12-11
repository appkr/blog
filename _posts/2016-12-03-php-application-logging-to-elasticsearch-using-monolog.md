---
layout: post-minimal
title: "Monolog를 이용한 애플리케이션 로깅" 
date: 2016-12-03 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- PHP
- Laravel
image: http://blog.appkr.kr/images/2016-12-03-img-01.png
---

이 포스트에서는 **PHP 커뮤니티에서 De facto(사실상) 표준으로 인식되는 로깅 라이브러리인 [Monolog](https://github.com/Seldaek/monolog)의 사용법을 소개**한다. Monolog는 [PSR-3](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-3-logger-interface.md) `LoggerInterface`를 구현한 구현체이며, RFC-5424에서 정의한 심각도 규격(e.g. DEBUG, INFO, ..)에 따라 로그를 핸들링한다. 컴포저를 만든 조르디 보기아노(Jordi Boggiano)가 구현했으며, **파일 뿐만 아니라 데이터베이스, 메일, SaaS 서비스등 다양한 방법으로 로그를 처리**할 수 있다.

이 포스트에서는 라라벨 프로젝트에서 기본 로그 저장소인 파일(`storage/logs/laravel.log`)에 더해서 Elastic Search에도 로그를 적재하는 방법을 다룬다. 다음 도구 또는 서비스를 사용한다.

- 라라벨: PHP 프로그래밍 언어로 작성된 풀 스택 웹 프레임워크[^1]
- Elastic Search: 검색에 특화된 데이터베이스. CRUD 및 설정을 위한 REST API를 제공한다.[^2]
- Docker: 컨테이너화된 애플리케이션 운영 환경을 관리하는 도구[^3]

이 포스트의 소스 코드는 [https://github.com/appkr/monolog-scratchpad](https://github.com/appkr/monolog-scratchpad)에서 받을 수 있다.

<!--more-->
<div class="spacer">• • •</div>

## 1. 로그 쓰기

새로 만든 라라벨 프로젝트의 라우팅 정의 파일을 이용해서 로그를 써 봤다.

```php
<?php // routes/web.php

Route::get('/', function () {
    $message = "Hello Monolog";
    $context = ['foo' => 'bar'];
    
    Log::emergency($message, $context);
    Log::alert($message);
    Log::critical($message);
    Log::error($message);
    Log::warning($message);
    Log::notice($message);
    Log::info($message);
    Log::debug($message);
    
    return view('welcome');
});
```

그리고, 로그 파일을 확인해 보면 다음과 같은 로그가 기록된 것을 확인할 수 있다.

```sh
# storage/logs/laravel.log

[2016-12-03 06:58:34] local.EMERGENCY: Hello Monolog {"foo":"bar"} 
[2016-12-03 06:58:34] local.ALERT: Hello Monolog  
[2016-12-03 06:58:34] local.CRITICAL: Hello Monolog  
[2016-12-03 06:58:34] local.ERROR: Hello Monolog  
[2016-12-03 06:58:34] local.WARNING: Hello Monolog  
[2016-12-03 06:58:34] local.NOTICE: Hello Monolog  
[2016-12-03 06:58:34] local.INFO: Hello Monolog  
[2016-12-03 06:58:34] local.DEBUG: Hello Monolog  
```

## 2. Monolog 살펴 보기 

Monolog 라이브러리는 다음과 같은 디렉토리 구조로, 크게 보면 

1. PSR-3 `LoggerInterface` 구현체
2. 로그 핸들러
3. 로그 포매터
4. 로그 프로세서

로 구성되어 있다. 각각의 역할과 예는 아래 블럭에 인라인 주석으로 표시했다.

```sh
~/monolog-scratchpad $ tree vendor/monolog/monolog/src/Monolog
# vendor/monolog/monolog/src/Monolog
# ├── ErrorHandler.php            # Monolog를 전역 예외 처리기로 등록할 때 편리한 헬퍼
# ├── Logger.php                  # PSR-3 LoggerInterface를 구현한 구체 클래스
# ├── Registry.php                # 로거 인스턴스를 등록해놓은 간단한 레지스트리 클래스
# |                                 애플리케이션에서 여러 개의 로거를 사용할 때 쓴다.
# ├── Formatter                   # 포매터
# │   ├── FormatterInterface.php
# │   ├── ...
# │   └── LineFormatter.php       # 로그를 문자열(String)로 포매팅한다.
# ├── Handler                     # 로그 핸들러
# │   ├── AbstractHandler.php
# │   ├── HandlerInterface.php
# │   ├── ErrorLogHandler.php     # 로그를 stdout으로 보낸다.
# │   ├── ...
# │   └── SlackHandler.php        # 로그를 슬랙으로 보낸다.
# └── Processor                   # 프로세서, 로그를 가공하거나 추가 정보를 더한다.
#     ├── ...
#     └── GitProcessor.php        # 로그에 Git 브랜치와 커밋 해시를 추가한다.
#
# 7 directories, 88 files
```

## 3. Elastic Search를 이용한 로그 핸들링

### 3.1. Elastic Search 설치

Elastic Search를 이용하는 이유는 다음과 같다.

1. 검색이 빠르다.
2. [Kibana](https://www.elastic.co/products/kibana) 등 시각화 도구와 연결하기 좋다.

#### 3.1.1. Docker 데몬 설치

아래 설치법은 맥 OS X 기준인데, 다른 운영체제도 [Docker 홈페이지](https://www.docker.com/)를 방문해서 Docker 패키지를 다운로드 받으면 된다. Docker 패키지는 가벼운 리눅스 커널과 유틸리티의 모음이라고 이해하면 된다.

```bash
$ brew tap caskroom/cask
$ brew cask install docker --appdir=/Application
```

**`Note``** Docker 데몬은 관리자 권한을 요구하므로, 설치 후 최초 한번 실행해서 운영체제 로그인 정보를 입력하여 권한을 부여해야한다.

#### 3.1.2. Elastic Search 이미지 다운로드 및 실행

Docker를 쓰는 이유는 환경 격리다. 호스트 운영체제가 윈도우든 맥이든 Docker 이미지는 같은 리눅스 커널 위에서 작동하므로 호스트 운영체제의 영향을 받지 않는다. 게다가 운영체제에 맞춘 복잡한 컴파일 과정을 거치지 않아도 된다. 그냥 아래 명령어들을 복사해서 콘솔에 붙여넣기만 하면 된다. 

```bash
# 도커 컨테이너와 호스트 머신이 공유할 폴더를 만든다.
# 호스트 머신이란 로컬 컴퓨터를 말한다. 
# Docker 이미지는 서버의 스냅샷이고 이를 실행한 상태를 컨테이너라 한다(정확한 표현은 아니다.)
~/monolog-scratchpad $ mkdir esdata

# 이미지를 다운로드 받고 실행한다.
~/monolog-scratchpad $ docker run -d \
    --name es50 \
    -v `pwd`/esdata:/usr/share/elasticsearch/data \
    -p 9200:9200 \
    elasticsearch
# Unable to find image 'elasticsearch:latest' locally
# ...
# Status: Downloaded newer image for elasticsearch:latest
# a88d12860180...

# 실행 상태를 확인한다.
# CONTAINER ID 해시는 필자의 것과 다르다.
~/monolog-scratchpad $ docker ps
# CONTAINER ID        IMAGE            COMMAND    CREATED    STATUS    PORTS    NAMES
# a88d12860180        elasticsearch    ...        ...        ...       9200/tcp es50
```

브라우저에서 `http://localhost:9200`을 방문해서 방금 Docker 컨테이너로 구동한 Elastic Search가 잘 작동하나 확인해 보자.

[![Elastic Search Welcome Page](/images/2016-12-03-img-01.png)](/images/2016-12-03-img-01.png)

### 3.2. Elastic Search PHP 클라이언트 설치 및 작동 확인

앞서 Elastic Search는 REST API를 제공한다고 했다. REST API를 소비하는 PHP 클라이언트를 설치한다.

```bash
~/monolog-scratchpad $ composer require elasticsearch/elasticsearch
```

라우트 정의 파일로 설치한 Elastic Search 라이브러리가 작동하지는 확인한다.

```php
<?php // routes/web.php 

use Elasticsearch\ClientBuilder;

Route::get('/', function () {
    $esClient = ClientBuilder::create()->build();
    dd($esClient);
});
```

[![Elastic Search Client](/images/2016-12-03-img-02.png)](/images/2016-12-03-img-02.png)

### 3.3. Monolog를 위한 Elastic Search 핸들러 만들기 

Monolog 라이브러리에는 `ElasticSearchHandler`가 이미 포함되어 있다. 그런데, 앞 절에서 설치한 Elastic Search 공식 클라이언트가 아닌 다른 클라이언트를 사용하고 있다. API가 달라 부득이 별도의 핸들러를 만들어야 한다. Monolog와 Elastic Search 문서를 읽어 보니 어렵지 않다. 만들어 보자.

라라벨 [공식 문서](https://laravel.com/docs/5.3/errors#configuration)에서는 `bootstrap/app.php`에서 등록하는 방법을 설명하고 있다. 좀 더 고급지고, 다른 프로젝트에서 재활용할 수 있도록 별도 서비스 프로바이더로 만들어 봤다.

```bash
~/monolog-scratchpad $ php artisan make:provider CustomLogProvider
```

`boot()` 메서드에서 `ESHandler` 인스턴스를 만들고 포매터와 프로세서를 추가한 후, `Monolog` 인스턴스에 추가한다. 몇 가지 예제를 더 추가했는데 인라인 주석을 달아 두었다.

```php
<?php // app/Providers/CustomLogProvider.php

namespace App\Providers;

use App\LogHandlers\ESHandler;
use Elasticsearch\ClientBuilder;
use Illuminate\Support\ServiceProvider;
use Monolog\Formatter\NormalizerFormatter;
use Monolog\Processor\WebProcessor;

class CustomLogProvider extends ServiceProvider
{
    public function boot()
    {
        // 라라벨이 부팅하면서 서비스 컨테이너에 이미 등록해놓은 Monolog 인스턴스를 가져온다.
        $monolog = $this->app['log']->getMonolog();
        
        // Elastic Search REST 클라이언트 인스턴스를 만든다.
        $esClient = ClientBuilder::create()->build();
        
        // Monolog에 추가할 Elastic Search 핸들러 인스턴스를 만든다.
        $esHandler = new ESHandler($esClient);
        
        // NormalizerFormatter는 라이브러리에 내장되어 있다.
        // Monolog 메서드의 인자인 $message, $context 값을 정규화한다.
        // 정규화란 데이터 타입을 판단하고 적졀한 형태로 가공하는 것을 말한다.
        $esHandler->setFormatter(new NormalizerFormatter('Y-m-d\TH:i:s.uP'));
        
        // WebProcessor는 HTTP 요청에서 url, ip, http_method, referrer 등의 
        // 값을 추출하고 로그 메시지에 추가하는 일을 한다.
        $esHandler->pushProcessor(new WebProcessor);
        
        // Monolog 라이브러리에 기본 포함된 프로세서가 아닌 정말 정말 커스컴 프로세서를 추가해서
        // 로깅할 데이터를 더 추가한다. 여기서는 애플리케이션 이름, 버전, HTTP 요청을 구분할 수 있는 Hash 값을 추가했다.
        $esHandler->pushProcessor(function (array $record) {
            $record['extra']['app_name'] = config('app.name');
            $record['extra']['app_version'] = env('APP_VERSION', -1);
            $record['extra']['fingerprint'] = request()->fingerprint();
            return $record;
        });
        
        // Elastic Search 핸들러를 Monolog에 추가했다.
        // Monolog는 핸들러를 쌓아 두었다가, 하나씩 순차적으로 실행한다.
        // 즉, 라라벨이 기본으로 생성한 StreamHanlder(파일 로그)를 실행하고, 방금 만든 ESHandler도 실행한다.
        // 이미 생성된 인스턴스의 속성을 변경하는 것이므로 return할 필요 없다.
        $monolog->pushHandler($esHandler);
    }
}
```

이제 `ESHandler`를 만들 차례인데, Elastic Search API 문서를 참고해야 한다. 다음 코드 블록에서 `write` 메서드는 부모 클래스에서 구현을 강제한 메서드이며, 메서드 본문은 Elastic Search PHP 클라이언트의 사용법을 참고한 것이다.

```php
<?php // app/LogHandlers/ESHandler.php

namespace App\LogHandlers;

use Elasticsearch\Client as ESClient;
use Monolog\Handler\AbstractProcessingHandler;
use Monolog\Logger;

class ESHandler extends AbstractProcessingHandler
{
    private $esClient;

    public function __construct(ESClient $esClient, $level = Logger::DEBUG, $bubble = true)
    {
        parent::__construct($level, $bubble);

        $this->esClient = $esClient;
    }

    protected function write(array $record = [])
    {
        $payload = [
            'refresh' => true,
            'body' => [
                [
                    'index' => [
                        '_index' => 'monolog',
                        '_type' => config('app.name')
                    ]
                ],
                $record['formatted'],
            ]
        ];

        $this->esClient->bulk($payload);
    }
}
```

### 3.4. 서비스 프로바이더 등록 및 테스트 

라라벨 프로젝트에서 서비스 프로바이더를 등록하는 일반적인 방법이다.

```php
<?php // config/app.php

return [
    // ...
    'providers' => [
        // ...
        App\Providers\CustomLogProvider::class,
    ]
]
```

라우트 정의 파일에서 로그 쓰는 부분을 좀 더 단순히 고쳤다.

```php
<?php // web/routes.php

Route::get('/', function () {
    $message = "Hello Monolog";
    $context = ['foo' => 'bar'];
    Log::debug($message, $context);
    
    return view('welcome');
});
```

아래 그림은 `http://localhost:9200/monolog/Laravel/_search?size=100&sort=datetime:desc`로 요청했을 때의 출력 결과다.

[![Elastic Search에 적재된 로그](/images/2016-12-03-img-03.png)](/images/2016-12-03-img-03.png)

라라벨의 로그 저장소(파일)에도 잘 기록되었나 확인해 보자.

```bash
# storage/logs/laravel.log

[2016-12-03 10:36:35] local.DEBUG: Hello Monolog {"foo":"bar"} 
```

## 4. 결론

**Monolog는 PHP 커뮤니티 규칙을 따르는 로거**로서, 핸들러, 포매터, 프로세서 등의 기능을 이용해서, 애플리케이션 로깅의 자유도와 확장성을 제공한다. 본문에서 봤다시피 **핸들러를 계속 스태킹(stacking)하여 여러 가지 방법으로 로그를 처리**할 수 있다. 가령 이 글의 예제처럼 파일에도 쓰고, Elastic Search에도 쓰고, 덧붙여서 `stdout` 또는 `stderr`로도 출력하고 싶다면 `ErrorLogHandler`를 추가하면 된다. 아래처럼 말이다.

```php
<?php // app/Providers/CustomLogProvider.php

class CustomLogProvider extends ServiceProvider
{
    public function boot()
    {
        // ...
        $errorLogHandler = new \Monolog\Handler\ErrorLogHandler();
        $monolog->pushHandler($errorLogHandler);
    }
}
```

**`Note`** Docker 컨테이너를 중지하려면 `docker stop es50` 명령을 수행한다. `docker rm es50` 명령으로 이미 만든 컨테이너를 완전히 삭제하지 않았다면 다음 번 실행할 때는 `docker start es50` 명령으로 간단히 시작할 수 있다. Elastic Search는 꽤 무거운 서비스라 부팅하는데 10초 정도 걸릴 수 있다.

---

[^1]: 라라벨 https://laravel.com
[^2]: Elastic Search https://www.elastic.co/kr/
[^3]: Docker https://www.docker.com/
