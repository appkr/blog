---
layout: post-minimal
title: '리얼 타임 라라벨 데모 프로젝트' 
date: 2016-07-14 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- laravel
- websocket
---

**'[핑핑](https://github.com/appkr/pingping)'** 

라라벨이 **'핑'**하고 메시지를 던지면, Socket.io가 다시 모든 클라이언트에게 **'핑'**하고 메시지를 전파한다고 해서 **'핑핑'**이라 이름지었다. 이 프로젝트는 라라캐스트의 [Real-time Laravel with Socket.io](https://laracasts.com/series/real-time-laravel-with-socket-io) 시리즈를 보고, 필자 나름대로 해석하고 적용한 결과물이다.

어떤 사용자가 웹 페이지를 보던 중 도메인 모델을 변경하는 행동을 했을 때, 해당 도메인 모델을 표현하는 화면을 보고 있는 다른 클라이언트에게 모델의 변경 사실을 전파하려할 때 아주 유용하다. 가령 어떤 사용자가 `foo` 아티클을 보던 중 `bar` 댓글을 작성했다면, `foo` 아티클을 보던 다른 사용자의 UI에 `bar` 댓글을 밀어 넣을 수 있다.

라라벨과 Socket.io간의 통신을 위해 Pusher, Pubnub 등과 같은 3rd Party 서비스를 이용할 수도 있지만, 이 데모에서는 레디스를 이용해서 직접 구축한다. 그리고 웹 페이지의 DOM 조작을 위해 Vue.js[^1] 라이브러리를 이용할 것이다.

라라벨, 홈스테드(우분투 가상 머신), Node.js, Socket.io, 레디스 등을 전혀 몰라도,  2시간 정도를 투자해서 복사해서 붙여넣기만으로도 리얼 타입 웹을 경험해 볼 수 있다.

<!--more-->
<div class="spacer">• • •</div>

## 1. 프로젝트 설치

라라벨 설치 후 기본 셋팅을 한다.

```sh
# 프로젝트 복제
~$ git clone git@github.com:appkr/pingping.git
~$ cd

# 라라벨 구동을 위한 환경변수 파일 생성
~/pingping$ cp .env.example .env

# 라라벨의 파일 저장소에 쓰기 권한 부여
~/pingping$ chmod 775 storage bootstrap/cache

# 라라벨 프로젝트가 의존하는 라이브러리 설치
~/pingping$ composer install

# 라라벨이 사용할 암호화 시드 키 생성
~/pingping$ php artisan key:generate
```

데모를 위해서 홈스테드(Vagrant Box) 가상 머신과 `pingping.app` 이란 가상 호스트를 사용한다.

```sh
# /etc/hosts

192.168.10.10	pingping.app
```

홈스테드 설치는 [공식 매뉴얼](https://laravel.com/docs/homestead)([한글판](https://laravel.kr/docs/homestead))을 참고한다.

## 2. SocketChat

`public/socketchat`에서 Socket.io에서 제공하는 채팅 예제 프로젝트를 경험해 볼 수 있다. 리얼 타임 웹의 기능을 엿보기 위해서 포함했다.

채팅 시나리오에서는 Socket.io 서버와 라라벨 서버간의 통신은 필요없다. 채팅 클라이언트가 Socket.io 서버에 메시지를 보내면, Socket.io 서버가 다른 클라이언트에게 메시지를 릴레이 하는 것이 전부이기 때문이다.

다음과 같이 실행해 볼 수 있다.

```sh
~/pingping$ cd public/socketchat

# 필요한 Node 라이브러리를 설치한다.
~/pingping/public/socketchat$ npm install

# Socket.io 서버를 실행한다.
~/pingping/public/socketchat$ npm start
```

브라우저에서 `http://localhost:3000`를 열어 확인한다.

[![](https://github.com/appkr/pingping/raw/master/public/images/socketchat-in-action.gif)](https://raw.githubusercontent.com/appkr/pingping/master/public/images/socketchat-in-action.png)

[Socket.io 채팅 예제](http://socket.io/get-started/chat/)에 다음 기능을 더 추가했다.

- 새로운 사용자가 들어오거나, 참가자가 브라우저를 닫을 때 안내 메시지 출력
- 채팅 메시지를 타이핑하기 시작하면, 타이핑하고 있다는 안내 메시지 출력

여기서는 라라벨을 사용하지 않고, 가벼운 익스프레스 프레임워크를 사용해 라우팅과 뷰를 처리했다. 클린 인스톨 대비 변경 내용은 [커밋 로그](https://github.com/appkr/pingping/commit/e46792ed3bd96152b6800ae4b53e97264da43d69)에서 확인할 수 있다.

- public/socketchat/index.html
- public/socketchat/index.js
- public/socketchat/package.json

## 3. 레디스

홈스테드 머신에는 레디스 서버가 이미 설치되어 동작하고 있다. 따라해 보려면 해당 릴리스로 체크아웃한다.

```sh
~/pingping$ git checkout redis
```

### 3.1. 서버 구동

먼저 `pingping.app` 가상 호스트로 사용하므로, 홈스테드에 사이트 매핑을 해줘야 한다.

```yaml
# ~/.homestead/Homestead.yaml

sites:
    - map: pingping.app
      to: /home/vagrant/sites/pingping/public
```

서버를 준비하고, 구동한다.

```sh
# 라라벨과 Node.js에서 레디스를 쓰기 위한 라이브러리를 설치한다.
~/pingping$ composer install && npm install

# 홈스테드 머신을 구동하고 SSH로 접속한다.
# 홈스테드 표준 설치 디렉터리는 ~/.homestead(={YOUR_HOMESTEAD_DIRECTORY})다.
# homestead 명령을 이용할 수 없다면, Vagrantfile이 있는 디렉터리에서 vagrant up, vagrant ssh를 이용해도 된다.
~/{YOUR_HOMESTEAD_DIRECTORY}$ homestead up
~/{YOUR_HOMESTEAD_DIRECTORY}$ homestead ssh

# 엔진엑스 사이트를 추가하고, 엔진엑스를 재시동한다.
vagrant@homestead:~$ serve pingping.app /home/vagrant/sites/pingping
vagrant@homestead:~$ sudo service nginx restart

# Socket.io 서버를 구동한다.
vagrant@homestead:~$ cd sites/pingping/
vagrant@homestead:~/sites/pingping$ npm start
```

### 3.2. 실험

브라우저 창 하나는 `http://pingping.app/pub`, 다른 하나는 `http://pingping.app/sub`을 연다. `pub` 페이지를 새로고침할 때마다, `sub` 페이지의 목록이 하나씩 추가되는 것을 확인할 수 있다.

[![](https://github.com/appkr/pingping/raw/master/public/images/redis-in-action.gif)](https://raw.githubusercontent.com/appkr/pingping/master/public/images/redis-in-action.png)

### 3.3. 작동 원리

(복붙으로 리얼 타임 웹의 느낌만 보려면, 이 절을 읽지 말라~) 라라벨에서 발생한 이벤트를 Socket.io 서버에 중계하기 위한 도구로 레디스를 사용한다. 작동 원리는 다음과 같다.

1.  라라벨이 레디스 이벤트를 발행한다.
2.  Socket.io는 레디스의 이벤트를 구독한다.
3.  레디스에 새로운 이벤트가 들어오면, Socket.io 서버는 레디스에서 받은 메시지를 접속된 모든 클라이언트에게 릴레이한다.
4.  Socket.io 클라이언트는 Socket.io 서버로 부터 받은 메시지를 소비한다(e.g. DOM 업데이트).

다음은 라라벨에서 이벤트를 발행하는 코드다.

```php
// app/Http/routes.php

<?php 

Route::get('pub', function () {
    $data = [
        'event' => 'NewUserCreated',
        'data' => factory(App\User::class)->make()->toArray()
    ];

    Redis::publish('pingping', json_encode($data));

    return response()->json($data, 200, [], JSON_PRETTY_PRINT);
});
```

다음은 Socket.io 서버가 레디스 이벤트를 구독하고, 접속되어 있는 클라이언트에게 메시지를 날리는 부분이다.

```javascript
// socket.js

var server = require('http').Server();
var io = require('socket.io')(server);
var Redis = require('ioredis');
var redis = new Redis();

redis.subscribe('pingping');

redis.on('message', function (channel, message) {
  message = JSON.parse(message);
  io.emit(channel + '.' + message.event, message.data);
});
```

다음은 클라이언트가 메시지 구독하고 소비하는 부분이다.

```html
<!-- // resources/views/welcome.blade.php -->

<script>
  var socket = io('http://pingping.app:3000');

  new Vue({
    el: '#app',
    data: {
      users: []
    },
    ready: function () {
      socket.on('pingping.NewUserCreated', function (data) {
        this.users.push(data);
      }.bind(this));
    }
  });
</script>
```

변경 내용은 [커밋 로그](https://github.com/appkr/pingping/commit/dfb6ae1b4acc6cae4b9dca8941e7439453358aae)에서 확인할 수 있다.

## 4. All Together (라라벨 브로드캐스트)

라라벨은 애플리케이션에서 발생하는 이벤트를 클라이언트에게 브로드캐스트 하는 기능을 이미 가지고 있다. 앞 절의 레디스와 동작이 달라질 것은 하나도 없고, 단지 코드만 조금 바뀐다.

따라해 보려면 최종 릴리스로 체크아웃한다.

```sh
~/pingping$ git checkout master
```

라라벨 기본 브로드캐스트 드라이버는 Pusher이다. Pusher는 3절에서의 레디스 설치, 라라벨 프로젝트에 `predis/predis` 추가, Node.js 프로젝트에 `ioredis` 추가 등의 내용을 대체해 준다. Pusher는 공짜 같아 보이지만, 금방 쿼타를 초과한다. 

`.env` 환경 변수 설정을 열고 레디스로 값을 바꿨다.

```sh
# .env

BROADCAST_DRIVER=redis
```

라라벨의 이벤트 시스템을 사용하도록 기존 코드를 살짝 바꿨다. 혹시 오해하실까봐 말씀드리면, 실전에서 이 코드는 컨트롤러 클래스에 작성한다.

```php
// app/Http/routes.php

<?php

Route::get('pub', function () {
    $user = factory(App\User::class)->make()->toArray();
    event(new App\Events\NewUserCreated($user));

    return $user;
});
```

이벤트 클래스를 작성했다. 뼈대 코드는 아티즌 명령으로 작성했다(`$ php artisan make:event NewUserCreated`).

```php
// app/Events/NewUserCreated.php

<?php

namespace App\Events;

use Illuminate\Queue\SerializesModels;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;

class NewUserCreated extends Event implements ShouldBroadcast
{ // 브로드캐스트하려면 ShouldBroadcast 인터페이스를 구현해야 한다.
    use SerializesModels;

    // public으로 선언된 프로퍼티만 브로드캐스트 된다.
    public $user;

    public function __construct(array $user)
    {
        $this->user = $user;
    }

    public function broadcastOn()
    {
        // 브로드캐스트 채널 이름이다. 여러 채널도 가능하다.
        return ['pingping'];
    }
}
```

결과는 3절과 똑같다. 상세 변경 내용은 [커밋 로그](https://github.com/appkr/pingping/commit/aaad42ecd6cc2f7dc92aa05072e0d1cb50a7f9ae)에서 확인할 수 있다.

## 5. 결론

리얼 타임 웹은 프런트와 백엔드를 아우르는 풀스택스러운 고오급 기술이고, 라라벨을 이용하면 비교적 쉽게 구현할 수 있다.

한 때 SPA(Single Page Application)가 유행했다. 그런데, SPA는 

1. 처음 로드할 때 어마어마한 양의 자바스크립트를 받고 프로세싱해서 랜딩 페이지를 렌더링하는데까지 엄청난 시간이 걸리고, 
2. 프런트엔드에서 뷰를 렌더링하기 때문에 검색 엔진들은 크롤링해도 아무것도 없는 빈 페이지를 어쩔 줄 몰라했었고, 
3. 다른 서비스에서 리디렉션하여 돌아 왔을 때의 네비게이션 문제점 등 여러 가지 문제점을 안고 있었다. 

모바일 앱에는 적합하지만, 웹에는 적합하지 않다는 것이 중론이다. 이제 URL마다 페이지를 다시 로드 하는 전통적인 웹 구현 방법에다 Socket.io(웹 소켓)를 결합한 하이브리드 구현 방법으로 바뀌어 가고 있다(사실 꽤 됐다).

---

[^1]: [Vue.js](http://vuejs.org/)_제이쿼리를 대체할 수 있는 자바스크립트 라이브러리다. 앵귤러나 엠버처럼 풀 MVC 프레임워크가 아니라, 뷰 모델(DOM)만 건드리는 가벼운 녀석이다. 그럼에도 불구하고, 최신 프레임워크가 지원하는 양방향 데이터 바인딩등을 지원해서 상당한 개발 생산성을 보인다. 2만개 이상의 스타를 가지고 있고, [깃허브 트렌딩에 계속 노미네이트](https://github.com/trending?since=monthly)되고는 등 빠르게 영역을 확대하고 있는 라이브러리다.  
