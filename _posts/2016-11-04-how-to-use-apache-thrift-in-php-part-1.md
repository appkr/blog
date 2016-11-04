---
layout: post-minimal
title: 'RPC - Apache Thrift 입문 1부' 
date: 2016-11-04 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- rpc
- "apache thrift"
---

RPC(Remote Procedure Call)와 REST(REpresentational State Transfer)는 원격 API를 호출하는 대표적인 방법이다. 

REST가 API를 통해 원격 서버에 있는 리소스(모델 또는 데이터)에 대한 상태를 주고 받는다고 생각하는 반면, RPC는 원격 서버의 함수를 호출해서 결과를 얻는다고 생각한다. 그래서 REST에서는 `GET /posts/{id}` 또는 `POST /posts`와 같이 원격 서버의 리소스에 접근할 수 있는 직접적인 통로를 제공하는 반면, RPC에서는 URL 엔드포인트는 그냥 통로일 뿐 원격 서버와 클라이언트가 공통으로 사용하는 라아브러리를 시용해서 `$client->find($id)`와 같이 통신한다. 

이 포스트에서는 PHP 프로젝트에서 Apache Thrift RPC 시스템을 사용하는 방법을 설명한다.

**`CAVEAT`** **게시판 서비스를 만드는데 RPC를 쓰지 말라! 속도나 강건함을 얻는 대신 디버깅의 편리함을 포기해야 한다. 클라이언트가 멀티 플랫폼으로 구성되어 있어 서버와 주고 받는 메시지를 엄격하게 규정해야 하고, 외부에 공개하지 않는 API일 때만 고려해 볼 것을 권장한다.**

<!--more-->
<div class="spacer">• • •</div>

## 1. 왜?

웹 API는 클라이언트와 서버가 메시지를 주고 받기 위한 약속이다. 클라이언트가 HTTP 프로토콜을 통해 직렬화된 데이터를 보내면 서버는 받은 데이터를 역직렬화해서 클라이언트의 요청을 이해한다. 서버가 클라이언트의 요청을 처리하는 과정에서 데이터베이스에 접근하고, 데이터베이스에서 조회한 데이터를 가공해서 JSON/XML 형태로 직렬화해서 다시 HTTP 프로토콜로 응답한다. 이 모든 과정은 순조롭다. 그런데 우리가 개발하는 API는 구글, 페이스북, 깃허브등이 하는 오픈 API가 아니라, 대부분이 자체 서비스를 위한 내부 API라는 점이다.  

HTTP + JSON/XML은 검증된 공식이다. 자바냐, 파이썬이냐 등등 플랫폼 의존성도 신경 쓸 필요 없는 만국 공용어 같은 녀석이라 볼 수 있다. 그러나, **JSON은 메시지 구조에 대한 정의가 없고, XML은 무겁다. 게다가 클라이언트와 서버 모두가 이해할 수 있는 API 문서를 작성해야 하고, 양쪽 코드를 모두 관리해야 한다**. 

RPC 시스템에서는 JSON 뿐만 아니라, 바이너리 데이터도 주고 받을 수 있다. 특히 바이너리 데이터는 메시지 크기가 작아, 서버나 클라이언트의 메모리 공간을 절약할 뿐더러 전송 속도가 매우 빠르다. 바이너리 데이터는 JSON (역)직렬화에 비해 특히 클라이언트 측에서 월등한 성능을 보인다. 또, 앞서 지적한 메시지 구조나 파싱 비용에 대한 이슈도 없다.

물론 새로운 것을 배워야 하고 메시지 패킷을 직접 정의해야 하는 등의 번거로움이 있다. 익숙해지기 전까지는 개발자들에겐 이 모든 것이 헬(hell)이고, 생성성은 떨어질 수 밖에 없다.

## 2. 다른 RPC 프레임워크

Apache Thrift 외에도 선택지는 더 있다.

