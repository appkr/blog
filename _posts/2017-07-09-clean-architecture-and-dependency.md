---
layout: post-minimal
title: '아키텍처와 의존성'
date: 2017-07-09 00:00:00 +0900
categories:
- learn-n-think
tags:
- 개발자
- 아키텍처
image: //blog.appkr.dev/images/2017-07-09-img-01.png
---

이 글은 그간 내가 짠 코드에 대한 반성이며, 앞으로 더 잘 만들겠다는 약속이며, 이런 실수를 하지 말라는 계몽이기도합니다. 

> 割鷄焉用牛刀(할계언용우도)
> 닭 잡는 데 어찌 소 잡는 칼을 쓰겠는가?
>
> <footer><cite>논어(論語) "양화(陽貨)"편</cite></footer>

오해를 하실까봐 미리 쉴드를 칩니다. 제가 좋아하고 자주 인용하는 말입니다.  

그런데 바꾸어 생각해보면, 소잡는데 닭 잡는 칼을 쓰는 것도 바보 같은 짓입니다. 일회성으로 사용할 소프트웨어을 개발할 때는 모든 설계 원칙을 지킬 필요 없습니다만, 계속 유지 보수해야 하는 대형 서비스를 개발할 때는 소 잡는 칼을 써야지요.

지난 몇 개월간 저의 포커스는 **읽기 쉬운 코드**였습니다. *"팀에 처음 합류한 신입이 코드를 이해하고 바로 프로젝트에 투입할 수 있는가?"* 라는 관점이죠.

<div class="panel panel-default">
  <div class="panel-body">
    <p class="lead">컴퓨터가 인식 가능한 코드는 바보라도 작성할 수 있지만, 인간이 이해할 수 있는 코드는 실력 있는 프로그래머만 작성할 수 있다.</p>
    <small class="text-muted">- 마틴파울러 "리팩토링"</small>
  </div>
</div>

저는 2016년 12월 부터 라라벨 5.2로 개발한 메쉬프라임이라는 서비스 개발에 참여하고 있습니다. 이 서비스는 오픈한 지 대략 1년 됐고 현재는 매일 2만 트랜잭션 정도가 발생하고, 이 트랜잭션에는 네다섯 개 정도의 테이블이 연결되어 있어서, 대략 10만 레코드가 생성됩니다. 오늘 기준으로 `master` 브랜치에 총 3,495 커밋이 있고, 추가된 코드는 대략 42만 라인입니다. 결코 작은 서비스가 아니죠?

팀 합류 초기에 폭풍같이 몰아치던 기능 추가 프로젝트가 어느 정도 마무리되어, 한 숨 돌리면서, 몇 주전에 라라벨 프레임워크 버전 업을 시도한 적이 있습니다. 운영 서버에 적용할 의도는 아니었지만, 곧 5.5 LTS가 나오니 5.3 -> 5.4까지 마이그레이션 해보자는 취지였지요. 공식 매뉴얼에서 말하는 마이그레이션 가이드를 따라 5.3 마이그레이션을 수행했습니다. 랜딩 페이지가 나오고 로그인도 잘 됐습니다만, API 엔드포인트를 하나씩 호출해 보고 문제점들을 하나씩 잡아가는 과정에서 마이그레이션이 불가하다는 점을 깨닫고 뒤로 물러섰습니다.

왜 그랬을까요? 바로 이 글에서 쓰고자 하는 **1) 커플링된 코드**와 **2) 아키텍처** 때문이었습니다. 본문에 나오는 코드는 메쉬프라임과 무관함을 밝힙니다.
 
이제 나는 **읽기 쉬울 뿐만 아니라 유지 보수가 편리한 코드**를 개발할 것을 약속합니다.

<div class="panel panel-default">
  <div class="panel-body">
    <p class="lead">프로그램이 지닌 가치는 두 종류다. 하나는 <strong>1) 현재의 기능이라는 가치</strong>이고, 또 하나는 <strong>2) 미래의 기능이라는 가치</strong>다. 프로그래밍할 때 개발자는 주로 그 프로그램에 현재 무슨 기능을 넣을지에 전념한다. 버그를 수정하든 새 기능을 추가하든, 그것은 프로그램의 성능을 높임으로써 현재 기능의 가치를 높이는 일이다.</p>
    <p class="lead">프로그램의 현재 기능은 그저 일부에 불과하다는 사실을 깨우치지 않으면 개발자로서 오래 가지 못한다. 오늘 일을 오늘 할 수 있어도 내일 일을 내일 할 능력이 없다면 개발자로서 싪패하게 된다. 오늘 해야 할 일은 알아도 내일 일은 알 수 없는 것이 당연하다. 이런 일, 저런 일, 또는 어쩌면 생각지도 못한 일을 하게 될 수도 있다.</p>
    <small class="text-muted">- 켄트 벡</small>
  </div>
