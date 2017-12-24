---
layout: post-minimal
title: 'PHP 프로젝트에 Swagger 적용 #1'
date: 2017-12-24 00:00:00 +0900
categories:
- work-n-play
- learn-n-think
tags:
- Swagger
- API
- PHP
image: http://blog.appkr.kr/images/2017-12-24-img-01_swagger-logo.png
---

<img src="/images/2017-12-24-img-01_swagger-logo.png" style="width:200px">

<div class="text-center">
  <p class="text-muted">PHP 기반 API 서버 프로젝트에 스웨거(Swagger)를 적용할 수 있을까?</p>
  <p class="lead"><strong>예, 적용할 수 있습니다. 예제를 짜서 검증했습니다.</strong></p>
</div>

<div class="spacer">• • •</div>

이 포스트를 쓰기 위한 예제를 진행하면서 스웨거가 해결하고자 했던 문제점을 좀 더 깊이 있게 생각해보는 계기가 되었습니다. 이 시리즈에서는 다음 내용을 다루려고 합니다.

1. 스웨거란 무엇이며, 왜, 언제 쓰는가?
2. PHP 기반 API 서버 프로젝트에 스웨거를 어떻게 적용해야 하는가?

<div class="spacer">• • •</div>

네이버 국어사전에 따르면 **찍새**와 **딱새**를 이렇게 정의하고 있습니다.