-   **[프로토콜 버퍼(Protocol Buffers)](https://developers.google.com/protocol-buffers/)**
    -   구글이 개발
    -   2008년에 BSD 라이선스로 오픈 소스
    -   구글 운영 환경에서 사용. 우리가 검색 요청을 할 때마다 프로토콜 버퍼가 작동함.
    -   공식적으로 C++/Java/Python/Javascript만 지원하지만, 커뮤니티에서 제공하는 다른 언어용 프로젝트도 있음.
    -   문서가 훌륭하고, 커뮤니티 활동도 활발함.
    -   구글, ActiveMQ, Netty 등에서 사용
    
-   **[Apache Thrift](https://thrift.apache.org/)**
    -   x-구글러가 페이스북에 입사하여 많듦.
    -   2007년에 Apache 라이선스로 오픈 소스
    -   현존하는 RPC 스택 중 가장 많은 언어를 공식적으로 지원함.
    -   RPC 콜을 위한 풀 스택을 지원하므로 트랜스포트를 직접 쓸 필요가 없으며, 심지어 클라이언트/서버 코드도 생성해 줌.
    -   문서는 부실하고, 버전업 속도가 상대적으로 느린 편임.
    -   페이스북, 에버노트, LastFM 등에서 사용
    
-   기타
    -   **[Apache AVRO](https://avro.apache.org/)**, **[GRPC](http://www.grpc.io/)** 외

## 3. 워크플로우

REST든 RPC든 서버와 클라이언트간의 약속을 정하는 일이 먼저다. 대신 RPC는 몇 가지 과정을 더 거쳐야 한다. 

-   서버-클라이언트 간의 약속 만들기(메시지 형식 및 서비스 인터페이스). RPC 프레임워크들은 인터페이스를 정의하기 위한 IDL(Interface Definition Language)을 제공한다.
-   IDL로 정의한 인터페이스 코드를 RPC 프레임워크에서 제공하는 툴(컴파일러)를 이용해서 각 플랫폼(언어)에서 사용할 수있는 보일러 플레이트 코드로 컴파일한다.
-   생성된 보일러 플레이트 코드를 프로젝트로 가져와서 서버 및 클라이언트 애플리케이션 개발한다.

이상에서 언급한 워크플로우에 따라 Apache Thrift를 이용해서 PHP 서버 프로젝트를 만드는 법을 설명한다.

## 4. 약속(IDL) 작성

IDL을 설명하는 Thrift 공식 문서는 많이 부실하다. 필자가 찾은 가이드 중 [https://diwakergupta.github.io/thrift-missing-guide/](https://diwakergupta.github.io/thrift-missing-guide/)가 가장 좋았다. 

이 예졔 프로젝트(`thrift-example-idl`)는 IDL 문법 중 일부만 사용하지만, 진입장벽을 낮춰 주는 좋은 시작점이 될 것이라고 확신하다. IDL 코드 안에 주석으로 설명을 포함했다. 

```java
// https://github.com/appkr/thrift-example-idl/blob/master/src/Post.thrift

include "Errors.thrift"                 // Errors.thrfit 파일을 임포트 한다.

namespace php Appkr.Thrift.Post         // PHP용 네임스페이스를 정의한다.
namespace java kr.appkr.thrift.post     // 다른 언어도 정의할 수 있다는 것을 보여 주기 위해서
                                        // 예제 프로젝트에서 쓰지는 않지만, 자바 패키지도 정의했다.

/**
 * Post 엔티티
 */
struct Post {                           // Post 메시지 타입을 정의한다. 
                                        // 모델이라 볼 수도 있고, 필요한 데이터만 간추린 DTO라 볼 수도 있다.
                                        // PHP에서 연관 배열을 생성자의 인자로 넘겨서 Thrift 객체를 생성한다.
                                        // 예) $post= new Post(['id'=>1, 'title'=>'foo', ...]);
    /** 기본 키 */
    1: optional i32 id,                 // 번호는 클라인트-서버간 통신 및 버전간 호환성 유지를 위해 꼭 필요하다.
                                        // 꼭 필요한 필드라면 required, 그렇지 않다면 optional 키워드를 쓴다.

    /** 포스트 제목 */
    2: optional string title,

    /** 포스트 본문 */
    3: optional string content,

    /** 포스트 최초 생성 시각 */
    4: optional string created_at,

    /** 포스트 최종 수정 시각 */
    5: optional string updated_at
}

/**
 * Post 엔티티의 필드들
 */
enum PostField {                        // enum 필드는 PHP 코드에서 클래스 상수로 변환된다.
    /** 제목 필드 */
    TITLE = 1,                          // 메시지 정의할 때는 콜론(:), enum에서는 등호(=)를 사용한다. 주의하자.
                                        // enum의 값으로 연속된 정수를 쓸 필요는 없다. 100, 200, ..도 가능하다.
    /** 본문 필드 */
    CONTENT = 2,

    /** 최초 생성 시각 */
    CREATED_AT = 3,

    /** 최종 수정 시각 */
    UPDATED_AT = 4,
}

/**
 * 정렬 방향
 */
enum SortDirection {
    /** 오름 차순 */
    ASC = 1,

    /** 내림 차순 */
    DESC = 2,
}

/**
 * PostCollection 엔티티
 */
typedef list<Post> PostCollection       // Thrift가 제공하는 기본 타입 외 커스텀 타입도 정의할 수 있다.

/**
 * 쿼리 필터 엔티티
 */
struct QueryFilter {
    /** 검색할 키워드 */
    1: optional string keyword = '',    // 기본 값을 할당했다.

    /** 정렬 기준이 되는 필드 */
    2: optional PostField sortBy = PostField.CREATED_AT,

    /** 정렬 방향 */
    3: optional SortDirection sortDirection = SortDirection.DESC
}

/**
 * Post 서비스
 */
service PostService {                   // 서비스를 정의한다.
                                        // 여기서 앞서 정의한 struct와 enum을 사용한다.
    /**
     * 포스트 목록을 응답합니다.
     */
    PostCollection all(                 // 리턴 타입 -> 메서드명 순으로 쓴다.
        1: QueryFilter qf,              // 객체형 메서드 인자다.
        2: i32 offset = 0,
        3: i32 limit = 10
    ) throws (                          // 자바처럼 예외를 메서드 뒤에 정의한다.
        1: Errors.UserException userException,
                                        // 임포트한 다른 네임스페이스의 메시지 타입을 참조할 때 점(.)을 이용한다.
        2: Errors.SystemException systemException
                                        // 여러 개의 예외를 던진다면 예외 변수 이름을 서로 다르게 사용해야 한다. 
                                        // 가령 여기서 다시 userException을 쓰면 컴파일 에러가 난다.
    ),

    /**
     * 특정 포스트의 상세 정보를 응답합니다.
     */
    Post find(
        1: i32 id
    ) throws (
        1: Errors.UserException userException
        2: Errors.SystemException systemException
    ),

    /**
     * 새 포스트를 만듭니다.
     */
    Post store(
        1: string title,
        2: string content
    ) throws (
        1: Errors.UserException userException
        2: Errors.SystemException systemException
    )
}
```

`Post.thrift`에서 참조한 `Errors.thrift`는 [예제 프로젝트](https://github.com/appkr/thrift-example-idl/blob/master/src/Errors.thrift)에서 찾을 수 있다.

IDL 예제 프로젝트의 파일 목록은 다음과 같다.

```sh
~/thrift-example-idl/src
├── Errors.thrift
└── Post.thrift
```

## 5. 컴파일해서 보일러 플레이트 코드 생성

Thrift IDL 문법으로 인터페이스 작성이 끝나면 Thrift 컴파일러 바이너리로 보일러 플레이트 코드를 생성한다. 

OS X 컴퓨터에서는 홈브루로 설치할 수 있는데, 이 포스트를 작성 시점의 `thrift` 바이너리는 PHP의 PSR4를 지원하지 않는 0.9.3 버전이다. 따라서 Thrift 프로젝트의 `dev-master 1.0.0-candidate` 소스를 받아서 컴파일해야하는데 OS X에서는 여간 어려운 일이 아니다. 따라서 [OS X에서 미리 컴파일해 놓은 파일을 여기서 다운로드](/files/thrift-osx.gz) 받아 사용할 것을 권장한다. 다운로드 받은 파일의 압축을 풀고 `/usr/local/bin` 디렉터리로 옮기고 실행 권한을 설정해 준다.

```sh
~ $ mv thrift /usr/local/bin/
~ $ chmod 755 /usr/local/bin/thrift
~ $ thrift --version
# Thrift version 1.0.0-dev
```

이제 컴파일해 보자.

```sh
~ $ cd ~/thrift-example-idl
~/thrift-example-idl $ thrift -r --gen php:server,psr4 src/Post.thrift
```

`-r`은 인클루드(임포트)한 파일까지도 컴파일하겠다는 의미이고, `--gen`은 `language:key1[=val1]` 형식으로 쓴다. 가령 IDL로 정의한 인터페이스를 자바 코드로 컴파일한다면 `--gen java`처럼 쓰면 된다. 아무런 에러 피드백 없이 명령 수행이 끝났다면 성공한 것이다. 디렉터리 목록으로 컴파일된 결과를 확인해 보자.

```sh
~/thrift-example-idl
├── gen-php
│   └── Appkr
│       └── Thrift
│           ├── Errors
│           │   ├── ErrorCode.php
│           │   ├── SystemException.php
│           │   └── UserException.php
│           └── Post
│               ├── Post.php
│               ├── PostField.php
│               ├── PostServiceClient.php
│               ├── PostServiceIf.php
│               ├── PostServiceProcessor.php
│               ├── PostService_all_args.php
│               ├── PostService_all_result.php
│               ├── PostService_find_args.php
│               ├── PostService_find_result.php
│               ├── PostService_store_args.php
│               ├── PostService_store_result.php
│               ├── QueryFilter.php
│               └── SortDirection.php
└── src
```

`gen-php`를 `dist-php`로 옮기고,

```sh
~/thrift-example-idl $ mv gen-php dist-php
```

PHP 애플리케이션에서 PSR-4 표준으로 오토로드할 수 있도록 `composer.json` 파일을 만들었다.

```json
// composer.json

{
  "name": "appkr/thrift-example-idl",
  "autoload": {
    "psr-4": {
      "Appkr\\": "dist-php/Appkr"
    }
  }
}
```

`thrift-example-idl` 예제 프로젝트에서는 이상의 모든 작업을 `Makefile`로 작성해 두었다. 자바 컴파일도 포함하고 있다. 해서 다음 명령으로 이상의 복잡한 작업을 수행할 수 있다. 

```sh
~/thrift-example-idl $ make clean
# rm -rf lang/java/build lang/java/post-thrift.jar
# rm -rf gen-* dist-* docs

~/thrift-example-idl $ make
# rm -rf lang/java/build lang/java/post-thrift.jar
# rm -rf gen-* dist-* docs
# thrift -r --gen php:server,psr4 src/Post.thrift
# thrift -r --gen java src/Post.thrift
# ...
# mkdir -p docs
# thrift -r --gen html:standalone -out docs src/Post.thrift
# mv gen-php dist-php
```

`Makefile`에서는 IDL 문서도 HTML로 생성하고 있는데, 열어보면 아래 그림처럼 생겼다.

[![자동 생성된 API 문서](/images/2016-11-04-img-01.png)](/images/2016-11-04-img-01.png)

PHP 및 다른 클라이언트 애플리케이션 프로젝트에서 편하게 사용하기 위해 깃 버전 컨트롤에 올려 두자.

```sh
~/thrift-example-idl $ git push origin master
```

## 6. 애플리케이션 개발

이제 5절에서 생성한 인터페이스를 구현한 PHP 서버 프로젝트를 만들 것이다.

### 6.1. 새 프로젝트 생성

새 라라벨 프로젝트를 생성한다(꼭 라라벨일 필요는 없다). 

```sh
~ $ composer create-project laravel/laravel thrift-example-project --verbose
# Installing laravel/laravel (v5.3.16)
# ...
# Application key [base64:6+n/jPCRoy+KKH0sozxwkgOY9J96Ez9vXhxX/0Uz+h8=] set successfully.

~ $ cd thrift-example-project
~/thrift-example-project $ php artisan --version
# Laravel Framework version 5.3.21
```

간단한 프로젝트므로 데이터베이스 드라이버를 SQLite로 쓴다.
 
```sh
# .env

DB_CONNECTION=sqlite
#DB_HOST=127.0.0.1
#DB_PORT=3306
#DB_DATABASE=homestead
#DB_USERNAME=homestead
#DB_PASSWORD=secret
```

SQLite 데이터베이스를 만든다.

```sh
~/thrift-example-project $ touch database/database.sqlite
```

### 6.2. Thrift가 컴파일한 보일러 플레이트 코드 가져오기 

우리의 서버 애플리케이션에서는 Apache Thrift 라이브러리와 5절에서 생성한 보일러 플레이트 코드가 필요하다. 깃허브와 컴포저를 이용했는데, 그냥 복사해서 vendor 디렉터리 아래에 붙여 넣어도 된다. `composer.json`에 `apache/thrift`와 `appkr/thrift-example-idl`를 추가한다(5절에서 만든 보일러 플레이트 코드는 packagist.org에 등록되어 있지 않으므로, `composer.json`에서 `repositories` 키를 이용했다).

```json
// composer.json

{
  "name": "laravel/laravel",
  "repositories": [
    {
      "type": "vcs",
        "url": "git@github.com:appkr/thrift-example-idl.git"
      }
  ],
  "require": {
    "php": ">=5.6.4",
    "laravel/framework": "5.3.*",
    "apache/thrift": "dev-master",
    "appkr/thrift-example-idl": "dev-master"
  },
  // ...
}
```

방금 추가한 라이브러리를 프로젝트로 끌어온다. 혹시 명령 수행 과정에 `minimimum-stability` 설정에 문제가 있다면, 위 두 개의 의존성을 `composer.json`의 `require-dev` 키 아래로 옮기거나, `"minimum-stability":"dev"` 설정을 `composer.json`에 추가하여 해결할 수 있다. 실 프로젝트에서는 IDL 인터페이스 프로젝트의 컴파일 결과를 별도 브랜치로 옮기거나 태그로 달아 이 문제를 피할 수 있다.

```sh
~/thrift-example-project $ composer update
# ...
# The compiled class file has been removed.
```

### 6.3. 서비스 개발

#### 6.3.1. 데이터 준비

모델과 마이그레이션을 만들고 테스트에 사용할 데이터를 만든다.

```sh
~/thrift-example-project $ php artisan make:model Post --migration
# Created ...
```

4절 에서 정의한 대로 `id`, `title`, `content`, `created_at`, `updated_at` 컬럼을 정의한다.

```php
<?php
// database/migrations/YYYY_MM_DD_hhiiss_create_posts_table.php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreatePostsTable extends Migration
{
    public function up()
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->increments('id');
            $table->string('title');
            $table->text('content');
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('posts');
    }
}
```

마이그레이션(테이블 스키마를 생성)한다.

```sh
~/thrift-example-project $ php artisan migrate
# Migrated: YYYY_MM_DD_hhiiss_create_posts_table
```

방금 만든 테이블에 테스트 데이터를 채우기 위해 모델 팩토리를 만든다.

```php
<?php
// database/factory/ModelFactory.php

// ...

$factory->define(App\Post::class, function (Faker\Generator $faker) {
    return [
        'title' => $faker->sentence,
        'content' => $faker->paragraph,
    ];
});
```

팅커 REPL을 실행하고, 방금 만든 모델 팩토리로 포스트 100개를 만든다.

```sh
~/thrift-example-project $ php artisan tinker
>>> factory(App\Post::class, 100)->create();
# ...
>>> exit
```

#### 6.3.2. 라우팅 및 컨트롤러

클라이언트가 접근할 수 있는 URL 엔드포인트가 필요하다. Thrift에서는 모든 데이터를 HTTP 본문으로 보내기 때문에 HTTP `POST` 메서드로 요청을 보내고 받아야 한다. 

```php
<?php
// routes/api.php

Route::post('posts', 'PostsController@handle');
```

컨트롤러를 만들고, 

```sh
~/thrift-example-project $ php artisan make:controller PostsController
```

컨트롤러의 내용을 채운다.

```php
<?php
// app/Http/Controllers/PostsController.php

namespace App\Http\Controllers;

use App\Services\PostService;           // 직접 만들어야 한다.
use App\Thrift\ThriftResponse;          // 직접 만들어야 한다.
use Appkr\Thrift\Post\PostServiceProcessor;
                                        // 5절에서 IDL 정의에 의해 Thrift 컴파일러가 생성해 준 파일이다. 
use Illuminate\Http\Request;

class PostsController extends Controller
{
    public function handle(Request $request)
    {
        $service = new PostService();   // 서비스 인스턴스를 생성한다.
        $processor = new PostServiceProcessor($service);
                                        // 서비스 인스턴스를 프로세서에 주입한다.
        
        return ThriftResponse::make($request, $processor, 'json');
                                        // HTTP 요청을 Process하고 HTTP 응답을 반환한다.
    }
}
```

`PostService`는 우리가 직접 만들어야 하는 메인 서비스 코드다. 이 서비스 인스턴스를 `PostServiceProcessor`에 주입한다. 프로세서는 앞 절에서 Thrift가 만들어준 코드다.

다음 그림은 Thrift의 네트워크 스택이다. `Transport`는 HTTP 서버와 클라이언트다. `Protocol` 객체는 입력 및 출력 스트림(HTTP 본문)을 읽거나 쓰고, Thrift 객체로 (역)직렬화한다. `Processor`는 매니저와 같은 역할로, 역직렬화된 입력 스트림을 넘겨 받아 생성자로 받은 서비스 객체에게 처리를 위임하고 리턴 값을 받아 `Protocol`에게 넘겨주는 일을 한다.
 
```sh
         +--------------------------------------------+
         |                    Service                 |
         |                   (직접 구현)                |
         +--------------------------------------------+
         |     ↑              Processor         ↓     |
         |                (컴파일러가 자동 생성)           |
         +--------------------------------------------+
         |     ↑(역직렬화)      Protocol    (직렬화)↓     |
         |         (Thrift 라이브러리에 포함되어 있음)      |
         +--------------------------------------------+
 --wire->|                   Transport                |--wire->
         |         (Thrift 라이브러리에 포함되어 있음)      |
         +--------------------------------------------+
```

컨트롤러에서 본 `ThriftResponse`를 만든다.

```php
<?php
// app/Thrift/ThriftResponse.php

namespace App\Thrift;

use Illuminate\Http\Request;
use Thrift\Protocol\TCompactProtocol;   // 바이너리보다 더 가볍다(apache/thrift 라이브러리가 제공).
use Thrift\Transport\TMemoryBuffer;     
use Thrift\Protocol\TJSONProtocol;      // 디버깅할 때 편하다(apache/thrift 라이브러리가 제공). 
use Thrift\Protocol\TBinaryProtocol;    // 대표적 프로토콜이다(apache/thrift 라이브러리가 제공).
use UnexpectedValueException;

class ThriftResponse
{
    public static function make(Request $request, $processor, $format)
    {
        $readTransport = new TMemoryBuffer($request->getContent(false));
        $writeTransport = new TMemoryBuffer();
                                        // (역)직렬화 전에 HTTP 요청/응답을 바이트 단위로 읽고
                                        // 쓰기 위한 임시 저장소다.  

        switch ($format) {              // 프로토콜 객체를 만든다.
            case 'json':
                $readProtocol = new TJSONProtocol($readTransport);
                $writeProtocol = new TJSONProtocol($writeTransport);
                break;
            case 'binary':
                $readProtocol = new TBinaryProtocol($readTransport);
                $writeProtocol = new TBinaryProtocol($writeTransport);
                break;
            case 'compact':
                $readProtocol = new TCompactProtocol($readTransport);
                $writeProtocol = new TCompactProtocol($writeTransport);
                break;
            default:
                throw new UnexpectedValueException;
        }

        $readTransport->open();
        $writeTransport->open();
        $processor->process($readProtocol, $writeProtocol);
                                        // 프로세서에서 역직렬화된 HTTP 요청 본문과
                                        // HTTP 응답을 쓸 수 있는 객체를 인자로 넘긴다.
        $readTransport->close();
        $writeTransport->close();

        $content = $writeTransport->getBuffer();
                                        // 프로세서가 버퍼에 쓴 HTTP 응답 본문을 읽어서 변수에 담는다.

        return response($content)
            ->header('Content-Type', 'application/x-thrift');
                                        // Content-Type 헤더를 application/thrift로 지정해야 한다. 
    }
}
```

트랜스포트와 프로토콜 구현은 컴포저로 가져온 Thrift 라이브러리에 이미 포함되어 있으므로 순서에 맞게 잘 조립하기만 하면 된다. 코드에서 보다시피 `json`, `binary`, `compact` 등의 프로토콜을 이용할 수 있다. 이 코드는 한번 짜놓으면 바꿀 일이 거의 없으므로 내용을 따지지 말고 그냥 공식처럼 가져다 쓰자.

#### 6.3.3. 서비스 개발

`PostServiceIf`는 Thrift가 IDL로 자동 생성한 PHP의 클래스 인터페이스다. IDL에 정의했듯이 이 인터페이스는 

-   `list<ThriftPost> all(QueryFilter $qf, int $offset, int $limit)`, 
-   `ThriftPost find(int $id)`, 
-   `ThriftPost store(string $title, string $content)` 

API를 가지고 있으므로 여기서 구현해 주면 된다. IDL에 의하면 `\Appkr\Thrift\Post\Post` 객체지만, `App\Post` 엘로퀀트 모델과 구분을 위해 일부러 `ThriftPost`로 썼다.

```php
<?php
// app/Service/PostsService.php

namespace App\Services;

use Appkr\Thrift\Post\Post as ThriftPost;
use Appkr\Thrift\Post\PostServiceIf;

class PostService implements PostServiceIf
{
    public function all(\Appkr\Thrift\Post\QueryFilter $qf, $offset, $limit)
    {
        $posts = \App\Post::offset($offset)->limit($limit)->get();
                                        // $offset을 건너뛰고 $limit개의 포스트를 조회하는 엘로퀀트 쿼리다. 
                                        // QueryFilter는 이번 포스트에서는 쓰지 않는다.
        return $posts->map(function ($post) {
            return new ThriftPost($post->toArray());
        })->all();                      // EloquentCollection을 순회하면서 ThriftPost 객체에 맵핑해 준다.
    }

    public function find($id)
    {
        $post = \App\Post::find($id);

        return new ThriftPost($post->toArray());
    }

    public function store($title, $content)
    {
        $post = new \App\Post;
        $post->title = $title;
        $post->content = $content;
        $post->save();

        return new ThriftPost($post->toArray());
    }
}
```

각 API 들이 IDL에서 정의한 `list<ThriftPost>` 및 `ThriftPost` 타입을 반환해야 하므로, `all()` 메서드에서는 엘로퀀트 쿼리에 의해 번환된 `EloquentCollection` 객체를 순회하면서 `ThriftPost` 객체로 맵핑해 주었다.  

#### 6.3.4. 작동 테스트

PHP 프로젝트니까 PHPUnit 테스트에서 Thrift 클라이언트를 만들고 같은 프로젝트에 있는 Thrift 서버로 요청을 보내서 정상 작동을 테스트해 볼 것이다.

```php
<?php
// tests/ThriftClientTest.php

class ThriftClientTest extends TestCase
{
    protected $client;

    public function setUp()
    {
        parent::setUp();

        $transport = new \Thrift\Transport\THttpClient(
            'localhost',
            '8000',
            'api/posts'
        );                              // apache/thrfit 라이브러에서 제공하는 HTTP 클라이언트다.

        $protocol = new \Thrift\Protocol\TJSONProtocol($transport);
                                        // 편의를 위해 JSONProtocol을 이용했다.

        $this->client = new \Appkr\Thrift\Post\PostServiceClient($protocol);
                                        // IDL 컴파일할 때 자동 생성된 클라이언트다. 
    }

    public function testAll()
    {
        $queryFilter = new \Appkr\Thrift\Post\QueryFilter([
            'keyword' => 'Lorem',
            'sortBy' => \Appkr\Thrift\Post\PostField::CREATED_AT,
            'sortDirection' => \Appkr\Thrift\Post\SortDirection::DESC
        ]);                             // QueryFilter 객체를 만들었다.
                                        // 앞서 언급했듯이 연관 배열 형식으로 객체를 만들 수 있다.
                                        // 정의하지 않은 필드는 무시된다. 예) 'foo' => 'bar'는 무시됨.

        $response = $this->client->all($queryFilter, 0, 10);
                                        // 로컬 라이브러리의 API를 호출하듯이 원격 API를 호출한다.
                                        // 마치 Guzzle이나, aws-php-sdk를 쓰는 것과 비슷하다. 
        var_dump($response);
    }

    public function testFind()
    {
        $response = $this->client->find(10);
        var_dump($response);
    }

    public function testStore()
    {
        $response = $this->client->store(
            'foo',
            'Lorem content'
        );
        var_dump($response);
    }
}
```

테스트를 하려면 웹 서버가 필요한데 PHP 내장 웹서버를 이용하자. 

```sh
~/thrift-example-project $ php artisan serve
# Laravel development server started on http://localhost:8000/
```

새 콘솔 창을 열고 PHPUnit 명령으로 서버에 요청을 보내고 정상적인 응답을 받는지 확인한다.

```sh
~/thrift-example-project $ vendor/bin/phpunit
# PHPUnit 5.6.2 by Sebastian Bergmann and contributors.
# ...
# OK (3 tests, 0 assertions)
```

[![PHPUnit](/images/2016-11-04-img-02.png)](/images/2016-11-04-img-02.png)

## 7. 결론

Thrift 클라이언트가 보낸 HTTP 요청 본문은 이렇게 생겼다. `JSONProtocol`을 썼으니 그나마 읽을 수 있는 것이지, `BinaryProtocol`을 쓰면 전혀 읽을 수 없는 본문이 전달된다.

```sh
# storage/logs/laravel.log

[2016-11-04 17:09:27] local.INFO: HTTP Body ["[1,\"all\",1,0,{\"1\":{\"rec\":{\"1\":{\"str\":\"Lorem\"},\"2\":{\"i32\":3},\"3\":{\"i32\":2}}},\"2\":{\"i32\":0},\"3\":{\"i32\":10}}]"] 
[2016-11-04 17:09:27] local.INFO: HTTP Body ["[1,\"find\",1,0,{\"1\":{\"i32\":10}}]"] 
[2016-11-04 17:09:27] local.INFO: HTTP Body ["[1,\"store\",1,0,{\"1\":{\"str\":\"foo\"},\"2\":{\"str\":\"Lorem content\"}}]"] 
```

디버깅이 지극히 힘들다. Thrift 트랜젝션에서 `var_dump($var)`라도 찍으면 `Thrift\Exception\TProtocolException` 또는 `Thrift\Exception\TTransportException`이 바로 떨어진다. 웹 브라우저와 HTTP 클라이언트를 이용하는 것이 아닐 뿐더러, 껍데기만 HTTP일뿐(Tcp도 가능하다고 한다) 완전 다른 프로토콜이므로 라라벨 로그에 의존해서 디버깅 해야 한다. 그럼에도 장점은 있다.

-   (봤다시피) 마치 원격 API를 로컬 라이브러리의 API처럼 호출한다. 따라서 클라이언트는 편하다.
-   각 플랫폼별 코드 뿐만아니라, (예쁘지는 않지만) 문서까지도 자동 생성해 준다.
-   클라이언트가 문서를 읽고 이해해서 데이터 형식에 맞추거나, 서버가 데이터 형식에 대한 유효성을 검사하는데 신경을 덜 쓸 수 있다.
-   빠르다.
 
 Thrift 요청과 응답은 Thrift의 프로토콜 안쪽에서 (역)직렬화 되므로, PHP 변수나 객체로 값을 검사하려면 프로토콜 안쪽에서 해야 한다. 2부에서는 Thrift 프로토콜 안쪽에서 작동하는 미들웨어를 만들어서 예외를 잡고 소비하는 방법을 다룰 예정이다.
 
 <div class="spacer">• • •</div>
 
 이번 포스트의 예제 프로젝트는 
 
-   [https://github.com/appkr/thrift-example-idl](https://github.com/appkr/thrift-example-idl)
-   [https://github.com/appkr/thrift-example-project](https://github.com/appkr/thrift-example-project)

에 공개되어 있다.
