---
layout: post-minimal
title: '모바일 푸쉬 메시지(FCM)를 위한 PHP 서버 구현 2부' 
date: 2016-12-24 00:00:00 +0900
categories:
  - work-n-play
tags:
  - 개발자
  - Laravel
  - PHP
image: http://blog.appkr.kr/images/images/2016-12-24-img-01.png
---

**FCM(Firebase Cloud Message)은 Android, iOS, Web 등의 클라이언트에 푸쉬 메시지를 보내기 위한 서비스**다. 과거 GCM(Google Cloud Message)이 진화한 것이다.

지난 [1부](/work-n-play/firebase-cloud-message-php-server-implementation-part-1/)에서는 푸쉬 메시지를 받을 모바일 단말 애플리케이션이 구글 FCM 서버로 부터 받은 고유 식별 토큰을 애플리케이션 서버로 전달해 등록하는 과정을 구현했다. 이번 포스트에서는 등록한 토큰으로 푸쉬 메시지를 쏘는 기능을 구현한다. 

<!--more-->
<div class="spacer">• • •</div>

## 1. FCM 라이브러리 선택 및 적용

이 글을 쓰는 시점에 PHP 버전의 공식 FCM 라이브러리는 없다. [Packagist](https://packagist.org/)를 검색해보면 다음과 같은 결과를 얻을 수 있다. 

[![Packagist Search](/images/2016-12-24-img-01.png)](/images/2016-12-24-img-01.png)

다운로드 9,070회와 좋아요 59개를 받은 `brozot/laravel-fcm`, 8,456회와 50개를 받은 `paragraph1/php-fcm` 라이브러리가 눈에 들어온다. 스페이스 대신 탭을 쓰고, PHP에는 없는 ENUM을 만들어 쓰는 등 Java 스러워서 한참을 고민하다, 버전이 1.2.x이고 코드 퀄리티가 더 훌륭해서 `brozot/laravel-fcm`로 선택했다.

### 1.1. 라이브러리 설치

컴포저로 라이브러리를 가져온다.

```bash
~/fcm-scratchpad $ composer require brozot/laravel-fcm
```

설치한 라이브러리를 라라벨에서 사용하기 위해서는 라이브러리에서 제공하는 서비스 프로바이더를 등록해야 한다. 서비스 프로바이더가 라라벨 부팅 시점에 필요한 인스턴스를 생성해서 서비스 컨테이너에 미리 등록하면, 애플리케이션 실행 중에 언제든 꺼내 쓸 수 있다. 

```php
<?php // config/app.php

return [
    // ...
    'providers' => [
        // ...
        LaravelFCM\FCMServiceProvider::class,
    ]  
];
```

이전 포스트에서 설명했듯이 Firebase 콘솔로 부터 받은 서버 키와 발신자 ID를 방금 설치한 라이브러리에 알려주어야 FCM 서버와 정상적으로 HTTP 통신을 할 수 있다. 라이브러리의 설정 파일을 복제하고, `.env` 파일에 값을 기록하자.

```bash
~/fcm-scratchpad $ php artisan vendor:publish --provider="LaravelFCM\FCMServiceProvider"
```

위 명령은 `config/fcm.php` 파일을 생성한다.

```php
<?php // config/fcm.php

return [
    // ...
    'http' => [
        'server_key' => env('FCM_SERVER_KEY', 'Your FCM server key'),
        'sender_id' => env('FCM_SENDER_ID', 'Your sender id'),
        // ...
    ],
];
```

아하! `FCM_SERVER_KEY`, `FCM_SENDER_ID` 두 개의 환경 변수를 참조하는 것을 알았으므로, 1부에서 FCM 콘솔에서 프로젝트를 등록하고 얻은 값들을 `.env` 파일에 써준다.

```bash
# .env

FCM_SERVER_KEY=AAAAMqBU...OJy1Dw
FCM_SENDER_ID=217...581
```

### 1.2. 설치한 라이브러리를 사용하여 FCM 보내기

설치한 라이브러리의 기능을 가장 쉽게 확인할 수 있는 방법은 라우트를 하나 만들고 브라우저에서 해당 라우트로 접속해서 작동을 확인하는 방법이다. 아래 코드는 [라이브러리의 `README`에 소개된 내용](https://github.com/brozot/Laravel-FCM#basic-usage) 그대로다.

```php
<?php // routes/api.php

use Illuminate\Http\Request;
use LaravelFCM\Message\OptionsBuilder;
use LaravelFCM\Message\PayloadDataBuilder;
use LaravelFCM\Message\PayloadNotificationBuilder;

Route::get('fcm', function () {
    $optionBuilder = new OptionsBuilder();
    $optionBuilder->setTimeToLive(60*20);

    $notificationBuilder = new PayloadNotificationBuilder('알림 제목');
    $notificationBuilder->setBody('알림 본문')->setSound('default');

    $dataBuilder = new PayloadDataBuilder();
    $dataBuilder->addData(['foo' => 'bar']);

    $option = $optionBuilder->build();
    $notification = $notificationBuilder->build();
    $data = $dataBuilder->build();

    $token = 'eI..b0:APA...FJx';

    $downstreamResponse = app('fcm.sender')->sendTo($token, $option, $notification, $data);

    var_dump('numberSuccess', $downstreamResponse->numberSuccess());
    var_dump('numberFailure', $downstreamResponse->numberFailure());
    var_dump('numberModification', $downstreamResponse->numberModification());
    var_dump('tokensToDelete', $downstreamResponse->tokensToDelete());
    var_dump('tokensToModify', $downstreamResponse->tokensToModify());
    var_dump('tokensToRetry', $downstreamResponse->tokensToRetry());
    var_dump('tokensWithError', $downstreamResponse->tokensWithError());
});
```

로컬 서버를 구동하고 `GET /api/fcm`을 방문하면 다음 결과를 얻을 수 있다. 

```bash
~/fcm-scratchpad/routes/api.php:46:string 'numberSuccess' (length=13)
~/fcm-scratchpad/routes/api.php:46:int 0

~/fcm-scratchpad/routes/api.php:47:string 'numberFailure' (length=13)
~/fcm-scratchpad/routes/api.php:47:int 1

~/fcm-scratchpad/routes/api.php:48:string 'numberModification' (length=18)
~/fcm-scratchpad/routes/api.php:48:int 0

~/fcm-scratchpad/routes/api.php:49:string 'tokensToDelete' (length=14)
~/fcm-scratchpad/routes/api.php:49:
array (size=1)
  0 => string 'eI..b0:APA...FJx' (length=152)
  
~/fcm-scratchpad/routes/api.php:50:string 'tokensToModify' (length=14)
~/fcm-scratchpad/routes/api.php:50:
array (size=0)
  empty
  
~/fcm-scratchpad/routes/api.php:51:string 'tokensToRetry' (length=13)
~/fcm-scratchpad/routes/api.php:51:
array (size=0)
  empty
  
~/fcm-scratchpad/routes/api.php:52:string 'tokensWithError' (length=15)
~/fcm-scratchpad/routes/api.php:52:
array (size=0)
  empty
```

유효하지 않은 단말기 토큰이므로 실패가 떨어지는 것은 당연하다. 우리의 PHP 애플리케이션 서버에서 생성한 메시지가 FCM 서버를 거쳐 단말기에게 전달되는 전체 과정을 확인하지는 못했지만, 적어도 FCM 서버와 통신이 된다는 것은 확인했다. 

## 2. 푸쉬 메시지 요청에 대한 FCM 서버 응답의 이해

아무리 라이브러리를 가져다 쓴다지만 [FCM 문서](https://firebase.google.com/docs/cloud-messaging/server#response)를 이해하지 않고는, FCM 서버의 응답 메시지에 따라 어떤 후속 처리를 해야 할지 알 수 없다. 다음은 총 6개의 단말기에 푸쉬 메시지를 보냈을 때 FCM 서버의 응답 예제이다. 

```json
{ 
  "multicast_id": 216,
  "success": 3,
  "failure": 3,
  "canonical_ids": 1,
  "results": [
    { "message_id": "1:0408" },
    { "error": "Unavailable" },
    { "error": "InvalidRegistration" },
    { "message_id": "1:1516" },
    { "message_id": "1:2342", "registration_id": "32" },
    { "error": "NotRegistered"}
  ]
}
```

우선 `results.message_id`가 있는 메시지들은 성공한 것이다. 다행히 우리가 설치한 라이브러리는 FCM 서버의 응답을 미리 파싱해서 이해하기 쉬운 메서드 이름으로 제공하고 있는데, 다음 표로 정리했다.

응답 필드|라이브러리의 메서드(`DownstreamResponse`)|설명|예제 응답 번호(zero-index)
---|---|---
`success`|`numberSuccess()`|푸쉬 메시지 전달에 성공한 건수|0,3,4
`failure`|`numberFailure()`|푸쉬 메시지 전달에 실패한 건수|1,2,5
`canonical_ids`|`numberModification()`|단말기의 고유 식별 토큰이 변경된 건수|4
&nbsp;|`tokensToDelete()`|애플리케이션 서버에서 삭제할 토큰의 목록|5
&nbsp;|`tokensToModify()`|애플리케이션 서버에서 업데이트할 토큰의 목록|4
&nbsp;|`tokensToRetry()`|애플리케이션 서버에서 재 전송해야 하는 토큰의 목록|1
&nbsp;|`tokensWithError()`|에러가 난 이유 목록|&nbsp;

## 3. FCM 전송 및 응답 처리 클래스 구현

라이브러리가 제공하는 사용법 예제만으로는 뭔가 부족하다. 우리 서비스만을 위한 클래스를 만들텐데, 이름을 `FCMHandler`라고 하자. 이 클래스는 라이브러리의 API를 이용하여 FCM 메시지를 보내고 응답 결과에 따라 전송을 재시도하거나 서버에 등록된 단말기 등록 정보를 조작하는 일을 할 것이다. 아래 코드 블록의 인라인 설명 및 주석을 참고한다.

```php
<?php // app/Services/FCMHandler.php

namespace App\Services;

use App\Device;
use LaravelFCM\Message\OptionsBuilder;
use LaravelFCM\Message\PayloadDataBuilder;
use LaravelFCM\Message\PayloadNotificationBuilder;
use LaravelFCM\Response\DownstreamResponse;

class FCMHandler
{
    /**
     * 푸쉬 메시지를 보낼 단말기의 registration_id(==push_service_id) 목록.
     *
     * @var array[string $push_service_id]
     */
    protected $to = [];

    /**
     * 보낼 메시지.
     *
     * @var array[string $key => string $value]
     */
    protected $data = [];

    /**
     * @var \LaravelFCM\Sender\FCMSender
     */
    protected $fcm;

    /**
     * 전송이 실패해서 여러 번 재전송할 때를 대비해 한 번 만든 메시지 인스턴스를 캐시하는 저장소.
     *
     * @var array
     *  [
     *      'optionBuilder' => \LaravelFCM\Message\Options,
     *      'notificationBuilder' => \LaravelFCM\Message\PayloadNotification,
     *      'data' => \LaravelFCM\Message\PayloadData
     *  ]
     */
    private $cache = [];

    /**
     * FCMHandler constructor.
     * @param array $to
     * @param array $data
     */
    public function __construct(array $to = [], $data = [])
    {
        $this->to = $to;
        $this->data = $data;
        // 라이브러리가 제공한 LaravelFCM\FCMServiceProvider를 열어 보면
        // 라라벨의 서비스 컨테이너에 인스턴스를 등록할 때의 키를 알 수 있다.
        // 'fcm.sender'라는 키를 사용하고 있어서, app() 헬퍼를 이용해서 등록된 인스턴스를 가져왔다.
        // 마치 $container = ['key' => new stdClass]에서 $container['key']를
        // 사용해서 할당된 stdClass 인스턴스를 얻어 오는 것과 같은 개념이다.
        $this->fcm = app('fcm.sender');
    }

    /**
     * 푸쉬 메시지를 보낼 단말기의 registration_id 목록을 설정한다.
     *
     * @param array $to
     * @return $this
     */
    public function to(array $to)
    {
        $this->to = $to;

        return $this;
    }

    /**
     * 푸쉬 메시지 전송을 라이브러리에 위임하고, 전송 결과를 처리한다.
     *
     * @param array $data
     * @return DownstreamResponse
     * @throws \Exception
     */
    public function send($data = [])
    {
        $this->data = $data;
        $retryCount = 0;
        $retryInterval = [1, 2, 4];

        $response = $this->fire();

        if ($response->numberModification() > 0) {
            // 단말기 공장 초기화 등의 이유로 registration_id가 바뀌었다.
            $tokens = $response->tokensModify();
            $this->updateDevices($tokens);
        }

        if ($response->numberFailure() > 0) {
            if ($tokens = $response->tokensToDelete()) {
                // 해당 registration_id를 가진 단말기가 구글 FCM 서비스에 등록되어 있지 않다.
                $this->deleteDevices($tokens);
            }

            if ($tokens = $response->tokensToRetry()) {
                $this->to($tokens);

                if (isset($retryInterval[$retryCount])) {
                    // 메시지 전송에 실패했다.
                    // 1,2,4초 간격으로 총 세 번 재 시도한다.
                    sleep($retryInterval[$retryCount]);
                    $response = $this->send();
                    $retryCount += 1;
                }

                if ($response->numberFailure()) {
                    // 세 번을 재시도했음에도 성공하지 못했다 ㅜㅜ.
                    \Log::debug(
                        '푸쉬 메시지를 보낼 수 없습니다.',
                        $response->tokensWithError()
                    );
                }
            }
        }

        return $response;
    }

    /**
     * 이제 진짜로 푸쉬 메시지를 전송한다.
     *
     * @return DownstreamResponse
     */
    protected function fire()
    {
        return $this->fcm->sendTo(
            $this->getTo(),
            $this->buildOption(),
            null,
            $this->buildPayload()
        );
    }

    /**
     * 중복 수신자를 제거한 수신자 목록을 반환한다.
     *
     * @return array
     */
    protected function getTo()
    {
        return array_unique($this->to);
    }

    /**
     * 푸쉬 메시지 전송 옵션을 설정한다.
     *
     * @return \LaravelFCM\Message\Options
     */
    protected function buildOption()
    {
        if (array_key_exists('optionBuilder', $this->cache)) {
            // 캐시 되어 있으면 캐시를 사용한다.
            // 마치 위에서 app() 헬퍼를 쓴 것과 비슷하다.
            return $this->cache['optionBuilder'];
        }

        $optionBuilder = new OptionsBuilder();
        $optionBuilder->setTimeToLive(60*20);

        return $this->cache['optionBuilder'] = $optionBuilder->build();
    }

    /**
     * (단말기의 Notification Center에 표시될) 알림 제목과 본문을 설정한다.
     *
     * @param string $title
     * @param string $body
     * @return \LaravelFCM\Message\PayloadNotification
     */
    protected function buildNotification(string $title, string $body)
    {
        if (array_key_exists('notificationBuilder', $this->cache)) {
            return $this->cache['notificationBuilder'];
        }

        $notificationBuilder = new PayloadNotificationBuilder($title);
        $notificationBuilder->setBody($body)->setSound('default');

        return $this->cache['notificationBuilder'] = $notificationBuilder->build();
    }

    /**
     * 메시지 본문을 설정한다.
     *
     * @return \LaravelFCM\Message\PayloadData
     */
    protected function buildPayload()
    {
        if (array_key_exists('data', $this->cache)) {
            return $this->cache['data'];
        }

        $dataBuilder = new PayloadDataBuilder();
        $dataBuilder->addData($this->data);

        return $this->cache['data'] = $dataBuilder->build();
    }

    /**
     * 변경된 단말기의 토큰을 DB에 기록한다.
     *
     * @param array[string $old => string $new] $tokens
     * @return bool
     */
    protected function updateDevices(array $tokens)
    {
        foreach ($tokens as $old => $new) {
            $device = Device::wherePushServiceId($old)->firstOrFail();
            $device->push_service_id = $new;
            $device->save();
        }

        return true;
    }

    /**
     * 유효하지 않은 단말기 토큰을 DB에서 삭제한다.
     *
     * @param array[string $push_service_id] $tokens
     * @return bool
     */
    protected function deleteDevices(array $tokens) {
        foreach ($tokens as $token) {
            $device = Device::wherePushServiceId($token)->firstOrFail();
            $device->delete();
        }

        return true;
    }
}
```

우리의 `FCMHandler` 클래스가 노출하는 API는 딱 두 개다. `to(array $to)` 메서드는 수신자를 지정한다. `send(array $data)` 메서드는 라이브러리의 API를 한번 더 랩핑한 것으로 푸쉬 메시지 전송을 라이브러리의 API에 위임하고 응답 결과를 받아 처리하는 일을 한다. 가령 FCM 서버로부터 `Unavailable` 응답을 받았다면, 1, 2, 4초 간격으로 `send()` 메서드 자신을 다시 호출하여 메시지 전송을 재시도한다.

## 4. FCM 보내기 구현

1.2절에서 썼던 코드는 `FCMHandler`를 이용하면 다음과 같이 바뀐다.

```php
<?php // routes/api.php

// ...

use Illuminate\Http\Request;
use App\Services\FCMHandler;

Route::get('fcm', function (Request $request, FCMHandler $fcm) {
    // 푸쉬 메시지를 수신할 단말기의 토큰 목록을 추출한다.
    $user = $request->user();
    $to = $user->devices()->pluck('push_service_id')->toArray();

    if (! empty($to)) {
        // 보낼 내용이 마땅치 않아 로그인한 사용자 모델을 푸쉬 메시지 본몬으로 ㅡㅡ;. 
        $message = array_merge(
            $user->toArray(),
            ['foo' => 'bar']
        );

        // FCMHandler 덕분에 코드는 이렇게 한 줄로 간결해졌다.
        $fcm->to($to)->send($message);
    }

    return response()->json([
        'success' => 'HTTP 요청 처리 완료'
    ]);
})->middleware('auth.basic.once');
```

로컬 서버를 구동한다. 1부에서 구현했던 단말기 등록 API를 먼저 호출해서 단말기를 등록한다. 포스트맨에서 `GET /api/fcm` 요청해서 푸쉬 메시지를 보내본다.

```http
GET http://localhost:8000/api/fcm
Accept: application/json
Content-Type: application/json
Authorization: Basic dXNlckBleGFtcGxlLmNvbTpzZWNyZXQ=
```

그림과 같은 응답을 받았고, 로그 파일에는 전송 실패 메시지가 기록되었다. 

[![Postman](/images/2016-12-24-img-02.png)](/images/2016-12-24-img-02.png)

```bash
# storage/logs/laravel-fcm.log

[2016-12-24 04:55:46] Laravel-FCM.INFO: notification send to 1 devices success: 0 failures: 1 number of modified token : 0  [] []
```

## 5. 결론

2부에 걸친 포스트를 통해 모바일 단말기에 Firebase Cloud Message를 보내기 위한 PHP 애플리케이션 서버를 구현하는 방법을 다루었다. 3부를 쓸 기회가 있다면 빠진 퍼즐 조각인 모바일 앱 부분을 소개할 예정이다.

고정된 위치에서 전원과 인터넷에 연결되어 있는 기기와 달리, 모바일은 계속 변하는 환경에 노출되어 있다. 따라서 모바일 환경에 적합한 기술을 선택하는 것이 중요한데, FCM이 최고의 선택이라고 장담할 수는 없지만, 가장 대중적인 선택임에는 틀림없다. 

<div class="spacer">• • •</div>

이번 포스트의 예제 프로젝트는 [https://github.com/appkr/fcm-scratchpad](https://github.com/appkr/fcm-scratchpad)에 공개되어 있다. 이 포스트에서 사용한 포스트맨 콜렉션은 [https://raw.githubusercontent.com/appkr/fcm-scratchpad/master/docs/fcm-scratchpad.postman_collection.json](https://raw.githubusercontent.com/appkr/fcm-scratchpad/master/docs/fcm-scratchpad.postman_collection.json)에서 받을 수 있다.
