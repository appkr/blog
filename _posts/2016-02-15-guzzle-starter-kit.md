---
layout: post
title:  Guzzle Starter Kit
date: 2016-02-15 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- php
- psr
- guzzle
---
[Guzzle](http://docs.guzzlephp.org/en/latest/) 은 PHP 세계에서 *De facto*[^1] 표준으로 간주되는 HTTP Client 이다. Laravel[^2] 프레임웍을 보면 [Symfony HttpFoundation Component](https://github.com/symfony/http-foundation) 를 이용해서 클라이언트의 HTTP 요청에 응답하는데 이는 HTTP Server 이다. 가령, Laravel 프로젝트에서 Slack 메시지를 보낸다거나, Mandrill API 를 이용해서 메일을 보낸다든가, Github 에서 특정 Repo 의 Star 개수를 가져올 때 등등을 하려할 때 필요한 것이 HTTP Client 이다.

난 Guzzle 을 거의 사용하지 않았다. 왜냐하면, `guzzle/http`, `guzzle/guzzle` 로 패키지 이름이 바뀌는가 하면 Major 버전 업 마다 API 가 완전히 달려지고 사용법이 완전히 달라졌기 때문이다. 그럼에도 불구하고 *De facto* 로 인지되었던 이유는, PHP 에 기본 내장된 HTTP Client (==CURL) 의 복잡한 사용법을 대체할 무엇인가가 필요했고, 그 수요에 Guzzle 이 잘 대응했기 때문이라 생각된다.

그간에는 [Httpful](https://github.com/nategood/httpful) 이란 비교적 간단한 HTTP Client 를 이용해서 프로젝트를 진행했었다.

```php
<?php // Sending Slack message with Httpful

class Slack {
    public function send($text)
    {
        return \Httpful\Request::post('hook_address')->sendsJson()->body(['text' => $text])->send();    
    }
}

(new Slack)->send('Hello Slack');
```

Guzzle 을 다시 봐야 하는 이유는 2005 년 초에 PSR-7 이 발표되었고, Guzzle 이 이를 따르기 때문이다. 마치 Monolog 가 PSR-3 를 따르고, PHP 세계에서 *De facto* Logger 로 인지되는 것 처럼. 이젠 표준을 따르기 때문에 변화가 많지 않을 것이란 기대 때문이다. (SPDY 때문에 달라질게 있으려나??)

<!--more-->
<div class="spacer">• • •</div>

## PSR-7

[PSR-7](http://www.php-fig.org/psr/psr-7/) 은 HTTP message (==Request/Response) 에 대한 PHP-FIG 의 표준이다. HTTP Server 와 Client 모두에 적용되는 표준이다. [코드는 여기](https://github.com/php-fig/http-message)서 살펴볼 수 있는데 Interface 덩어리 이다.

## Guzzle Starter

자주 쓰지 않는 것들은 할 때마다 문서를 다시 봐야하는데.. 조금만 부지런해져서 [Guzzle Starter](https://github.com/appkr/guzzle-starter) 를 하나 만들어 놓기로 했다. Facebook 과 Github 사이에 약 5 초간 고민하다가, 개발자는 Github~ Github API 에서 Guzzle HTTP Client 로 접근해서 데이터를 가져오는 간단한 샘플을 만들기로 했다.  

### Scaffolding

```bash
$ mkdir guzzle-starter && cd guzzle-starter
$ echo "{}" > composer.json
$ composer require guzzlehttp/guzzle
$ composer install
$ mkdir src tests
```

```bash
.
├── composer.json
├── composer.lock
├── src
│   ├── Github.php      # Github API 요청 클래스
│   ├── client.php      # 실행 스크립트
│   └── config.php      # 로그인 정보 (.gitignore 에 포함)
├── tests
└── vendor
```

```javascript
// composer.json

{
  // ...
  "require": {
    "guzzlehttp/guzzle": "~6.1",
    // "monolog/monolog": "~1.17"
  },
  "autoload": {
    "psr-4": {
      "App\\": "src/"
    }
  }
}
```

### Github.php

```php
<?php // src/Github.php

namespace App;

use GuzzleHttp\Client;
// use GuzzleHttp\HandlerStack;
// use GuzzleHttp\MessageFormatter;
// use GuzzleHttp\Middleware;
use GuzzleHttp\Psr7\Request;
// use Monolog\Handler\StreamHandler;
// use Monolog\Logger;

class Github
{
    protected $debug = true;

    protected $client;

    public function __construct($base = null)
    {
        if (! $this->client) {
//            $logger = new Logger('mylogger');
//            $logger->pushHandler(new StreamHandler(__DIR__ . '/../logs/log.txt'));
//
//            $formatter = new MessageFormatter(MessageFormatter::DEBUG);
//
//            $handler = HandlerStack::create()->push(
//                Middleware::log($logger, $formatter)
//            );

            $this->client = new Client([
                'base_uri' => $base ?: 'https://api.github.com'/*,
                'handler'  => $handler*/
            ]);
        }
    }

    public function user($credentials)
    {
        try {
            $request = new Request('GET', 'users/' . $credentials['username'], [
                'debug' => $this->debug,
                'verify' => 'false',
                'headers' => [
                    'Accept' => 'application/vnd.github.v3+json',
                    'User-Agent' => 'Guzzle 6.2'
                ],
                'auth' => [
                    $credentials['username'],
                    $credentials['password']
                ]
            ]);

            $response = $this->client->send($request);
        } catch (Exception $e) {
            echo $e->getMessage();
        }

        return $response->getBody();
    }
}
```

`$response = (new Client('https://api.github.com'))->get('users/...', [/* ... */])` 처럼 간단히 써도 동작은 잘 된다. 디버깅을 위해 Request/Response 를 로그에 쓰는 등 여러가지 실험을 해 본다고 복잡해 졌다. 언제 필요할 지 모르니...

### Client

```php 
<?php // src/config.php

return [
    'username' => 'username',
    
    // For github_token
    // @see https://github.com/settings/tokens
    'password' => 'github_token'
];
```

```php
<?php // src/client.php

require __DIR__ . '/../vendor/autoload.php';
$credentials = include(__DIR__ . '/./config.php');
echo (new App\Github)->user($credentials);
```

### Run

```bash
$ php src/client.php
```

[![](/images/2016-02-15-img-01.png)](/images/2016-02-15-img-01.png)

<div class="spacer">• • •</div>

[^1] [De facto](https://en.wikipedia.org/wiki/De_facto) "in fact", "in reality", "as a matter of fact", "사실상" 이란 의미

[^2] [Laravel](https://laravel.com/) PHP 언어로 작성된, MVC 아키텍처를 따르는 웹 프레임웍이다. 요즘 PHP 세계에서는 완전 대세다.
