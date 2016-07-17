---
layout: post-minimal
title: '"휙~" 리얼 타임 라라벨 데모 프로젝트' 
date: 2016-07-15 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- laravel
- websocket
---

**'[휙~](https://github.com/appkr/whik)'** 라라벨은 도메인 이벤트를 클라이언트에게 브로드캐스트할 수 있는 기능을 제공한다. 5.2.39 기준으로 `pusher`, `redis`, `log` 등의 브로드캐스팅 드라이버를 지원한다. 이 데모에서는 라라벨이 **'휙~'**하고 메시지를 던지면, Socket.io가 접속된 모든 클라이언트에게 **'휙~'**하고 메시지를 전파한다. 

**언제 어떻게 쓸 수 있나?** 새로운 댓글이 작성되면 같은 댓글 목록을 보고 있는 사용자에게 새 댓글을 알리거나, 지금 서비스에 접속된 모든 사용자에게 푸시 알림을 보내는 등으로 사용할 수 있다. 

이 포스트는 데모 프로젝트를 복붙으로 따라해보기 위한 명령 및 코드 목록을 담고 있다. ***각 절의 작동 원리는 읽지 말고, 전체 동작을 한번 확인할 것을 권장한다.***

1. *데모 환경 준비_* 오늘 AWS에 인수된 클라우드9을 이용한다. 
2. *SocketChat_* Socket.io에서 제공하는 채팅 예제 프로젝트를 구동해 본다.
3. *Redis_* 라라벨과 Socket.io간의 메시지 중계자로 Redis를 이용한다.
4. *Broadcast_* 라라벨의 브로드캐스트 기능을 이용해 본다.

<small>* 웹 페이지의 DOM 조작을 위해 Vue.js[^1] 라이브러리를 이용할 것이다.</small>

