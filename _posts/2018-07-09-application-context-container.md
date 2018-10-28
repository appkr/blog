---
layout: post-minimal
title: '라라벨 ApplicationContext 컨테이너 구현'
date: 2018-07-09 00:00:00 +0900
categories:
- work-n-play
tags:
- Laravel
- 개발자
image: //blog.appkr.kr/images/2018-07-09-img-01.png
---

사전에서 context(컨텍스트)를 찾아보면 어떤 사건이 발생했을 때의 주변 상황 정도로 설명하고 있습니다. 컴퓨터 소프트웨어에서도 컨텍스트 스위칭, 로그 컨텍스트, 애플리케이션 컨텍스트 등 컨텍스트라는 단어를 많이 사용합니다.

라라벨은 IoC를 위한 Service Container[^1]가 있으며, 여기에 어떤 데이터 타입이든 바인딩할 수 있고, 애플리케이션 실행 중에 아래처럼 꺼내 쓸 수 있습니다. 

```php
$container = app();
$container->bind('foo', function () {
	return 'bar';
});
$container->make('foo'); // 'bar'
``` 

그런데, 아래와 같은 문제가 있죠[^2]. 작은 애플리케이션에서는 이렇게 쓴다고 전혀 문제없지만, 애플리케이션이 커지면 결국 개발자에게 큰 부담으로 다가옵니다.

[![Strong Dependency](/images/2018-07-09-img-01.png)](/images/2018-07-09-img-01.png) 

이번 포스트에서는 라라벨 애플리케이션에서 애플리케이션 실행 시점의 주변 상황을 담아 놓고 필요할 때 꺼내 쓰기 위한 데이터 컨테이너를 구현했던 썰을 풀어보려합니다. `ApplicationContext`라 이름 지었고 Java 언어의 `ThreadLocal`[^3]과 비슷한 역할을 한다고 보면 됩니다. 주로 아래와 같은 상황에 유용하게 사용되기를 바라며 만들었어요.

- 프레임워크 영역(=main)의 데이터를 코어 영역(=app)으로 전달할 때
- 로깅 및 감사
- 프로세스간 컨텍스트 릴레이 등등 (e.g. Api -> Queue, App -> External, ...)

<!--more-->
<div class="spacer">• • •</div>

## 1. 기능 요구 사항

- 컨텍스트를 소비하는 코어 코드가 프레임워크에서 생성한 `Container`, `Application`에 의존하지 않도록 한다
- 추가적인 의존성이 없는 클린한 데이터 컨테이너
- 현재 컨텍스트를 다음 프로세스에 전달할 수 있고, 직전 컨텍스트를 현재 컨텍스트에 연결할 수 있다
- 트랜잭션 정보를 담고 있다
- 사용자 정보를 구할 수 있다

## 2. 설계

[![ApplicationContext Design](/images/2018-07-09-img-02.png)](/images/2018-07-09-img-02.png)

## 3. 구현

코드에 주석을 달았으므로 추가적인 설명은 생략합니다.

### 3.1. `ApplicationContextServiceProvider`

라라벨이 부팅할 때, `ApplicationContext` 객체를 만들고 `ServiceContainer`에 등록해 두는 일을 합니다.

```php
<?php // https://github.com/appkr/db-lock-poc/blob/master/app/Providers/ApplicationContextServiceProvider.php

namespace App\Providers;

use {...}

class ApplicationContextServiceProvider extends ServiceProvider
{
    public function register()
    {
        $this->app->singleton(ApplicationContext::class, function (Application $app) {
            $runningInConsole = php_sapi_name() == 'cli';
            $config = $app->make(ConfigRepository::class);

            return new ApplicationContext([
                'runningInConsole' => $runningInConsole,
                'appEnv' => $config->get('app.env', 'UNKNOWN'),
                'appVersion' => $config->get('app.version', 'UNKNOWN'),
                'transactionId' => $this->getTransactionId(),
                'traceNumber' => $this->getTraceNumber(),
                'user' => $this->getUser(),
                'clientIp' => $runningInConsole ? null : $this->getClientIp()
            ]);
        });
    }

    private function getTransactionId()
    {
        /** @var Request $request */
        $request = $this->app->make(Request::class);
        if ($request->hasHeader(XHttpHeader::REQUEST_ID)) {
            // 클라이언트가 제출한 X-Vendor-Request-Id가 항상 최우선 사용됩니다.
            return trim(urldecode($request->header(XHttpHeader::REQUEST_ID)));
        }
        if ($request->hasHeader(XHttpHeader::UNIQUE_ID)) {
            // 웹 서버가 부여한 식별자가 그 다음으로 사용됩니다.
            return trim(urldecode($request->header(XHttpHeader::UNIQUE_ID)));
        }
        // 둘 중 아무것도 없으며, 라라벨 애플리케이션에서 발급한 UUID로 폴백합니다.
        return (string)Uuid::uuid4();
    }

    private function getTraceNumber()
    {
    	// 로그를 쓸 때마다 트레이스 넘버를 1씩 증가시켜, 로그를 순서대로 보기 위함힙니다.
    	// 컨텍스트를 전달할 때도 현재의 컨텍스트 객체 또는 API 요청 헤더에 달아보내서 순서를 유지할 수 있도록 합니다.
        $request = $this->app->make(Request::class);
        return $request->hasHeader(XHttpHeader::TRACE_NUMBER)
            ? (int)trim(urldecode($request->header(XHttpHeader::TRACE_NUMBER))) : null;
    }

    private function getUser($guardName = 'api')
    {
        if (php_sapi_name() == 'cli') {
            return User::createDefaultUser([
                'name' => 'CLI',
                'email' => 'cli@example.com',
            ]);
        }

        /** @var Factory $authFactory */
        $authFactory = $this->app->make(Factory::class);
        $guard = $authFactory->guard($guardName);
        return $guard->user() ?: User::createDefaultUser();
    }

    private function getClientIp()
    {
        /** @var Request $request */
        $request = $this->app->make(Request::class);
        return $request->getClientIp();
    }
}
```