</div>

<!--more-->
<div class="spacer">• • •</div>

## 1. 강한 결합

어떤 모듈 A가 다른 모듈 B에 "의존"한다는 것은 A가 B의 변수(데이터) 또는 함수(데이터는 변경하는 로직)를 사용하고 있거나, A의 함수에서 B를 파라미터로 받거나 B를 생성하거나, A의 함수에서 B 모듈을 반환하는 등의 모든 행위를 포함합니다. 즉, 모듈 B의 데이터 구조 또는 함수가 변경되면, 모듈 A도 영향을 받는다고 해석할 수 있습니다. 극단적인 경우에는 멀쩡하던 모듈 B의 함수 또는 모듈 자체가 다음 버전에 갑자기 사라질 수도 있겠죠?

우리의 코드는 프레임워크 개발팀을 믿고 신뢰하며 프레임워크나 ORM의 함수를 사용합니다. 그러나, 그들은 우리에게 자신의 코드를 변경하지 않는다고 어떤 약속도 하지 않았습니다. 결합도가 높은 코드 예제를 볼까요?

```php
<?php // app/Product.php

namespace App;

class Product extends \Illuminate\Database\Eloquent\Model
{
    // ...  
    public function getProductImageAttribute(string $productImage)
    {
        return public_path("images/{$productImage}");
    }
}
```

Pure 해야 할 도메인 모델이 엘로퀀트라는 큰 덩어리는 상속하고 있습니다. 상속은 아주 강한 결합입니다. 또 이 코드는 `public_path()`라는 라라벨 전역 함수에 의존합니다. 문제는 여기에 그치지 않고, 도메인 서비스나 애플리케이션 서비스에서도 `app()` 전역 함수나 `DB`와 같은 라라벨 파사드에 의존하고 있을 겁니다. 지금도 이렇게 짜고 있지 않나요? "아니오" 라고 대답했다면, 둘 중 하나입니다. 거짓말을 하고 있거나, 개발자가 아니거나...