- **[찍새](http://krdic.naver.com/detail.nhn?docid=36508000)** 닦을 구두를 모아서 구두닦이에게 가져다주는 일만 하는 사람을 속되게 이르는 말.
- **[딱새](http://krdic.naver.com/detail.nhn?docid=11120600)** 은어로, ‘구두닦이’를 이르는 말.

예~ 구두닦이 서비스를 말하는 겁니다. 주제와 전혀 다른 구두닦이 서비스를 언급한 이유는, 제가 속한 회사의 서비스가 이런 식으로 역할 분담이 되어 있기 때문입니다. 상점으로부터 배송 대행 요청을 접수 받는 서비스와(이하 **프라임**), 기사님들에게 배송 대행 업무를 나누어 주고, 배정 받은 기사님이 물건을 보내고자하는 상점으로 가서 물건을 픽업하고 목적지까지 배송하고 상품가액과 수수료를 결재 받는 서비스(이하 **부릉**)로 구성되어 있습니다. 아무리 구두닦이 장인들이 모여 있더라도 구두를 찍어 오지 못하면 서비스는 쪼그라들겁니다. 반면에, 영업의 신들이 구두를 아무리 잘 찍어와도 구두를 깨끗이 닦지 못하면 손님은 다시 찾아오지 않을 겁니다. 결국 **둘 간에 강한 결합이 존재하며, 서로 선순환을 일으켜야 한다**는 사실을 알 수 있습니다.

참고로 **프라임** 서비스는 라라벨 서버, 닷넷 및 Android 클라이언트로 구성되어 있습니다. **부릉** 서비스는 스프링 서버, 닷넷 및 Android 클라이언트로 구성되어 있습니다. 두 서비스를 전부 관리하는 관리도구는 자바스크립트 SPA <sub class="text-muted">SINGLE PAGE APPLICATION</sub>로 구성되어 있습니다. 

이 포스트와 관련해서 **중요한 사실은 프라임도 부릉에게는 일개 클라이언트라는 점**입니다. 부릉은 멀티 클라이언트 플랫폼에 대응하기 위해 스웨거 API 스펙을 관리하고 있고, 프라임은 부릉이 노출하고 있는 API를 사용하기 위해서 스웨거 스펙으로 자동 생성한 PHP 클라이언트 라이브러리를 컴포저로 땡겨서 `vendor`에 꽂아서 사용합니다. 저는 프라임 서버 개발자입니다. 지난 일년간을 스웨거 스펙의 소비자이기만 하다가, 최근에 갑자기 *'PHP로 짠 서버 프로젝트가 스웨거 API의 생산자가 될 수 있을까?'*라는 생각이 들기 시작했습니다.

<!--more-->
<div class="spacer">• • •</div>

**[스웨거(Swagger)](https://swagger.io/)의 본질은 API 문서**입니다. 스웨거 스펙, 스웨거 문서, API 스펙, API 문서 등으로 다양한 이름으로 불립니다. 여기서 말하는 API는 Web API입니다.

흔히 API 문서라고하면, 설계의 일부이거나, 설계를 실현한 코드가 제공하는 기능을 사람이 이해할 수 있도록 정리한 문서라고 생각하기 쉽습니다. 그런데 스웨거에서는 **사람과 컴퓨터 모두가 읽고 이해할 수 있는 문서**를 의미합니다. 스웨거 스펙을 구심점으로 작동하는, 아래에 나열한 주요 도구들을 보면, 이 말이 무슨 뜻인지 감을 잡을 수 있을 겁니다.

## 1. 도구 세트

### 1.1. Swagger Editor

웹 UI에서 `yml` 형식으로 스웨거 스펙을 직접 작성하거나, 미리 작성한 스펙을 불러와서 수정할 수 있는 편집기입니다.

[![Swagger Editor](/images/2017-12-24-img-02-swagger-editor.png)](/images/2017-12-24-img-02-swagger-editor.png)

### 1.2. Swagger UI

컴퓨터가 이해한 스웨거 스펙을 개발자(==사람)가 이해할 수 있도록 UI로 표현해 줍니다. 요청과 응답 스펙을 나열해 놓은 단순 문서에 그치지 않고, 각 API를 실제로 요청해 볼 수 있습니다. 개발자들은 이 UI를 이용해서 테스트 데이터를 만든다거나, 자신이 개발하는 애플리케이션에서 보낸 요청의 정상 처리 여부 등을 조회해 볼 수 있습니다.

[![Swagger UI](/images/2017-12-24-img-03-swagger-ui.png)](/images/2017-12-24-img-03-swagger-ui.png)

### 1.3. Swagger Codegen

스웨거 스펙을 기반으로 서버 또는 클라이언트 SDK(=\~ 라이브러리 + 문서 등)를 만들어 줍니다. 즉, 스펙만 있으면 서버 또는 클라이언트 코드를 뚝딱 만들고, 복붙 또는 의존성 관리자로 끼워 넣어서 서비스를 빠르게 개발 할 수 있도록 도와줍니다. 이 도구가 지원하는 플랫폼 목록은 아래와 같습니다. 목록에서 `lumen`, `php`, `php-symfony`, `php-silex` 찾으셨나요?

```bash
~ $ swagger-codegen version
# 2.3.0-SNAPSHOT
~ $ swagger-codegen langs
# 모르는 플랫폼은 생략
# Available languages: [..., akka-scala, android, apache2, bash, csharp, clojure, csharp-dotnet2, dart, elixir, eiffel, erlang-client, erlang-server, python-flask, go, go-server, groovy, haskell-http-client, haskell, jmeter, java, java-play-framework, javascript, javascript-closure-angular, kotlin, lua, lumen, nodejs-server, perl, php, php-symfony, powershell, python, qt5cpp, rails5, ruby, rust, rust-server, scala, scala-lagom-server, php-silex, sinatra, slim, spring, html, swagger, swagger-yaml, swift4, swift3, swift, tizen, typescript-angular, typescript-angularjs, typescript-fetch, typescript-jquery, typescript-node, ...]
```

### 1.4. Postman 등 서드파티 도구

스웨거 스펙은 RAML, API Blueprint 등 초기의 API 문서 표준들과 협력하면서도 서로 경쟁하는 관계였으나, 리눅스 재단의 후원을 받으면서 [OpenAPI Specification](https://github.com/OAI/OpenAPI-Specification)으로 이름을 바꾸었고, 지금의 사실상 업계 표준(*de facto*)으로 통용되고 있습니다. 당연히 Postman과 같은 여러 서드파티 도구들도 스웨거 스펙을 지원하고 있습니다. 

[![Postman](/images/2017-12-24-img-04-postman.png)](/images/2017-12-24-img-04-postman.png)
[![Postman](/images/2017-12-24-img-05-postman.png)](/images/2017-12-24-img-05-postman.png)

## 2. 워크플로우

[![Swagger Workflow](/images/2017-12-24-img-06-workflow.png)](/images/2017-12-24-img-06-workflow.png)

<p class="text-center"><small class="text-muted">아이고.. 그림이 약간 틀렸는데, 이해하는데 큰 지장이 없어서 그냥 둘게요~</small></p>

### 2.1. 스웨거 스펙 작성

스웨거 스펙 정의 언어(IDL <sub class="text-muted">INTERFACE DEFINITION LANGUAGE</sub>) 문법을 익혀, Swagger Editor에서 직접 작성하면 됩니다. 또 하나의 방법은 API 서버 프로젝트에 특별한 패키지를 설치하고, 코드에서 Annotation으로 API 문서를 쓴 후, Annotation을 스웨거 스펙으로 변경하는 특별한 명령을 실행하는 방법입니다. 

직접 쓰는 방법은 코드와 문서가 서로 따로 관리되어 문서가 코드의 최신 내용을 정확히 반영하지 못한다거나, 또는 반대의 경우가 발생할 소지가 큽니다. 반면, Annotation 등을 이용하는 방법은 코드와 문서가 같이 존재하므로 앞서 지적한 문제는 덜하겠지만, Annotation 문법을 익혀야 하며, 자칫 코드가 완성되기 전에 API 문서를 공개하지 못하는 함정에 빠지기 쉽습니다. 

API는 약속입니다. 두 모듈을 개발하는 개발자들, 즉 서버와 클라이언트 개발자들이 미리 정의한 약속에 따라 개발을 한다면, 어느 한 쪽의 모듈 개발이 끝날 때까지 다른 모듈 개발자가 기다려야 하는 것이 아니라, 약속에 맞추어서 병렬로 개발할 수 있습니다. 인터페이스가 변경되지 않는 한, 상호 독립적으로 개발하고, 상호 독립적으로 빌드/패키징하고, 상호 독립적으로 배포할 수 있습니다.

정리하자면, 후자를 택한다 해도, API 서버 프로젝트의 HTTP 컨트롤러에서 더미 응답을 제공하는 최소 수준만 코드 작업하고, Annotation을 써서 빠르게 클라이언트 API를 정의할 수 있습니다. 나중에 약간의 변경이 생기더라도, 약속을 빨리 정하는 것이 개발 기간, 품질, 팀웍 모든 면에서 낫다는 점을 경험으로 배웠습니다. 스웨거는 과거의 "Code first" 개발 방식이 아니라, "Document first and generate boilerplate", 즉 RAD <sub class="text-muted">RAPID APPLICATION DEVELOPMENT</sub>를 추구하는 현대적인 애플리케이션 개발 방식을 담고 있습니다.   

자바 스프링에서만 가능한 스웨거 스펙을 생성하는 또 하나의 방법이 있는데요. [`springfox/springfox`](https://github.com/springfox/springfox)를 의존성으로 포함하고, 빌드할 때 스웨거 스펙을 자동으로 생성되게 하는 방법입니다. 패키지가 컨트롤러를 해석해서 작동하므로 Annotation도 필요없습니다. 다른 언어 프레임워크에서 유사한 패키지를 아직 찾거나 듣지는 못했습니다.  

### 2.2. SDK 생성

현재 최신 버전은 2.3.0 입니다. OSX에서는 홈브루를 이용해서 쉽게 설치할 수 있습니다. 아래는 PHP 클라이언트 SDK를 생성하는 명령의 예입니다.

```bash
~/sdk-project $ swagger-codegen help generate
~/sdk-project $ swagger-codegen generate \
    --lang php \
    --input-spec http://localhost/docs/swagger.json \
    --output . 
```

아래와 같은 SDK를 생성해줍니다. API 클라이언트(Guzzle Wrapper), 모델 클래스, 테스트 보일러플레이트, 마크다운으로 된 API 문서 등이 포함되어 있습니다.

```bash
~/sdk-project $ tree .
├── README.md
├── composer.json
├── docs                          # 마크다운으로 된 API 문서
│   ├── Api
│   └── Model
├── src 
│   ├── ApiException.php          # 최상위 예외 클래스
│   ├── Configuration.php         # 설정 주입용 컨테이너 클래스
│   ├── HeaderSelector.php
│   ├── ObjectSerializer.php      # Json String <=> PHP Object
│   ├── Model                     # 모델 클래스
│   │   ├── AccessToken.php
│   │   ├── ...
│   │   └── UserDto.php
│   └── Service                   # API 클래스 (Guzzle Wrapper)
│       ├── AuthApi.php
│       ├── ProductApi.php
│       └── ReviewApi.php
└── test                          # 테스트 보일러플레이트
    ├── Api
    └── Model

9 directories, 63 files
```

일반적으로 서버 개발자의 역할은 스웨거 스펙을 제공하는 일까지 입니다. 해서 보통 API 서버 프로젝트에 Swagger UI 프로젝트도 같이 구동해서 UI 및 스펙 JSON을 서비스 합니다. 공개된 스웨거 스펙을 이용해서 자신의 프로젝트에서 사용할 언어별 SDK를 생성하고 관리하는 일은 클라이언트 개발자의 역할입니다.

필자가 참여하는 프라임 서버는 스웨거를 사용하지 않고, 클라이언트가 서버에 저수준 REST API를 직접 호출합니다. 특히, 타입이 엄격하지 않던 JS 클라이언트와 서버 사이에 엄격한 타입 시스템을 가진 프록시 애플리케이션이 들어가면서, 요청/응답 모델의 데이터 타입 문제들이 심심찮게 발견되고 있습니다. 스웨거를 사용한다면, API 스펙에 의해 클라이언트 코드가 생성되며, 생성된 클라이언트는 서버와 실제 통신을 하게 되므로, 앞 절에서 말한 코드와 문서가 따로 노는 일은 사실상 발생할 수 없습니다.

### 2.3. 라이브러리 설치 및 코드 작성

앞 절에서 생성된 라이브러리는 컴포저를 이용해서 API 클라이언트 프로젝트에 끼워 넣습니다. 물론, 정석은 아니지만 `vendor` 폴더에 직접 복붙해도됩니다.

PHP에서 API 클라이언트를 개발한다면 보통 Guzzle을 이용해서 API 엔드포인트로 HTTP 요청을 보내고 응답을 받아서 처리하는 식으로 프로그래밍할 겁니다. 스웨거가 생성한 클라이언트 코드는 Guzzle를 한번 더 감싸놓은 형태로서, 저수준 REST 호출이 아닌, PHP 함수 호출로 API를 소비할 수 있도록 해 줍니다.

```php
<?php // https://github.com/appkr/swagger-api-client-poc/blob/master/tests/AuthApiTest.php#L57
class AuthApiTest extends SwaggerPocApiTester
{
    public function testMe()
    {
        $authorizationString = $this->getAuthString();
        
        // 전통적으로 많이 쓰던
        // GuzzleClient::get('auth/me', [
        //     'Authorization' => "Bearer {$authorizationString}"
        // ]); 이 아니라,
        // 
        // AuthApi::me(string $authorizationString): UserDto;
        // 라는 시그니처의 함수를 호출했습니다.
        $me = $this->getAuthApi()->me($authorizationString);
        
        $this->dump($me);
        $this->assertInstanceOf(UserDto::class, $me);
    }
}
```

스크롤이 많이 내려가서, PHP 기반 API 서버 프로젝트에 스웨거를 적용하는 예제 프로젝트에 대한 설명은 다음 포스트에 이어가도록 하겠습니다.

<div class="spacer">• • •</div>

예제 프로젝트는 미리 공개합니다.

- **API 서버 프로젝트(Laravel+Annotation+Swagger UI)**
  : [https://github.com/appkr/db-lock-poc](https://github.com/appkr/db-lock-poc)
- **API 클라이언트 라이브러리(Swagger Generated PHP/JS/Java API Client)**
  : [https://github.com/appkr/swagger-poc-api](https://github.com/appkr/swagger-poc-api)
- **PHP API 클라이언트 예제 프로젝트(Lumen)**
  : [https://github.com/appkr/swagger-api-client-poc](https://github.com/appkr/swagger-api-client-poc) 
