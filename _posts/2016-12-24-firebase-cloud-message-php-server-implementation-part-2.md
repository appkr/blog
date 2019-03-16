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
image: //blog.appkr.dev/images/images/2016-12-24-img-01.png
---

<div class="panel panel-default">
  <div class="panel-body">
    <p class="lead">이 포스트는 2016년 12월 24일 첫 포스트 이후, 2017년 1월, 2018년 7월, 2018년 11월 총 세차례에 걸쳐 완전히 다시 썼으며, 예제 코드 또한 변경되었습니다.</p> 
    <p class="lead">최종 리팩토링의 가장 큰 변경은 기존에 사용하던 <code class="highlighter-rouge">brozot/laravel-fcm</code> 패키지를 완전히 버리고, <code class="highlighter-rouge">Guzzle</code>로 직접 구현했다는 점입니다.</p>
  </div>
</div>

**FCM(Firebase Cloud Message)은 Android, iOS, Web 등의 클라이언트에 푸쉬 메시지를 보내기 위한 서비스**다. 과거 GCM(Google Cloud Message)이 진화한 것이다.

![Firebase Logo](https://1.bp.blogspot.com/-YIfQT6q8ZM4/Vzyq5z1B8HI/AAAAAAAAAAc/UmWSSMLKtKgtH7CACElUp12zXkrPK5UoACLcB/s1600/image00.png)

[지난 1부](/work-n-play/firebase-cloud-message-php-server-implementation-part-1/)에서는 푸쉬 메시지를 받을 모바일 단말 애플리케이션이 구글 Fcm 서버로 부터 받은 고유 식별 토큰을 애플리케이션 서버로 전달해 등록하는 과정을 구현했다. 이번 포스트에서는 등록한 토큰으로 푸쉬 메시지를 쏘는 기능을 구현한다. 

<!--more-->
<div class="spacer">• • •</div>

## 1. 설계

[![](/images/2016-12-24-img-00.png)](/images/2016-12-24-img-00.png)

<small>그림 원본: https://docs.google.com/presentation/d/11kNXkxA0kXoO-ayQHFa2yCOAIch4CEofXgf013aywFM/edit?usp=sharing</small>

각 클래스의 역할은 아래와 같다.

#### FcmServiceProvider
- `FcmDeviceRepository` 인터페이스에 대한 구체 클래스인 `EloquentFcmDeviceRepository`를 등록한다.
- `FcmHandler` 조립을 위한 공식을 등록한다.

#### FcmHandler
- Fcm 메시지를 전송한다.
- 메시지 전달을 요청한 push_service_id가 바뀌었으면, `FcmDeviceRepository`를 이용해서 `Device` 모델을 업데이트한다.
- 메시지 전달에 실패했을 때, 재전송하거나, 유효하지 않은 push_service_id라고 응답 받으면, `FcmDeviceRepository`를 이용해서 `Device` 모델을 삭제한다.
- 로그를 남긴다.

#### FcmDeviceRepository, EloquentFcmDeviceRepository
- Fcm 서버의 응답에 따라, `Device` 모델을 업데이트하거나 삭제한다.

#### DownstreamResponse
- `GuzzleClient`의 HTTP 응답을 파싱하여, 의미를 담고 있고 사용하기 편리한 형태로 가공한 데이터 객체다.
- `brozot/laravel-fcm`에서 제공하는 클래스를 그대로 인용했다.

#### User, Device
- A User has many devices. A Device belongs to a User. 

## 2. 환경변수 등록

이전 포스트에서 설명했듯이 Firebase 콘솔로 부터 받은 **서버 키**와 **발신자 ID**를 Fcm 서버에 요청할 때마다 제출해야 정상적으로 통신이된다. `.env` 파일에 환경 변수를 먼저 등록하고, 라라벨 config를 통해 이 값들에 접근할 수 있도록 하자.

```bash
# .env

FCM_SERVER_KEY=AAAAMqBU...OJy1Dw
FCM_SENDER_ID=217...581
```

```php
<?php // config/fcm.php

return [
    'server_key' => env('FCM_SERVER_KEY'),
    'sender_id' => env('FCM_SENDER_ID'),
    'server_send_url' => 'https://fcm.googleapis.com',
    'timeout' => 30, // in second
];
```

## 3. 서비스 프로바이더

```php
 1 <?php // app/Providers/FcmServiceProvider
 2 
 3 namespace App\Providers;
 4 
 5 use App\Services\EloquentFcmDeviceRepository;
 6 use App\Services\FcmDeviceRepository;
 7 use App\Services\FcmHandler;
 8 use GuzzleHttp\Client as GuzzleClient;
 9 use Illuminate\Contracts\Config\Repository as ConfigRepository;
10 use Illuminate\Contracts\Foundation\Application;
11 use Illuminate\Support\ServiceProvider;
12 use Psr\Log\LoggerInterface;
13 
14 class FcmServiceProvider extends ServiceProvider
15 {
16     public function register()
17     {
18         $this->bindFcmDeviceRepository();
19         $this->bindFcmHandler();
20     }
21 
22     private function bindFcmDeviceRepository()
23     {
24         $this->app->bind(FcmDeviceRepository::class, EloquentFcmDeviceRepository::class);
25     }
26 
27     private function bindFcmHandler()
28     {
29         $this->app->bind(FcmHandler::class, function (Application $app) {
30             $config = $app->make(ConfigRepository::class)->get('fcm');
31 
32             $httpClient = new GuzzleClient([
33                 'base_uri' => $config['server_send_url'],
34                 'headers' => [
35                     'Authorization' => "key={$config['server_key']}",
36                     'Content-Type' => 'application/json',
37                     'project_id' => $config['sender_id'],
38                 ],
39                 'timeout' => $config['timeout'],
40             ]);
41             $deviceRepo = $app->make(FcmDeviceRepository::class);
42             $logger = $app->make(LoggerInterface::class);
43 
44             return new FcmHandler($httpClient, $deviceRepo, $logger);
45         });
46     }
47 }
```

- 24: `FcmDeviceRepository`를 요청하면, `EloquentFcmDeviceRepository`를 조립해서 제공한다.
- 32~40: Fcm 서버와 통신하기위한 HTTP 클라이언트를 조립한다.
- 44: `FcmHandler` 객체가 동작하기 위해 필요한 의존 객체를 생성자로 주입하고 생성된 최종 객체를 반환한다.  

## 4. 디바이스 리포지토리

인터페이스를 만들지 말지는 개발자의 선택이다. 

이 예제에서 구현한 엘로퀀트를 이용하는 리포지토리를 대신하는 다른 리포지토리를 런타임에 선택해서 사용하려면 인터페이스를 만들고, 인터페이스를 구현하는 구체 클래스를 추가하는 것이 좋다. 가령, 서비스 프로바이더에 조건문을 걸어 환경에 따라 서로 다른 리포지토리를 사용하는 용례를 생각해 볼 수 있다(`if (App::environment('local')) { return new NullRepository; }`).

```php
 1 <?php // app/Services/FcmDeviceRepository.php
 2 
 3 namespace App\Services;
 4 
 5 interface FcmDeviceRepository
 6 {
 7     public function updateFcmDevice(string $oldId, string $newId);
 8     public function deleteFcmDevice(string $deprecatedId);
 9 }
```

```php
 1 <?php // app/Services/EloquentFcmDeviceRepository.php
 2 
 3 namespace App\Services;
 4 
 5 use App\Device;
 6 use DB;
 7 
 8 class EloquentFcmDeviceRepository implements FcmDeviceRepository
 9 {
10     public function updateFcmDevice(string $oldId, string $newId)
11     {
12         $device = Device::where('push_service_id', $oldId)->first();
13         if ($device === null) {
14             return;
15         }
16 
17         $device->push_service_id = $newId;
18 
19         DB::transaction(function () use ($device) {
20             $device->save();
21         });
22     }
23 
24     public function deleteFcmDevice(string $deprecatedId)
25     {
26         $device = Device::where('push_service_id', $deprecatedId)->first();
27         if ($device === null) {
28             return;
29         }
30 
31         DB::transaction(function () use ($device) {
32             $device->delete();
33         });
34     }
35 }
```

- 12: Fcm 서버에서 응답받은 `$oldId`를 가진 `Device` 모델을 찾는다.
- 17: Fcm 서버에서 응답받은 `$newId`로 교체한다.
- 20: 저장한다.
- 24~34: 마찬가지로 Fcm 서버가 유효하지 않다고 응답해준 `$deprecatedId`를 가진 `Device` 모델을 찾아 삭제한다.

## 5. Fcm 핸들러

```php
  1 <?php // app/Services/FcmHandler.php
  2 
  3 namespace App\Services;
  4 
  5 use Exception;
  6 use GuzzleHttp\Client as GuzzleClient;
  7 use GuzzleHttp\Psr7\Request;
  8 use Psr\Log\LoggerInterface;
  9 
 10 class FcmHandler
 11 {
 12     const MAX_TOKEN_PER_REQUEST = 1000;
 13     const API_ENDPOINT = 'fcm/send';
 14 
 15     private $httpClient;
 16     private $deviceRepo;
 17     private $logger;
 18 
 19     private $receivers;
 20     private $message;
 21     private $retryIntervalInUs = 100000; // 100ms
 22     private $maxRetryCount = 3;
 23     private $retriedCount = 0;
 24 
 25     public function __construct(
 26         GuzzleClient $httpClient,
 27         FcmDeviceRepository $deviceRepo,
 28         LoggerInterface $logger
 29     ) {
 30         $this->httpClient = $httpClient;
 31         $this->deviceRepo = $deviceRepo;
 32         $this->logger = $logger;
 33     }
```

- 15~17: 생성자를 통해 받은 멤버 필드들이다.
- 19~20: 개별 메시지 전송에 필요한 수신자와 메시지 본문을 담을 필드다.
- 21~23: 메시지 재전송등의 제어를 위해 사용할 필드다. 

```php
 35     public function sendMessage()
 36     {
 37         if (count(array_filter($this->receivers)) === 0) {
 38             $this->logProgress('푸쉬 알림을 전송을 건너 뜁니다: 수신자가 없습니다.');
 39             return;
 40         }
 41 
 42         if ($this->isInitialRequest()) {
 43             $this->logProgress('푸쉬 알림을 전송합니다.', [
 44                 'receivers' => $this->receivers,
 45                 'message' => $this->message,
 46             ], 'debug');
 47         }
 48 
 49         try {
 50             if (count($this->receivers) > self::MAX_TOKEN_PER_REQUEST) {
 51                 $response = null;
 52                 foreach (array_chunk($this->receivers, self::MAX_TOKEN_PER_REQUEST) as $chunk) {
 53                     $responsePartial = $this->_sendMessage($chunk);
 54                     if (!$response) {
 55                         $response = $responsePartial;
 56                     } else {
 57                         $response->merge($responsePartial);
 58                     }
 59 
 60                     usleep(1);
 61                 }
 62             } else {
 63                 $response = $this->_sendMessage($this->receivers);
 64             }
 65 
 66             $this->updatePushServiceIdsIfAny($response);
 67             $this->handleDeliveryFailureIfAny($response);
 68 
 69             $this->logProgress("푸쉬 알림을 전송했습니다.", [
 70                 'receiver' =>$this->receivers,
 71             ]);
 72         } catch (Exception $e) {
 73             $this->logProgress("푸쉬 알림을 전송하지 못헸습니다: {$e->getMessage()}", [
 74                 'receiver' => $this->receivers,
 75             ], 'error');
 76             throw $e;
 77         }
 78     }
```

- 42~47: 재전송이 아닌 최초 요청일때, 로그를 남긴다.
- 50: Fcm 스펙이 한 요청당 1,000개의 수신자까지만 메시지를 전송할 수 있으므로, 제한 개수를 넘을 때는 청크로 나누어 처리한다.
- 52~53: 청크로 나누었기 때문에, 청크에 대한 응답을 합치는 구문이다. 가령 1,500개 수신자에게 메시지를 보낸다면, 1,000개 짜리 청크에 대한 응답을 `$response` 변수에 담아두고, 나머지 500개 청크에 대한 응답을 `$response`에 머지하는 방식이다. 
- 65~66: 처리 방식(청크 vs. 한방)에 무관하게, Fcm 서버의 응답을 담고 있는 `$response` 변수를 이용해서, push_service_id의 업데이트 또는 삭제 작업을 다른 함수에 위임한다.

```php
 80     public function setReceivers(array $receivers)
 81     {
 82         $this->receivers = $receivers;
 83     }
 84 
 85     public function setMessage(array $message)
 86     {
 87         $this->message = $message;
 88     }
```

- 메시지를 전송(수신)할 push_service_id와 보낼 메시지를 셋팅하는 함수다.

```php
 90     private function _sendMessage(array $tokens)
 91     {
 92         $request = $this->getRequest($tokens);
 93         $guzzleResponse = $this->httpClient->send($request);
 94 
 95         return new DownstreamResponse($guzzleResponse, $tokens);
 96     }
 97 
 98     private function getRequest(array $tokens)
 99     {
100         // 'to' for single receiver,
101         // 'registration_ids' for multiple receivers
102         $httpBody = \GuzzleHttp\json_encode([
103             'registration_ids' => $tokens,
104             'notification' => null,
105             'data' => $this->message,
106         ]);
107 
108         return new Request('POST', self::API_ENDPOINT, [], $httpBody);
109     }
```

- 92: `getRqeust()` 함수에게 요청 객체 생성을 위임한다.
- 93: 라라벨 컨테이너가 서비스 프로바이더에 등록해둔 조립 공식에 따라 만들어준, `$httpClient: GuzzleClient` 객체를 이용해서 Fcm 서버에 HTTP 요청을 보내고, 응답을 `$guzzleResponse` 변수에 담았다.  
- 95: Fcm 서버의 응답(`$guzzleResponse`)과 수신자 목록을 이용해서 `DownstreamResponse` 데이터 객체를 만들고 반환한다. 63, 66~67에서 봤던 `$response` 변수가 바로 여기서 반환한 `DownstreamResponse` 객체다. 

```php
111     private function updatePushServiceIdsIfAny(DownstreamResponse $response)
112     {
113         if ($response->numberModification() <= 0) {
114             return;
115         }
116 
117         /**
118          * @var array $pushServiceIdsToModify {
119          *     @var string $oldPushServiceId => string $newPushServiceId
120          * }
121          */
122         $pushServiceIdsToModify = $response->tokensToModify();
123 
124         // 메시지는 성공적으로 전달되었습니다.
125         // 단말기 공장 초기화 등의 이유로 구글 Fcm 서버에 등록된 registration_id가 바뀌었습니다.
126         $this->logProgress('구글 서버와 push_service_id 를 동기화합니다.', [
127             'push_service_id_to_modify' => $pushServiceIdsToModify
128         ]);
129 
130         foreach ($pushServiceIdsToModify as $oldPushServiceId => $newPushServiceId) {
131             $this->deviceRepo->updateFcmDevice($oldPushServiceId, $newPushServiceId);
132         }
133     }
```

- 131: 라라벨 컨테이너가 주입해준 `EloquentFcmDeviceRepository` 객체를 여기서 사용한다. 이미 설명했듯이, 리포지토리의 `updateFcmDevice()` 함수를 호출해서, push_service_id를 업데이트 작업을 지시하는 부분이다. 


```php
135     private function handleDeliveryFailureIfAny(DownstreamResponse $response)
136     {
137         if ($response->numberFailure() <= 0) {
138             return;
139         }
140 
141         $pushServiceIdsToDelete = $response->tokensToDelete();
142         if (! empty($pushServiceIdsToDelete)) {
143             // 해당 registration_id를 가진 단말기가 구글 Fcm 서비스에 등록되어 있지 않습니다.
144             $this->logProgress('사용불가한 push_service_id 를 삭제합니다.', [
145                 'push_service_ids_to_delete' => $pushServiceIdsToDelete
146             ]);
147 
148             foreach ($pushServiceIdsToDelete as $pushServiceIdToDelete) {
149                 $this->deviceRepo->deleteFcmDevice($pushServiceIdToDelete);
150             }
151         }
152 
153         $pushServiceIdsToRetry = $response->tokensToRetry();
154         if (! empty($pushServiceIdsToRetry)) {
155             if ($this->isFinalRetry()) {
156                 // 재시도 했지만 메시지 전송에 실패했습니다.
157                 throw new Exception();
158             }
159 
160             // 최대 3회, 1회는 기본값, 다음 루프는 2회, 3회까지 실행됨.
161             $this->retriedCount = $this->retriedCount + 1;
162             // (최초 1회 200밀리초 뒤 실행, 2회 400밀리초 뒤, 3회 800밀리초 뒤) -> 프로세스가 총 1.4초동안 실행됨.
163             // @see https://firebase.google.com/docs/cloud-messaging/http-server-ref?hl=ko#error-codes
164             $this->retryIntervalInUs = $this->retryIntervalInUs * 2;
165 
166             usleep($this->retryIntervalInUs);
167 
168             $this->logProgress("{$this->getOrdinalRetryCount()} 재전송 시도합니다.", [
169                 'retried_count' => $this->retriedCount,
170                 'push_service_ids_to_retry' => $pushServiceIdsToRetry,
171             ]);
172 
173             $this->receivers = $pushServiceIdsToRetry;
174             $this->sendMessage();
175         }
176     }
```

- 우선 `handleDeliveryFailureIfAny()` 함수를 두가지 일을 한다. 이렇게 구현된 이유는 뒤에 설명할 Fcm 서버의 응답 스펙과 관련이 있다. 두 가지 일이란; 
- 141~151: 첫째 디바이스 리포지토리에게 유효하지 않는 push_service_id 삭제 지시를 한다. 
- 153~175: 둘째, 재전송이 필요한 push_service_id 들에 대해 2번 더 전송 시도한다. 
- 160~161: 지금까지 `$retriedCount` 변수에는 `0`이 담겨 있었고, 이 라인에서 `1`을 더했다.
- 162~164: [Exponential Backoff](https://en.wikipedia.org/wiki/Exponential_backoff) 구현이다. 방금 실패했으면 재시도해도 실패할 가능성이 있으므로, 재시도 주기를 점진적으로 늘려가며 재시도하는 로직이다.
- 173~174: 수신자(`$receivers`) 변수를 실패한 push_service_id[]로 덮어 쓰고, `sendMessage()` API를 다시 호출한다. 또 실패하면 이 함수에 들어오게 되고, `$retriedCount`, `$retryIntervalInUs` 등의 제어 변수들이 조정되고, 또 재시도하게 될 것이다.

```php
178     private function isInitialRequest()
179     {
180         return $this->retriedCount === 0;
181     }
182 
183     private function isFinalRetry()
184     {
185         return $this->retriedCount === $this->maxRetryCount;
186     }
187 
188     private function getOrdinalRetryCount()
189     {
190         switch ($this->retriedCount) {
191             case 1:  return '첫번째';
192             case 2:  return '두번째';
193             case 3:  return '세번째';
194             default: return '';
195         }
196     }
197 
198     private function logProgress(string $message, $context = [], string $level = 'debug')
199     {
200         $this->logger->log($level, "[FcmHandler] {$message}", $context);
201     }
202 }
```

- 나머지는 모두 헬퍼 함수들이다.

## 6. 메시지 보내기 테스트

팅커를 이용해서 구현한 클래스가 잘 작동하는지 확인해보자. 유효하지 않은 단말기 토큰이므로 실패가 떨어지는 것은 당연하다. 우리의 PHP 애플리케이션 서버에서 생성한 메시지가 Fcm 서버를 거쳐 단말기에게 전달되는 전체 과정을 확인하지는 못했지만, 적어도 Fcm 서버와 통신이 된다는 것은 확인했다. 

```bash
# In terminal session 1
$ php artisan tinker
>>> $handler = App::make(App\Services\FcmHandler::class);
=> App\Services\FcmHandler {#733}

>>> $handler->setReceivers([str_repeat('a', 152)]);
=> null

>>> $handler->setMessage(['Lorem' => 'Ipsum']);
=> null

>>> $handler->sendMessage();
=> null
```

```bash
# In terminal session 2
$ tail -f storage/logs/laravel.log
[2018-11-13 14:27:11] local.DEBUG: [FcmHandler] 푸쉬 알림을 전송합니다. {"receivers":["aa..um"}}
[2018-11-13 14:27:11] local.DEBUG: [FcmHandler] 사용불가한 push_service_id 를 삭제합니다. {"push_service_ids_to_delete":["aa..aa"]}
[2018-11-13 14:27:11] local.DEBUG: [FcmHandler] 푸쉬 알림을 전송했습니다. {"receiver":["aa..aa"]}
```

## 7. 컨트롤러 구현

Fcm 메시지는 웹 페이지, 크론, 이벤트 핸들러, 큐 잡 등등 애플리케이션 어디서든 보낼 수 있다. 이 포스트에서는 웹 페이지를 통해서 메시지를 보낸다고 가정하고 컨트롤러(간결함을 위해 라우트 정의 파일 이용)를 만들어본다. 1부에서 만든 단말기 등록 API를 이용해서 1번 User의 단말기가 등록되어 있다고 가정한다.

```php
<?php // routes/api.php

Route::post('fcm_test', function (App\Services\FcmHandler $fcmHandler) {
    $user = App\User::find(1);
    $fcmHandler->setReceivers($user->getPushServiceIds());
    $fcmHandler->setMessage([
        'message' => 'Hello Fcm',
    ]);
    $fcmHandler->sendMessage();
    
    return new Illuminate\Http\JsonResponse(null, 200);
});
```

`$user->getPushServiceIds()`는 모델에 정의한 헬퍼 함수이며, 다음과 같다.

```php
<?php // app/User.php

class User extends Authenticatable
{
    // ...

    public function getPushServiceIds()
    {
        return $this->devices->pluck('push_service_id')->all();
    }
}
```

> 본문에 언급되지 않은 코드는 [예제 프로젝트의 풀 리퀘스트](https://github.com/appkr/fcm-scratchpad/pull/2/files)에서 확인할 수 있다.

## 8. 푸쉬 메시지 요청에 대한 Fcm 서버 응답의 이해

`DownstreamResponse` 클래스를 이해하려면, [Fcm 문서](https://firebase.google.com/docs/cloud-messaging/server#response)에 명시된 Fcm 서버의 응답 메시지를 이해해야 하는데... 아래는 총 6개의 단말기에 푸쉬 메시지를 보냈을 때 Fcm 서버의 응답 예제이다. 이 예제를 통해서 Fcm 응답 스펙을 이해할 수 있다. 

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

우선 `results.message_id`가 있는 메시지들은 성공한 것이다. `DownstreamResponse` 클래스의 메서드들도 다음 표에 정리했다.

응답 필드|라이브러리의 메서드(`DownstreamResponse`)|설명|예제 응답 번호(zero-index)
---|---|---
`success`|`numberSuccess()`|푸쉬 메시지 전달에 성공한 건수|0,3,4
`failure`|`numberFailure()`|푸쉬 메시지 전달에 실패한 건수|1,2,5
`canonical_ids`|`numberModification()`|단말기의 고유 식별 토큰이 변경된 건수|4
&nbsp;|`tokensToDelete()`|애플리케이션 서버에서 삭제할 토큰의 목록|5
&nbsp;|`tokensToModify()`|애플리케이션 서버에서 업데이트할 토큰의 목록|4
&nbsp;|`tokensToRetry()`|애플리케이션 서버에서 재 전송해야 하는 토큰의 목록|1
&nbsp;|`tokensWithError()`|에러가 난 이유 목록|&nbsp;


## 9. 결론

2부에 걸친 포스트를 통해 모바일 단말기에 Firebase Cloud Message를 보내기 위한 PHP 애플리케이션 서버를 구현하는 방법을 다루었다. 3부를 쓸 기회가 있다면 빠진 퍼즐 조각인 모바일 앱 부분을 소개할 예정이다.

고정된 위치에서 전원과 인터넷에 연결되어 있는 기기와 달리, 모바일은 계속 변하는 환경에 노출되어 있다. 따라서 모바일 환경에 적합한 기술을 선택하는 것이 중요한데, Fcm이 최고의 선택이라고 장담할 수는 없지만, 가장 대중적인 선택임에는 틀림없다. 

<div class="spacer">• • •</div>

이번 포스트의 **예제 프로젝트는 [https://github.com/appkr/fcm-scratchpad](https://github.com/appkr/fcm-scratchpad)에 공개**되어 있다. 

**포스트맨 콜렉션은 [https://raw.githubusercontent.com/appkr/fcm-scratchpad/master/docs/fcm-scratchpad.postman_collection.json](https://raw.githubusercontent.com/appkr/fcm-scratchpad/master/docs/fcm-scratchpad.postman_collection.json)**에서 받을 수 있다.

## 덧.

이 예제 프로젝트와 연동해서 작동하는 Android 예제 클라이언트를 brownsoo 님이 제공해 주셨습니다. 상세한 설명은 [https://github.com/brownsoo/fcm-scratchpad-android](https://github.com/brownsoo/fcm-scratchpad-android)를 참고해 주세요.

![Android Client Example](https://raw.githubusercontent.com/appkr/fcm-scratchpad/master/docs/image-04.png)
