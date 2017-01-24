---
layout: post-minimal
title: '모바일 푸쉬 메시지(FCM)를 위한 PHP 서버 구현 1부' 
date: 2016-12-18 00:00:00 +0900
categories:
  - work-n-play
tags:
  - 개발자
  - Laravel
  - PHP
image: http://blog.appkr.kr/images/images/2016-12-18-img-01.png
---

**FCM(Firebase Cloud Message)은 Android, iOS, Web 등의 클라이언트에 푸쉬 메시지를 보내기 위한 서비스**다. 과거 GCM(Google Cloud Message)이 진화한 것이다.

![Firebase Logo](https://1.bp.blogspot.com/-YIfQT6q8ZM4/Vzyq5z1B8HI/AAAAAAAAAAc/UmWSSMLKtKgtH7CACElUp12zXkrPK5UoACLcB/s1600/image00.png)

PubNub, Pusher 등의 메시징 서비스와 FCM이 다른 점은 단말기가 꺼져 있거나, 잠김 모드에 있거나, 메시지를 받을 애플리케이션이 실행 중이지 않을 때도 메시지를 보낼 수 있다는 점이다.

FCM을 이용한 푸쉬 메시징 시스템을 구성하라면 다음 두 가지가 필요하다.

-   푸쉬 메시지를 받을 모바일 **단말용 애플리케이션**
-   푸쉬 메시지를 전송할 모바일 단말을 선별하고, 원하는 메시지와 함께 구글 FCM 서버에 메시지 전송 요청을 부탁할 **애플리케이션 서버**([구글 공식 문서](https://firebase.google.com/docs/cloud-messaging/server)에서는 "앱 서버"라고 칭하기도 한다).

이 포스트에서는 **애플리케이션 서버를 구현하는 과정**을 기술해본다. 모바일 단말용 애플리케이션은 이 포스트에서 다루지 않는다.

<!--more-->
<div class="spacer">• • •</div>

## 1. FCM 작동 원리

### 1.1. 프로젝트 등록

[Firebase 콘솔](https://console.firebase.google.com/)에서 프로젝트를 만든다. 프로젝트를 등록하는 과정 중에 모바일 애플리케이션의 패키지 이름을 등록해야한다. 등록 과정이 끝나면 대시보드의 설정을 클릭해서 서버 키와 발신자 ID를 얻을 수 있다. 이 값은 메시지를 보낼 때 사용된다.

[![FCM Console](/images/2016-12-18-img-01.png)](/images/2016-12-18-img-01.png)

[![FCM Console](/images/2016-12-18-img-02.png)](/images/2016-12-18-img-02.png)

### 1.2. 단말기 등록

FCM 콘솔에 등록한 패키지 이름으로 FCM SDK를 적용해서 앱을 만들고, 앱을 시작할 때 FCM 서버와 통신하여, 앱을 실행한 해당 단말기를 식별할 수 있는 고유 토큰(`registration_id`)을 받을 수 있다. 전화번호처럼 이 단말기의 고유 식별 번호라 생각하면 된다.

```bash
App Server      FCM Server      Mobile
│               │ Request token │
│               │<--------------│
│               │ Respond "foo" │
│               │-------------->│
│      Token save request "foo" │
│<------------------------------│
│ Saved                         │
│------------------------------>│
```

-   위 시퀀스 다이어그램에서 모바일 애플리케이션이 FCM 서버로 부터 `"foo"`라는 토큰을 받았다.
-   모바일 애플리케이션은 앱 서버에 `"foo"` 토큰 저장 요청을 한다.
-   이 때 앱 서버는 토큰 저장을 요청한 클라이언트(단말 또는 사용자)를 식별하고 전달 받은 토큰을 데이터베이스에 저장한다.

### 1.3. FCM 보내기

메시지를 보내고 싶은 단말기의 토큰을 선별한 후, FCM 서버의 API 엔드포인트로 받을 단말기 목록과 보낼 메시지를 전달하면 된다.

```bash
App Server      FCM Server      Mobile("foo")
│ push message  │               │
│ req heading   │               │
│ for "foo"     │               │
│-------------->│               │
│               │ Deliver       │
│               │ message       │
│               │-------------->│
│        Result │               │
│<--------------│               │
```

모든 과정이 순조로울 수는 없다. 메시지 전송 요청에 대한 FCM 서버의 응답에 따라, 서버에 저장된 클라이언트의 토큰(`registration_id`)을 업데이트하거나 삭제하는 등 몇 가지 후속 처리를 해야할 경우도 있다.

## 2. 단말기 등록 서비스 구현

우리의 모바일 애플리케이션이 FCM 서버와 통신하여 고유한 토큰을 이미 얻은 상태라고 가정하고, 모바일 애플리케이션이 앱 서버에 단말기 등록 요청을 할 수 있는 기능을 구현해 볼 것이다. 1.2절의 내용이다.

### 2.1. 프로젝트 생성

라라벨 프로젝트를 만든다.

```bash
~ $ composer create-project laravel/laravel fcm-scratchpad
# Installing laravel/laravel (v5.3.16)
# ...
# Application key [xxx] set successfully.
```

예제 프로젝트이므로 SQLite 데이터베이스를 사용하자.

```bash
~ $ cd fcm-scratchpad
~/fcm-scratchpad $ touch database/database.sqlite
```

```bash
# .env

DB_CONNECTION=sqlite
#DB_CONNECTION=mysql
#DB_HOST=127.0.0.1
#DB_PORT=3306
#DB_DATABASE=homestead
#DB_USERNAME=homestead
#DB_PASSWORD=secret
```

### 2.2. 모델, 마이그레이션, 시더 만들기

모델과 마이그레이션을 동시에 만든다.

```bash
~/fcm-scratchpad $ php artisan make:model Device --migration
# Model created successfully.
# Created Migration: YYYY_MM_DD_xxxxxx_create_devices_table
```

마이그레이션을 작성한다. 우리 예제에서는 모바일 애플리케이션이 저장을 요청하는 토큰을 `push_service_id` 컬럼에 저장하기로 하자.

```php
<?php // YYYY_MM_DD_xxxxxx_create_devices_table.php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreateDevicesTable extends Migration
{
    public function up()
    {
        Schema::create('devices', function (Blueprint $table) {
            $table->increments('id');
            $table->integer('user_id')->unsigned()->index();
            $table->string('device_id')->nullable();
            $table->string('push_service_id')->nullable();
            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::table('devices', function (Blueprint $table) {
            // 외래키 관계를 선언했다면, 리버스 마이그레이션 할때 에러를 피하기 위해
            // 테이블을 삭제하기 전에 외래키를 먼저 삭제하는 것이 중요하다.
            $table->dropForeign('devices_user_id_foreign');
        });

        Schema::dropIfExists('devices');
    }
}
```

`User` 모델과 `Device` 모델 간의 관계는 일대다 관계라고 가정하자. 한 사람이 여러 대의 단말기를 가질 수 있다는 의미다.

```php
<?php // app/User.php

namespace App;

use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable
{
    // ...
    public function devices()
    {
        return $this->hasMany(Device::class);
    }
}
```

반대 관계도 설정한다.

```php
<?php // app/Device.php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Device extends Model
{
    protected $fillable = [
        'device_id',
        'push_service_id'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

테스트 데이터를 심을 시더를 만든다.

```php
<?php // database/seeds/DatabaseSeeder.php

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run()
    {
        // 라라벨에 기본 내장된 User 모델 팩토리를 이용했다.
        $user = factory(App\User::class)->create([
            'email' => 'user@example.com',
            'name' => '김고객',
        ]);
        // User-Device 간 관계를 이용해서 새 더미 레코드를 생성했다.
        $user->devices()->create([
            'device_id' => str_rand(16),
            'push_service_id' => str_rand(152),
        ]);
    }
}
```

### 2.3. 라우팅과 컨트롤러 만들기

모바일 애플리케이션이 토큰을 등록할 수 있는 API 엔드포인트를 만든다.

```php
<?php // routes/api.php

Route::post('/devices', 'DevicesController@upsert');
```

HTTP 요청 처리 로직을 작성한다. 예제 프로젝트에서는 레코드가 없으면 새로 만들고, 레코드가 있으면 업데이트하는 업서트 로직을 만들었다.

```bash
~/fcm-scratchpad $ php artisan make:controller DeviceController
```

```php
<?php // app/Http/Controllers/DevicesController.php

namespace App\Http\Controllers;

use App\User;
use Illuminate\Http\Request;

class DevicesController extends Controller
{
    public function upsert(Request $request)
    {
        // 사용자 인증 기능을 구현하지 않았으므로 하드코드로 사용자를 지정해주었다.
        $user = User::find(1);

        $device = $user->devices()
            ->whereDeviceId($request->device_id)->first();

        $input = $request->all();

        if (! $device) {
            $device = $user->devices()->create($input);
        } else {
            $device->update($input);
        }

        return $device;
    }
}
```

로컬 서버를 구동하고 포스트맨 등으로 단말기 등록이 잘 작동하는지 확인해 본다.

```bash
~/fcm-scratchpad $ php artisan serve
# Laravel development server started on http://localhost:8000/
```

```http
POST http://localhost:8000/api/devices
Accept: application/json
Content-Type: application/json

{
  "device_id": "1234567890abcdef",
  "push_service_id": "..."
}
```

### 2.4. HTTP 기본 인증 구현

API 클라이언트 인증을 위해 HTTP 기본 인증을 하는 미들웨어를 만들자. `Auth::onceBasic()` 메서드는 클라이언트가 `Authorization` 헤더로 제출한 `base64_encode("{$email}:{$password}")`를 검사하고 로그인 정보가 맞으면 이번 요청 동안만 로그인을 유지하고, 잘못된 로그인 정보라면 401 응답을 반환한다. 

```bash
~/fcm-scratchpad $ php artisan make:middlware AuthenticateOnceWithBasicAuth
```

```php
<?php // app/Http/Middleware/AuthenticateOnceWithBasicAuth.php

namespace App\Http\Middleware;

use Illuminate\Support\Facades\Auth;

class AuthenticateOnceWithBasicAuth
{
    public function handle($request, $next)
    {
        return Auth::onceBasic() ?: $next($request);
    }
}
```

미들웨어를 만들면 HTTP 커널에 등록해야 한다. `auth.basic.once`라는 별칭으로 등록했다.

```php
<?php // app/Http/Kernel.php

namespace App\Http;

use Illuminate\Foundation\Http\Kernel as HttpKernel;

class Kernel extends HttpKernel
{
    // ...
    protected $routeMiddleware = [
        'auth.basic.once' => \App\Http\Middleware\AuthenticateOnceWithBasicAuth::class,
    ];
}
```

이제 미들웨어를 클라이언트 인증 미들웨어를 사용할 수 있는 상태이므로 라우팅에 적용하자. 라우팅 정의 파일에서 직접 적용하는 방법과 컨트롤러 생성자에서 적용하는 방법이 있는 데 후자를 이용한다.

```php
<?php // app/Http/Controllers/DevicesController.php

// ...

class DevicesController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth.basic.once');
    }
    
    public function upsert(DeviceRequest $request)
    {
        // $user = User::find(1);
        $user = $request->user();

        // ...
    }
}
```

다음 그림처럼 포스트맨에서 `Authorization` 탭을 누르고 `Username: user@example.com`, `Password: secret`를 입력한 후 `Update Request` 버튼을 누르면 `Authorization` 헤더가 업데이트된다.

[![Postman](/images/2016-12-18-img-03.png)](/images/2016-12-18-img-03.png)

<small>포스트의 내용보다 그림에서는 전송하는 데이터의 내용이 좀 더 많을 수 있다. 깃허브 예제 프로젝트 구현을 전부 설명할 수 없어서 일부 축약했기 때문이다.</small>

```http
POST http://localhost:8000/api/devices
Accept: application/json
Content-Type: application/json
Authorization: Basic dXNlckBleGFtcGxlLmNvbTpzZWNyZXQ=

{
  "device_id": "1234567890abcdef",
  "push_service_id": "..."
}
```

2.3절과 같은 결과를 얻을 수 있으면 클라언트를 정상적으로 인증하고, 단말기 정보를 잘 등록한 것이다.

<div class="spacer">• • •</div>

포스트가 길어져서 여기서 끊고 나머지는 2부에서 이어가기로 한다.

이번 포스트의 예제 프로젝트는 [https://github.com/appkr/fcm-scratchpad](https://github.com/appkr/fcm-scratchpad)에 공개되어 있다. 이 포스트에서 사용한 포스트맨 콜렉션은 [https://raw.githubusercontent.com/appkr/fcm-scratchpad/master/docs/fcm-scratchpad.postman_collection.json](https://raw.githubusercontent.com/appkr/fcm-scratchpad/master/docs/fcm-scratchpad.postman_collection.json)에서 받을 수 있다. 