### 3.2. `ApplicationContext`

로직 없이 Getter와 Setter만 있는 DTO(Data Transfer Object), Boundary 객체입니다.

```php
<?php // https://github.com/appkr/db-lock-poc/blob/master/app/ApplicationContext.php

namespace App;

use Myshop\Domain\Model\User;

class ApplicationContext
{
    private $dataContainer;

    public function __construct(array $data = [])
    {
        $this->dataContainer = $data;
    }

    public function isRunningInConsole(): bool
    {
        return $this->get('runningInConsole');
    }

    public function getAppEnv(): string
    {
        return $this->get('appEnv');
    }

    public function getAppVersion(): string
    {
        return $this->get('appVersion');
    }

    public function getTransactionId(): string
    {
        return $this->get('transactionId');
    }

    public function setTransactionId(string $newTransactionId)
    {
        $this->set('transactionId', $newTransactionId);
    }

    public function getTraceNumber(): int
    {
        return intval($this->get('traceNumber'));
    }

    public function setTraceNumber(int $newTraceNumber)
    {
        $this->set('traceNumber', $newTraceNumber);
    }

    public function increaseTraceNumber()
    {
        $this->set('traceNumber', intval($this->get('traceNumber')) + 1);
    }

    public function succeedPreviousContext(ApplicationContext $previousContext)
    {
        if ($previousContext === $this) {
            return;
        }
        $this->set('transactionId', $previousContext->getTransactionId());
        $this->set('traceNumber', $previousContext->getTraceNumber());
        $this->set('user', $previousContext->getUser());
    }

    public function getUser(): User
    {
        return $this->get('user');
    }

    public function setUser(User $user)
    {
        $this->set('user', $user);
    }

    public function getClientIp()
    {
        return $this->get('clientIp');
    }

    // Helpers

    public function all() {...}

    public function keys() {...}

    public function values() {...}

    public function get($key, $default = null)
    {
        return array_key_exists($key, $this->dataContainer) ? $this->dataContainer[$key] : $default;
    }

    private function set($key, $value)
    {
        $this->dataContainer[$key] = $value;
    }

    public function has($key) {...}
}
```

### 3.3. `ClientContextPolicy`: A Domain Class Example

런타임에 `ServiceContainer`에 등록했던 `ApplicationContext`를 주입받아 사용자의 IP를 체크하는 일을 하는 예제 클래스입니다. 네임스페이스는 프레임워크 영역인 `App` 아래에 있지만, "허용한 IP로 접속했을 때만 서비스 사용을 허용한다"라는 도메인 정책을 구현하고 있으므로, 도메인 클래스라 할 수 있습니다.

```php
<?php // https://github.com/appkr/db-lock-poc/blob/master/app/Policies/ClientContextPolicy.php

namespace App\Policies;

use App\ApplicationContext;
use App\Http\Exception\NotAllowedIpException;
use Myshop\Domain\Model\User;
use Symfony\Component\HttpFoundation\IpUtils;

class ClientContextPolicy
{
    private $appContext;

    public function __construct(ApplicationContext $appContext)
    {
        $this->appContext = $appContext;
    }

    public function check()
    {
        $user = $this->appContext->getUser();
        $clientIp = $this->appContext->getClientIp();
        $this->checkUserIp($user, $clientIp);
    }

    private function checkUserIp(User $user, $clientIp)
    {
        $allowedIps = $user->allowed_ips ?: ['*'];
        if (in_array('*', $allowedIps, true)) {
            return;
        }

        $accessAllowed = IpUtils::checkIp($clientIp, $allowedIps);
        if (! $accessAllowed) {
            throw new NotAllowedIpException;
        }
    }
}
```

깃허브 예제 코드에서는 Sentry, Logging, Exception Handling 등에 `ApplicationContext`를 적용하는 부분도 담고 있습니다. 전체 코드는 [https://github.com/appkr/db-lock-poc/pull/23/files](https://github.com/appkr/db-lock-poc/pull/23/files) 에서 확인하실 수 있습니다.

---

[^1]: [ServiceContainer 공식 문서](https://laravel.com/docs/5.6/container), [공식보다 더 나은 문서](https://gist.github.com/davejamesmiller/bd857d9b0ac895df7604dd2e63b23afe)

[^2]: [클린 아키텍처](/learn-n-think/clean-architecture-and-dependency/#2-%ED%81%B4%EB%A6%B0-%EC%95%84%ED%82%A4%ED%85%8D%EC%B2%98)에 대한 포스트를 읽어보세요.

[^3]: [`ThreadLocal`에 관한 최범균님의 블로그 포스트](//javacan.tistory.com/entry/ThreadLocalUsage)