**`참고`** "의존성"에 대해 깃허브 저장소에 예제 코드와 함께 정리하고 있습니다. [https://github.com/appkr/pattern/tree/master/dependency](https://github.com/appkr/pattern/tree/master/dependency)

## 2. 클린 아키텍처

아래 엉클 밥의 비디오에는 나오지는 않는데, 이 분은 OO(객체지향)를 이렇게 정의하셨습니다.

> OO란 Low level detail로 부터 High level policy를 보호하는 것이다.
>
> <footer><cite>로버트 C. 마틴</cite></footer>

이게 어떻게 가능할까요? 아래 비디오에서는 경계(`||`, 두 줄로 표시합니다)라고 답하고 있습니다. 쉽게 말하면 인터페이스입니다. 

[![The Principles of Clean Architecture by Uncle Bob Martin](//img.youtube.com/vi/o_TH-Y78tt4/0.jpg)](https://www.youtube.com/watch?v=o_TH-Y78tt4&t=10m45s)

중요 내용만 요약했습니다.

-   High Level 폴더 구조를 보고 Ruby on Rails 앱인줄 바로 알았다. 
    -   웹은 입출력 장치(==딜리버리 메커니즘)인데, 왜 이 앱이 하고자 하는 바를 폴더 구조에서 알 수 없는가?
    -   **`주`** RoR 폴더 구조를 벤치마크한 라라벨도 마찬가지입니다.
-   아키텍처는 해결하고자 하는 문제에 관한 의도를 표현해야한다. 
    -   아키텍처는 스프링, MySQL과 같은 툴이 아니다. 
    -   의도는 유스케이스(Use Case)를 통해서 드러난다.
-   Interactor는 애플리케이션에 종속적인 비즈니스 룰을 다룬다. 
    -   Domain은 애플리케이션과 무관한 비즈니스 룰을 다룬다. 
    -   **`주`** 애플리케이션은 웹 시스템에 적용, 모바일 앱에 적용 등을 말할 때의 "적용"의 의미. 앱과 혼동하지 말것.
-   앱과 무관한 웹 시스템, 데이터베이스등의 입출력 장치들은 경계(`||`)를 통해서 소스 코드의 의존성을 역전시켜야 한다. 
    -   비즈니스 룰 보다 UI가 더 자주 변경된다. UI의 변경 때문에 비즈니스 률이 영향받지 않아야 한다. 
    -   데이터베이스도 마찬가지로 디테일에 해당한다. 
    -   **`주`** 화살표의 방향에 주의하라고 여러번 말씀하심
-   프레임워크는 편리함을 선사하지만, 그에 따른 대가를 치러야 하는 시점이 찾아 온다.

비디오에 나온 그림을 전부 종합하면 아래 그림 및 설명과 같습니다.

![](/images/2017-07-09-img-01.png)
<small class="text-muted">그림 출처: //hugo.ferreira.cc/architecture-the-lost-years/</small>

- <small class="text-muted">(실선 두 개로 표시된)</small> 경계 왼쪽에는 우리가 흔히 아는 `View`와 `Controller`가 있습니다. 아래 쪽에는 `DataBase(=~Persistence Engine)`가 있습니다.
- 컨트롤러는 사용자의 요청을 받아 `Request Model(DTO, Command)`을 만들어서 `<<I>>Boundary`의 함수를 호출할 때 인자로 담아서 경계 안쪽으로 전달합니다.
- `Interactor(=~Service Object)`는 `<<I>>Boundary`를 구현하고 있고, `Controller`에서 넘겨준 `Request Model`을 사용해서 `Entity`의 함수를 호출합니다.
- `Interactor`는 요청을 수행하기 위해 `Entity Gateway(=~<<I>>Repository)`의 함수를 호출해서 저장된 상태를 불러 오기도 하고, 변경된 상태를 저장하기도 합니다.
- `Entity Gateway Impl`은 `<<I>>Entity Gateway`를 구현하고 있으며, 데이터베이스 API(SQL, ORM) 또는 File, Collection 등의 함수를 이용해서 조회 및 저장 작업을 수행합니다.
- `Interactor`는 요청을 처리한 후 `<<I>>Boundary`의 함수를 호출할 때 인자로 `Response Model`을 만들어 경계 바깥 쪽으로 전달합니다.
- `Presentor`는 `<<I>>Boundary`를 구현하고 있으며, `Interactor`가 전달한 `Response Model`을 가공하고, `View Model`의 데이터를 채워줍니다.

## 3. 모범 사례

[Trip Planner](https://github.com/leopro/trip-planner)라는 예제 프로젝트입니다. 커맨드와 유스케이스를 이용하고 있습니다. 아쉽게도 라라벨은 아니고, [심포니(Symfony)](//symfony.com/)와 [독트린(Doctrine)](//www.doctrine-project.org/)을 사용하네요. 

### 3.1. Controller

컨트롤러에서 아래와 같은 코드를 이용해서 `CreateTripCommand(=~Request Model)`를 만들어서 `UseCase::run()(=~<<I>>Boundary)`을 호출합니다. 

`new CreateTripCommand('my trip')` 부분을 실제 Http 컨트롤러에서는 `new CreateTripCommand($request->get('trip_name')`처럼 사용할 겁니다. 그리고 `new CreateTripUseCase($tripRepository)` 구문은 IoC 또는 의존성 주입을 사용할 것이므로 생략될 것입니다.

이 예제는 특별하게도 커맨드 버스를 이용하므로, 컨트롤러 코드에서 커맨드를 만들고, 커맨드 버스를 이용해서 생성된 커맨드를 전달하고, 커맨드 핸들러가 커맨드를 처리할 커맨드 핸들러(=~`Interactor`)를 찾아서 `run()` 메서드를 실행하고 컨트롤러 쪽으로 실행 결과를 반환해 줍니다. 

```php
<?php // https://github.com/leopro/trip-planner/blob/master/src/Leopro/TripPlanner/Application/Tests/CreateTripTest.php

namespace Leopro\TripPlanner\Application\Tests;

use ...

class CreateTripTest extends \PHPUnit_Framework_TestCase
{
    public function testCreateTrip()
    {
        $tripRepository = $this->getMockBuilder('...');
        $command = new CreateTripCommand('my trip');
        $useCase = new CreateTripUseCase($tripRepository);

        $trip = $useCase->run($command);
        $this->assertInstanceOf('...');
    }
}
```

### 3.2. Request Model

`CreateTripCommand`라는 Request Model 입니다. 커맨드를 사용하므로 커맨드 버스나 핸들러와 같은 복잡한 개념이 나오는데, 커맨드의 근본은 DTO(Data Transfer Object)를 사용하는 것과 마찬가지로 로직이 없는 순수 데이터 구조체입니다. 

DTO 보다 커맨드 시스템이 더 나은 점은 1) 커맨드 이름만으로 의도가 확실히 드러난다는 점, 2) 웹, 콘솔 등 다양한 애플리케이션(=~적용 방식, 입출력 장치)에서 재사용할 수 있다는 점, 3) 테스트가 편하다는 점 등을 들 수 있습니다.

```php
<?php // https://github.com/leopro/trip-planner/blob/master/src/Leopro/TripPlanner/Application/Command/CreateTripCommand.php

namespace Leopro\TripPlanner\Application\Command;

use ...

class CreateTripCommand implements Command
{
    private $name;

    public function __construct($name) {...}
    
    public function getRequest()
    {
        return new ArrayCollection([
          'name' => $this->name
        ]);
    }
    
    // ...
} 
```

### 3.3. Interactor

이 예제에서는 `UseCase`가 `<<I>>Boundary`이고, 이를 구현한 `CreateTripUseCase`가 `Interactor`입니다. DTO를 사용하는 전통적인 구현이라면, `CreateTripService`와 같은 이름으로 지었을 겁니다.

코드를 살펴보면, 유효한 커맨드인지 검사를 수행하고, `createWithFirstRoute()` 함수를 호출해서 `Trip` 이라는 `Entity`를 만듭니다. 그리고, 생성자를 통해서 주입 받은 `TripRepository` 인터페이스의 `add()` 함수를 호출함으로써 생성된 엔티티를 영속화시킵니다. 뒤에서 다시 보겠지만, `TripRepository`는 2절의 그림에서 본 경계 안 쪽에 있는 `<<I>>Entity Gateway`입니다. 

```php
<?php // https://github.com/leopro/trip-planner/blob/master/src/Leopro/TripPlanner/Application/UseCase/CreateTripUseCase.php

namespace Leopro\TripPlanner\Application\UseCase;

use ...

class CreateTripUseCase extends AbstractUseCase implements UseCase
{
    private $tripRepository;

    public function __construct(TripRepository $tripRepository) {...}

    public function getManagedCommand() {...}

    public function run(Command $command)
    {
        $this->exceptionIfCommandNotManaged($command);

        $trip = Trip::createWithFirstRoute(
            new TripIdentity(uniqid()),
            $command->getRequest()->get('name')
        );

        $this->tripRepository->add($trip);

        return $trip;
    }
} 
```

### 3.4. Entity

3.3. 절에서 호출한 `createWithFirstRoute` 함수가 `Trip` 모델의 상태를 변경합니다.

여기서 주목할 점은 데이터베이스와의 결합도를 낮추기 위해 `TripIdentity` 타입의 식별자를 사용한다는 점입니다. 데이터베이스에 의존하는 구현에서는 `INSERT INTO ...` 하기 전에는 엔티티의 식별자를 알 수 없고, 메모리 안에서 불완전한 상태로 살아있게 되는 문제가 있습니다.

또 하나 지적하고 싶은 점은 PHP의 한계 중에 하나인 메서드 오버로딩(overloading)입니다. 오버로딩을 할 수 없기 때문에 생성자를 Private로 선언하고, `createWithFirstRoute()`라는 정적 팩토리 메서드를 제공하고 있습니다. 오버로딩이 지원되었다면, `__construct(TripIdentity $identity)`, `__construct(TripIdentity $identity, $name)`처럼 생성자를 여러 개 만들었겠지요?

```php
<?php // https://github.com/leopro/trip-planner/blob/master/src/Leopro/TripPlanner/Domain/Entity/Trip.php

namespace Leopro\TripPlanner\Domain\Entity;

use ...

class Trip
{
    private $identity;
    private $name;
    private $routes;

    private function __construct(TripIdentity $identity, $name) {...}

    public static function createWithFirstRoute(TripIdentity $identity, $name)
    {
        $trip = new self($identity, $name);
        $trip->routes->add(Route::create($trip->name));

        return $trip;
    }

    // ...
} 
```

### 3.5. Entity Gateway

3.4. 절에서 호출했던 그 인터페이스입니다. 특이한 점은 `save()`, `persist()` 대신 `add()`라는 함수명을 쓰고 있습니다. 현재까지의 전체 구현이 PHP의 네이티브 배열을 랩핑한 `Collection`을 데이터 저장소로 사용하고 있어서이며, 영속성을 위한 저장 장치에 앱이 의존하지 않는다는 것을 한번 더 강조하는 네이밍입니다.  

```php
<?php // https://github.com/leopro/trip-planner/blob/master/src/Leopro/TripPlanner/Domain/Contract/TripRepository.php

namespace Leopro\TripPlanner\Domain\Contract;

use ...

interface TripRepository
{
    public function get(TripIdentity $identity);
    public function add(Trip $trip);
} 
```

### 3.6. Response Model

`Interactor`는 `Response` 모델에 데이터를 담아서 경계 바깥 쪽으로 내보냅니다.  

```php
<?php // https://github.com/leopro/trip-planner/blob/master/src/Leopro/TripPlanner/Application/Response/Response.php

namespace Leopro\TripPlanner\Application\Response;

class Response
{
    private $content;

    public function __construct($content = '') {...}

    public function getContent()
    {
        return $this->content;
    }
} 
```

### 3.7. All Together

아래 UML을 엉클 밥의 그림에 겹쳐보면... 소름이 돋습니다.

![Trip Planner](/images/2017-07-09-img-02.png)

### 3.8. Why?

다음 코드와 같이 컨트롤러에서 몇 줄만 쓰면 될 것을 복잡한 보일러 플레이트를 양산하면서 이렇게 짜고 있을까요?
 
```php
<?php

namespace App\Http\Controllers

use ...

class TripController {
    public function create(Request $request)
    {
        return Trip::create($request->all()); 
    }
}
```

강한 결합도(소프트웨어의 제 2가치 위반)로 발생하는 비용은 보일러 플레이트를 쓰는 비용보다 더 크기 때문입니다. 의존성이 없다는 것은 독립적으로 개발할 수 있다는 의미입니다. 독립적으로 개발할 수 있다는 것은 독립적으로 컴파일(패키징)할 수 있다는 의미입니다. 독립적으로 컴파일할 수 있다는 것은 독립적으로 배포할 수 있다는 의미입니다.   

업종마다 서비스마다 다를 수 있으니 오해마시기 바랍니다. 가령 여러 고객의 요구사항을 빠르게 찍어 내야 하는 웹 에이전시나, 한 달짜리 마케팅 캠페인용 서비스라면 바로 위의 코드와 같이 짠다고 해도 누가 뭐라 하겠습니까?

Ruby On Rails 커뮤니티에서도 DHH가 직접 나서서 똑같은 주제로 논쟁을 하고 있습니다. [https://gist.github.com/dhh/4849a20d2ba89b34b201](https://gist.github.com/dhh/4849a20d2ba89b34b201)

## 4. 앞으로 할 일

이 글에서 소개한 "커맨드 버스"와 지난 포스트에서 소개한 "<small>(의사, Pseudo)</small> 이벤트 소싱"은 라라벨에도 내장되어 있습니다. `Job`과 `Notification`이 바로 그것들인데요. 또 프레임워크에 의존하는 코드를 생산할까봐 조심스럽습니다. 컴포저로 설치한 3rd Party 컴포넌트도 전부 마찬가지 아니냐고 반문할 수 있습니다. 예! 맞습니다. 피하려면 라이브러리에서 제공하는 객체를 의존성 주입으로 사용하거나, IoC(서비스 컨테이너)를 이용해서 주입하거나, 앱 경계 안쪽에 인터페이스를 만들고 라이브러리를 [Adapter](https://en.wikipedia.org/wiki/Adapter_pattern) 또는 [Decorator](https://en.wikipedia.org/wiki/Decorator_pattern) 패턴으로 한번 랩핑해서 사용하는 방법이 있습니다.

지난 포스트 이후, 설계에 관한 고민을 하며 여기저기 기웃댔지만, 아직 라라벨의 의존성을 완전히 걷어낸 오픈 소스, 예제 프로젝트, 또는 방법을 설명하는 블로그 포스트는 찾지 못했습니다. 우선 라라벨 프로젝트에서 엘로퀀트를 완전히 경계 밖으로 내보내고 도메인 엔티티를 POPO(Plain Old PHP Object)로 만드는 방법을 연구할 겁니다. 이게 된다면, 엉클 밥이 말씀하신 프레임워크에 의존하지 않는, 또는 본문의 Trip Planner 예제처럼 HTTP와 같은 입출력 장치에 완전히 격리되어 작동하는 앱을 얻을 수 있을 겁니다. POPO를 이용함으로 그냥 공짜로 얻는 이점은 서두에 언급한 누구나 읽을 수 있는 코드입니다. 라라벨 매직이 전부 빠졌기 때문이죠.

지난 번 불변 엔티티도 깃허브 리포만 파 놓고 설계에 대한 고민들을 하다가 손을 못 대고 있었습니다. 확보된 코드는 도메인 주도 설계, 커맨드 주도 아키텍처, 이벤트소싱 & CQRS 등 새로운 아키텍처를 실험하기 위한 베이스로 사용할 예정입니다. 이번에도 조언 환영합니다.