이 프로젝트는 라라캐스트의 [Real-time Laravel with Socket.io](https://laracasts.com/series/real-time-laravel-with-socket-io) 시리즈를 보고, 필자 나름대로 해석하고 적용한 결과물이다.

<!--more-->
<div class="spacer">• • •</div>

## 0. 용어 이해

라라벨, Redis, Socket.io 등에서 계속 비슷한 용어를 사용하므로, 이 포스트를 이용해하는데 필요한 용어를 먼저 정리해 본다.

라라벨의 이벤트 시스템, Redis, Socket.io 서버와 클라이언트는 모두 PubSub(Publisher, Subscriber) 메시징 패러다임[^2]의 구현체다. 텔레비전 방송을 생각해 보면 쉽다. 방송국(Publisher)은 수신자(Subscriber)가 누군지 모른채 무작정 메시지를 브로드캐스트한다. 그리고 각 가정에서는 텔레비전을 켜고 관심있는 채널에 맞추고 방송국에서 송출한 메시지를 수신한다.

채널은 발신자와 수신자간의 파이프라고 생각하자. 발신자는 무차별적으로 여러 개의 파이프에 데이터를 흘려보내고, 수신자는 여러 개의 파이프 중 원하는 몇 개의 파이프에만 연결하여 데이터를 받는다. 이벤트 시스템 컨텍스트에서는 이벤트 채널(이 포스트 4절의 이벤트 클래스)과 이벤트 데이터라고 하고, PubSub 관점에서는 채널과 메시지라고 같다. 모두 같은 개념이다.

PubSub 패턴은 두 시스템(발신자와 수신자)간의 결합도를 낮추어 애플리케이션의 확장성을 제공한다. 이 포스트 3절에서 라라벨과 자바스크립트간의 메신저로 Redis를 사용했는데, Redis의 PubSub 기능이 없었다면 PHP와 자바스크립트가 쉽게 통신할 수 있었을까? 

## 1. 데모 환경 준비

[클라우드9](https://c9.io)를 이용할텐데, 계정이 없다면 만든다. 대시보드에서 <kbd>Create a new workspace</kbd>를 눌러 새 PHP 워크스페이스(프로젝트)를 만든다. 

[![Cloud 9, Create a new workspace](/images/2016-07-15-img-01.png)](/images/2016-07-15-img-01.png)

워크스페이스 이름은 아무렇게나 정해도 된다. 워크스페이스가 생성되면 클라우드9 콘솔에서 다음 명령을 수행한다. 

```sh
# 기본 생성된 파일들을 삭제한다.
you:~/workspace $ rm README.md php.ini hello-world.php

# 프로젝트를 복제한다.
you:~/workspace $ git clone https://github.com/appkr/whik.git

# .으로 시작하는 파일을 사용할 수 있도록 셸 옵션을 활성화한다.
you:~/workspace $ shopt -s dotglob

# 복제한 프로젝트를 워크스페이스 루트로 옮긴다.
you:~/workspace $ mv whik/* ./ 

# 복제한 프로젝트 디렉터리는 이제 필요없으므로 삭제한다. 
you:~/workspace $ rm -rf whik 
```

`public` 디렉터리를 웹 서버의 Document Root로 변경하기 위해 웹 서버 설정을 변경한다(`$ sudo nano /etc/apache2/sites-enabled/001-cloud9.conf`)

```sh
# /etc/apache2/sites-enabled/001-cloud9.conf

# 이렇게 생긴 문장을
DocumentRoot /home/ubuntu/workspace

# 이렇게 바꾸고 저장한다. nano로 열었다면 ctrl+x를 누른 후 y, 엔터를 누른다.
DocumentRoot /home/ubuntu/workspace/public
```

설정을 바꾸었으니 아파치 웹 서버를 재실행한다.

```sh
you:~/workspace $ sudo service apache2 restart
```

이제 라라벨 프로젝트가 의존하는 라이브러리를 설치하고, 애플리케이션을 초기화한다. 라라벨 프로젝트를 복제했을 때 으례히 실행하는 명령셋이다.

```sh
# 라라벨 프로젝트의 필요 라이브러리를 설치한다.
you:~/workspace $ composer install
 
# 웹 서버 사용자(라라벨 프레임워크)에게 파일 시스템에 쓰기 권한을 부여한다. 
you:~/workspace $ chmod -R 775 storage bootstrap/cache

# 라라벨이 사용할 전역 환경 변수 설정 파일을 생성한다.
you:~/workspace $ cp .env.example .env 

# 암호화 시드 키를 생성한다.
you:~/workspace $ php artisan key:generate 
```

## 2. SocketChat

소스 코드의 `public/socketchat`에서 [Socket.io에서 제공하는 채팅 예제 프로젝트](http://socket.io/get-started/chat/)를 경험해 볼 수 있다. 리얼 타임 웹의 가능성을 엿보기 위한 첫 단계다.

### 2.1. 코드 수정

소스 코드에서 각자의 클라우드9 접속 주소를 반영한다.

```javascript
// public/socketchat/index.html

// 이렇게 생긴 라인을
var socket = io('https://whik-appkr.c9users.io:8082');

// 각자의 접속 주소에 맞게 변경한다. 8082는 그대로 둔다.
var socket = io('https://your-c9-url:8082');
```

### 2.2. 실험 준비

클라우드9 콘솔에서 다음 명령을 실행한다.

```sh
you:~/workspace $ cd public/socketchat

# 필요한 Node 라이브러리를 설치한다.
you:~/workspace/public/socketchat $ npm install --only=prod

# Socket.io 서버를 실행한다.
you:~/workspace/public/socketchat $ npm start  
```

### 2.3. 실험

클라우드9 IDE 화면에서 <kbd>Run Project</kbd> 버튼을 누른다. `http://your-c9-url/socketchat`을 여러 개의 브라우저로 열어 채팅이 동작하는지 확인한다.

[![Socketchat in action](/images/2016-07-15-img-02.gif)](/images/2016-07-15-img-02.gif)

### 2.4. 작동 원리

Socket.io는 리얼 타임 웹을 위한 자바스크립트 라이브러이다. 웹소켓을 기본으로 사용하고, 웹소켓을 사용할 수 없을 때는 XHR 폴링 등으로 폴백해서, Socket.io 라이브러리를 사용하는 클라이언트와 서버간에 통신할 수 있도록 한다. 

웹소켓은 말그대로 소켓이다. 서버와 클라이언트가 연결을 계속 유지하면서, 풀듀플렉스로 데이터를 스트리밍한다. 연결 협상을 할 때는 HTTP 프로토콜을 사용하지만, 웹소켓을 사용할 수 있으면 프로토콜을 업그레이드한다. 피어-투-피어는 아니다.

#### 2.4.1. 클라이언트의 메시지 전송

클라이언트에서 `socket.emit()` API로 서버에 메시지를 보낸다. 여기서 `chat.message`란 채널 이름을 기억해두자.

```javascript
// public/socketchat/index.html

var socket = io('https://whik-appkr.c9users.io:8082');

new Vue({
  // 중략...
  methods: {
    send: function (event) {
      socket.emit('chat.message', this.message);
      this.message = '';
    }
  }
});
```

#### 2.4.2. 서버의 메시지 브로드캐스트

클라이언트가 `chat.message` 채널로 보낸 메시지를 서버가 수신하면, 현재 접속된 모든 클라이언트에게 브로드캐스트한다. 이번에도 `emit()` API를 이용하고, 채널 이름을 인자로 넘겼다.

```javascript
// public/socketchat/index.js

var io = require('socket.io')(server);

io.on('connection', function (socket) {
  socket.on('chat.message', function (message) {
    io.emit('chat.message', message);
  });
});
```

#### 2.4.3. 클라이언트의 메시지 수신 및 소비

`socket.on(channel, callback)`은 제이쿼리에서 많이 봤던 `selector.on(event, callback)`과 같은 이벤트 리스너다. 서버의 브로드캐스트 메시지 중 `chat.message` 채널로 발행한 메시지가 있으면 콜백이 동작한다.    

```javascript
// public/socketchat/index.html

new Vue({
  ready: function () {
    socket.on('chat.message', function (message) {
      // 콜백 안에서 인자로 받은 message 소비
    }.bind(this));
  }
});
```

종합하면, 어떤 클라이언트가 `https://your-c9-url/socketchat` 페이지에서 채팅 메시지를 작성하면, 같은 페이지에 접속한 다른 모든 클라이언트는 메시지를 받아 DOM을 업데이트한다. 

[![Socketchat Block Diagram](/images/2016-07-15-img-05.jpg)](/images/2016-07-15-img-05.jpg)

Socket.io 공식 예제 대비 약간의 기능을 추가했다. 변경 내용은 [커밋 로그](https://github.com/appkr/whik/commit/6ea7551111c752bd3ee3ce5d56c2bd771be90400)에서 확인할 수 있다.

## 3. Redis

Redis는 라라벨과 Socket.io간의 메시지 중계자 역할을 한다.

### 3.1. 코드 수정

소스 코드에서 각자의 클라우드9 접속 주소를 반영한다.

```sh
# .env

# 이렇게 생긴 라인을 
APP_URL=https://whik-appkr.c9users.io

# 각자의 접속 주소로 변경한다.
APP_URL=https://your-c9-url
```

### 3.2. 실험 준비

필요한 라이브러리를 설치하고, 클라우드9 콘솔에서 `feature/redis` 태그로 체크아웃한다.

```sh
# 필요한 Node 라이브러리를 설치한다.
you:~/workspace (master) $ npm install --only=prod

# 체크아웃한다.
you:~/workspace (master) $ git checkout feature/redis
```

클라우드9에 Redis는 이미 설치되어 있다. Redis 서버를 구동하고, Socket.io 서버를 실행한다.

```sh
# Redis 시동
you:~/workspace (c124f70) $ sudo service redis-server restart

# Socket.io 서버 실행
you:~/workspace (c124f70) $ npm start
```

### 3.3. 실험

클라우드9 화면에서 <kbd>Run Project</kbd> 버튼을 누르고, `http://your-c9-url/pub`과 `http://your-c9-url/sub`을 각각 브라우저로 연다. `pub` 페이지를 새로고침할 때마다, `sub` 페이지의 목록이 하나씩 추가되는 것을 확인할 수 있다.

[![Socketchat in action](/images/2016-07-15-img-03.gif)](/images/2016-07-15-img-03.gif)

### 3.4. 작동 원리

2절의 SocketChat 예제에서는 Node.js Express 프레임워크로 라우팅과 뷰를 처리했다(`public/socketchat/index.js`). 이 수퍼 마이크로 서비스에는 Socket.io 서버를 포함하고 있고, Socket.io 서버는 단지 Socket.io 클라이언트들에게 메시지를 릴레이하는 역할만 수행했다.

그런데, 이번 절에서는 시나리오가 좀 다르다. 라라벨 애플리케이션이 Socket.io 라이브러리를 이용해서 클라이언트들과 통신하도록 해야 한다. 라라벨과 Socket.io를 서비스하는 Node.js는 서로 다른 애플리케이션이고, 둘 간에 메시지를 전달할 방법으로 Redis를 선택했다. 

Node.js 서비스는 Redis 서버에 미리 약속한 채널(`whik`)을 계속 바라보고 있다가, 라라벨이 Redis에 약속한 채널(`whik`)에 메시지를 발행하면, 발행된 값을 읽어서 Socket.io 클라이언트에게 브로드캐스트하는 식으로 동작한다.

#### 3.4.1. 라라벨의 Redis 레코드 발행

라라벨의 `pub`라우팅을 방문하면, Redis 서버의 `whik` 채널에 JSON 직렬화된 레코드를 쓰도록 작성했다.

```php
// app/Http/routes.php

<?php

Route::get('pub', function () {
    $data = [
        'event' => 'App\\Events\\NewUserCreated',
        'data' => factory(App\User::class)->make()->toArray(),
    ];

    Redis::publish('whik', json_encode($data));

    return response()->json($data, 200, [], JSON_PRETTY_PRINT);
});
```

#### 3.4.2. Node.js의 Redis 구독

```javascript
// socket.js

var Redis = require('ioredis');
var redis = new Redis();

redis.subscribe('whik');
```

#### 3.4.3. Socket.io 메시지 브로드캐스트

Redis를 통해 Node.js측에서 받은 데이터는 다음과 같은 JSON 구조를 가진다.

```javascript
{
  "event": "App\\Events\\NewUserCreated",
  "data": {
    "name": "foo",
    "email": "foo@bar.com"
  }
}
```

Redis에 새 레코드가 발행되면, Socket.io 서버는 `whik:App\\Events\\NewUserCreated` 채널로 접속된 모든 Socket.io 클라이언트에게 메시지를 브로드캐스트한다. 

```javascript
// socket.js

redis.on('message', function (channel, message) {
  message = JSON.parse(message);
  io.emit(channel + ':' + message.event, message.data);
});
```

#### 3.4.4. Socket.io 클라이언트의 메시지 소비

라라벨의 `pub` 라우트는 Socket.io 클라이언트를 담고 있는 뷰를 반환한다. 

```php
// app/Http/routes.php

<?php

Route::get('sub', function () {
    return view('welcome');
});
```

Socket.io 클라이언트는 서버로부터 받은 메시지를 소비한다. `data`에는 `{"name": "foo", "email": "foo@bar.com"}`이 담겨 있다. 

```javascript
// resources/views/welcome.blade.php

var socket = io('{{ env('APP_URL') }}' + ':8082');

new Vue({
  ready: function () {
    socket.on('whik:App\\Events\\NewUserCreated', function (data) {
      // 콜백 안에서 인자로 받은 data 소비
    }.bind(this));
  }
});
```
 
[![Laravel-Redis-Socket.io Block Diagram](/images/2016-07-15-img-06.jpg)](/images/2016-07-15-img-06.jpg)

상세 변경 내용은 [커밋 로그](https://github.com/appkr/whik/commit/c124f70862e23c92207e87265287cb83171493e8)에서 확인할 수 있다.

## 4. Broadcast

라라벨은 도메인 이벤트를 바로 클라이언트에게 브로드캐스팅할 수 있다. 아주 편리하게~

### 4.1. 실험 준비

수정할 코드는 없다. `feature/broadcast` 태그로 체크아웃만 하면 된다.

```sh
# 체크아웃한다.
you:~/workspace (master) $ git checkout feature/broadcast
```

3.2절과 같이 Redis 서버를 구동하고, Socket.io 서버를 실행한다.
         
```sh
# Redis 시동
you:~/workspace (5736550) $ sudo service redis-server restart

# Socket.io 서버 실행
you:~/workspace (5736550) $ npm start
```

### 4.2. 실험

3.3절과 똑같다. 클라우드9 화면에서 <kbd>Run Project</kbd> 버튼을 누르고, `http://your-c9-url/pub`과 `http://your-c9-url/sub`을 각각 연다. `pub` 페이지를 새로고침할 때마다, `sub` 페이지의 목록이 하나씩 추가되는 것을 확인할 수 있다.

### 4.3. 작동 원리

라라벨은 프레임워크 어디서든 도메인 이벤트를 발행할 수 있다. 라라벨에서 이벤트를 던지는 방법은 여러 가지인데, 여기서는 이벤트 클래스(이벤트 채널, Data Transfer Object)를 이용했다.

#### 4.3.1. 이벤트 클래스

이벤트 클래스는 아티즌 콘솔로 만든다(`$ php artisan make:event NewUserCreated`). 브로드캐스트 기능을 쓰려면, 이벤트 클래스에서 `ShouldBroadcast` 인터페이스를 구현하면 된다. 인터페이스의 메서드는 `broadcastOn()` 하나이고, 이 메서드에서는 브로드캐스트할 채널 이름을 반환하면 된다.

```php
// app/Events/NewUserCreated.php

<?php

namespace App\Events;

use Illuminate\Queue\SerializesModels;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;

class NewUserCreated extends Event implements ShouldBroadcast
{
    use SerializesModels;

    public $user;

    public function __construct(array $user)
    {
        $this->user = $user;
    }

    public function broadcastOn()
    {
        return ['whik'];
    }
}
```

#### 4.3.2. 이벤트 발행

이제 `NewUserCreated` 이벤트가 발생하면, 라라벨은 이벤트 클래스에서 `public`으로 선언된 이벤트 데이터(클래스 프로퍼티)를 자동으로 JSON 직렬화하고, `config/broadcasting.php`에 정의한 드라이버로 브로드캐스팅한다. 

```php
// app/Http/routes.php

<?php

Route::get('pub', function () {
    $user = factory(App\User::class)->make()->toArray();
    event(new App\Events\NewUserCreated($user));

    return $user;
});
```

나머지는 3절과 같다.

변경 내용은 [커밋로그](https://github.com/appkr/whik/commit/57365503be757253a0830590d74fe9e8ea855b0b)에서 확인할 수 있다.

## 5. 결론

리얼 타임 웹은 프런트와 백엔드를 아우르는 풀스택스러운 고오급 기술이고, 라라벨과 Redis를 이용하면 비교적 쉽게 구현할 수 있다. Pusher 드라이버를 이용하면 더 간단하다.

한 때 SPA(Single Page Application)가 유행했다. 그런데, SPA는... 

1. 처음 로드할 때 어마어마한 양의 자바스크립트를 받고 프로세싱해서 랜딩 페이지를 렌더링하는데까지 엄청난 시간이 걸리고, 
2. 프런트엔드에서 뷰를 렌더링하기 때문에 검색 엔진들은 크롤링해도 아무것도 없는 빈 페이지 밖에 없어 어쩔 줄 몰라했었고, 
3. 다른 서비스에서 리디렉션하여 돌아 왔을 때의 네비게이션 문제점 등 여러 가지 문제점을 안고 있었다. 

모바일 앱에는 적합하지만, 웹에는 적합하지 않다는 것이 중론이다. 이제 URL마다 페이지를 다시 로드 하는 전통적인 웹에다 Socket.io를 결합하는 방법으로 바뀌어 가고 있다(사실 꽤 됐다).

---

[^1]: [Vue.js](http://vuejs.org/)_제이쿼리를 대체할 수 있는 자바스크립트 라이브러리다. 앵귤러나 엠버처럼 풀 MVC 프레임워크가 아니라, 뷰 모델(DOM)만 건드리는 가벼운 녀석이다. 그럼에도 불구하고, 최신 프레임워크가 지원하는 양방향 데이터 바인딩등을 지원해서 개발 생산성이 높다. 2만개 이상의 스타를 가지고 있고, [깃허브 트렌딩에 계속 노미네이트](https://github.com/trending?since=monthly)되는 등 꼭 배워야할 라이브러리다.

[^2]: PubSub_ [https://en.wikipedia.org/wiki/Publish-subscribe_pattern](https://en.wikipedia.org/wiki/Publish-subscribe_pattern)
