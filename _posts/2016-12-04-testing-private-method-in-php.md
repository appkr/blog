---
layout: post-minimal
title: "Private(or Protected) 메서드 테스트 하기 " 
date: 2016-12-04 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- PHP
---

최근에 회사 일로 검색 서비스를 개발했다. 검색 엔진으로는 Elastic Search를 사용했고, 매일 최한시(off-peak time)에 한 번씩 운영 데이터베이스에서 검색, 필터링, 정렬, Aggregation 등에 필요한 컬럼만 골라 인덱싱하도록 설계했다. 그리고, 재고 수량과 같이 실시간 업데이트가 필요한 값 들은 다른 서비스에서 SNS 메시지 또는 메시지 큐를 이용해서 전달하고, 전달 받은 값을 인덱싱에 반영하도록 구현했다.

Elastic Search는 사용법이 복잡하긴 하지만, 인덱싱된 필드 값에 따라 내림차순, 오름차순으로 미리 정렬된 결과를 받을 수 있다. 그런데, 아무리 실시간 업데이트를 한다고 해도, 인덱싱된 값만으로 정렬이 불가능한 경우가 있고, 이 경우에는 검색 결과를 받아서 후 처리로 배열을 순회하면서 다시 정렬을 해야 한다. 같은 클래스의 Public 메서드가 정렬 요청을 하므로, 당연히 Protected 메서드로 구현했다.

일반적으로 알려진 **테스트 모범 사례**는 다음과 같다.

- **내가 짠 코드만 테스트한다.** 외부에서 가져온 라이브러리를 테스트할 이유는 없다.
- **Public 메서드만 테스트한다.** Private나 Protected 메서드는 Public 메서드가 작동하는데 도움을 주는 메서드들이므로, Public 메서드를 테스트함으로써 자동으로 테스트된다.

후처리 정렬의 정상 작동을 확인해야 할 필요성이 생긴 것이다. 물론 구현한 Protected 메서드의 가시성을 Public으로 변경하면 쉽다. 그런데, 다른 클래스에서 호출하지도 않을 메서드를 Public으로 선언하는 것은 기분이 찜찜하다. 이 포스트에서는 **Private나 Protected로 선언된 메서드를 유닛 테스트하는 방법을 설명**한다. 결론부터 말하면, **PHP의 `Reflection` API를 이용**하는 것이다.

<!--more-->
<div class="spacer">• • •</div>

## 1. 테스트 타겟

테스트의 대상은 아래 클래스의 `sortByStoreStatusAndCanBuyNow()` 메서드다. 여러 단계를 거치긴 하지만, Public으로 선언한 `query()` 메서드의 의해서 호출된다. 인라인으로 간략한 설명을 달아 두었다. 

참고로 **네임스페이스에 나온 [`Bootake`는 내가 속한 회사에서 하는 서비스](http://bootake.com) 중 하나**다. 이번에 구현한 코드는 아직 서비스에 반영되진 않았다.

```php
<?php // core/Infrastructure/Queries/CvsProduct.php

namespace Search\Infrastructure\Queries;

use Bootake\SearchService\Thrift\Search\Product as ThriftProduct;
use Bootake\SearchService\Thrift\Search\SearchFilter;
use Bootake\SearchService\Thrift\Search\Section;
use Bootake\SearchService\Thrift\Search\SectionType;
use Illuminate\Support\Collection;
use Search\Application\OutMappers\ProductMapper;
use Search\Domain\Product;

class CvsProduct extends BaseQuery implements Queryable
{
    public function model()
    {
        // 엘로퀀트 모델 인스턴스다. 모델에 선언한 몇 가지 속성에 접근하기 위해서 필요하다.
        // BaseQuery라는 추상 부모 클래스에서 abstract function으로 이 메서드의 구현을 강제하고 있다.
        return new Product;
    }

    public function query(SearchFilter $sf, int $regionId, $offset = 0, $limit = 50)
    {
        // Elastic Search로 부터 받은 검색 결과를 $rawResults에 담았다.
        $this->rawResults = $this->client->search(
            $this->buildParam($sf, $regionId)
        );

        // 검색 결과는 여러 상점에서 제폼을 검색하므로 동일 제품이 검색 결과에 나타난다.
        // Elastic Search는 이미 Aggregation(GROUP BY)된 결과를 반환하는 것이 아니라,
        // 특정 필드 값에 따라 Aggregation했을 때의 ID값을 결과에 포함하여 반환한다.
        // 해서 실제 필요한 개수보다 더 많은 레코드를 요청하고, 필요한 레코드만 골라낸 후 페이징을 해야 한다.
        // 부모 클래스의 fetch() 메서드가 이 역할을 담당한다.
        $filtered = $this->fetch($this->model->distinctAttribute(), $offset, $limit);

        return $this->buildSection($filtered, $sf, $regionId);
    }

    protected function buildParam(SearchFilter $sf, $regionId)
    {
        // Elastic Search에 전달할 검색 파라미터다.
        return [
            // ...
        ];
    }

    protected function buildSection(Collection $payload, SearchFilter $sf, int $regionId)
    {
        // HTTP 응답으로 반환할 필드만 골라서 맵핑한다.
        // 이 과정에서 런타임에 계산해야 할 값들을 추가하거나, 데이터를 가공하거나 캐스팅하기도 한다.
        $mapped = (new ProductMapper)->mapCollection($payload, $sf, $regionId);
        
        // 정렬한다. 이 포스트의 대상이 되는 문제의 메서드가 여기서 호출된다.
        // 정렬한 결과를 미리 정의한 ThriftProduct Type에 맞도록 맵핑했다. 
        $sorted = $this->sortByStoreStatusAndCanBuyNow($mapped)
                       ->map(function (array $product) {
                           return new ThriftProduct($product);
                       })
                       ->values()->all();

        // $sorted 배열은 [ThriftProduct, ThriftProduct, ...] 형식인데,
        // 얘를 다시 Thrift 인터페이스에서 정의한 Section Type으로 랩핑한다.
        // getTotal()등의 메서드는 부모 클래스에 있다.
        return new Section([
            'type' => SectionType::PRODUCT,
            'matchedCount' => $this->getTotal(),
            'perPage' => $this->perPage(),
            'currentPage' => $this->resolveCurrentPage(),
            'stores' => [],
            'products' => $sorted,
        ]);
    }

    protected function sortByStoreStatusAndCanBuyNow(Collection $unsorted)
    {
        return $unsorted->sortBy(function($product) {
            // 'canBuyNow' 속성은 불리언이라 정렬을 위해 정수 값으로 바꾸어, $canBuyNow 변수에 할당했다.
            // 'canBuyNow'는 지금 장바구니에 담긴 상품과 같은 상점의 제품이란 의미다.
            $canBuyNow = $product['canBuyNow'] ? 1 : 2;

            // 제품이 속한 상점의 상태(영업 중 -> 배송 준비 중 -> 영업 준비 중)와
            // $canBuyNow를 복합해서 정렬해야 하므로 두 개 값을 결합했다.
            // 즉, 지금 상점이 영업 중이고 장바구니에 담긴 상품과 같은 상품이라 바로 구매 가능한 상품이 우선 노출된다.
            return sprintf('%d%d', $product['storeStatus'], $canBuyNow);
        });
    }
}
```

## 2. 테스트 작성

### 2.1. 테스트 헬퍼

`getTestableMethod()` 메서드는 PHP의 `Reflection` 클래스를 이용해서 인자로 받은 `$class::$name` 메서드를 이번 프로세스 동안만 Private 또는 Protected 메서드를 Public으로 변경해준다. 즉, 테스트를 수행하는 동안은 테스트 클래스가 타켓 메서드에 접근할 수 있다.

```php
<?php // tests/TestCase.php

namespace Test;

class TestCase extends \Laravel\Lumen\Testing\TestCase
{
    public function createApplication()
    {
        return require __DIR__.'/../bootstrap/app.php';
    }

    protected static function getTestableMethod($class, $name) {
        // $class의 Reflection 인스턴스를 만든다.
        $reflection = new \ReflectionClass($class);
        
        // $name 메서드를 접근 가능하도록 한다.
        $method = $reflection->getMethod($name);
        $method->setAccessible(true);

        // Reflection된 클래스가 아니라, 메서드를 반환한다.
        return $method;
    }
}
```

### 2.2. 테스트 코드

이제 테스트 코드를 쓰면 된다. 앞 절에서 만든 헬퍼에서 반환 받은 메서드에 `invokeArgs(클래스 인스턴스, [메서드의 인자])`식으로 사용하면 원래 감추진 메서드를 호출하여 결과를 얻을 수 있다.

```php
<?php // tests/Unit/QueryTest.php

namespace Test\Unit;

use Bootake\SearchService\Thrift\Search\StoreStatus;
use Elasticsearch\ClientBuilder;
use Search\Infrastructure\Queries\CvsProduct;

class QueryTest extends \Test\TestCase
{
    /** @test */
    function cvs_products_collection_should_be_sorted_by_its_parent_store_status()
    {
        $productCollection = collect([
            ['storeStatus' => StoreStatus::CLOSED, 'canBuyNow' => true],
            ['storeStatus' => StoreStatus::CLOSED, 'canBuyNow' => false],
            ['storeStatus' => StoreStatus::PREPARING, 'canBuyNow' => true],
            ['storeStatus' => StoreStatus::PREPARING, 'canBuyNow' => false],
            ['storeStatus' => StoreStatus::OPENED, 'canBuyNow' => true],
            ['storeStatus' => StoreStatus::OPENED, 'canBuyNow' => false],
        ]);

        // 1절에서 설명한 테스트 타켓 클래스의 인스턴스를 만든다.
        $cvsProductQuery = new CvsProduct(
            ClientBuilder::fromConfig([/*...*/])
        );

        // 테스트 헬퍼를 이용해서 다른 클래스에서 접근할 수 있는 메서드를 가져온다. 
        $method = static::getTestableMethod(
            CvsProduct::class,
            'sortByStoreStatusAndCanBuyNow'
        );

        // 메서드를 호출하고 반환값을 저장한다.
        $response = $method->invokeArgs($cvsProductQuery, [$productCollection]);

        $this->assertEquals(
            ['storeStatus' => StoreStatus::OPENED, 'canBuyNow' => true],
            $response->first()
        );

        $this->assertEquals(
            ['storeStatus' => StoreStatus::CLOSED, 'canBuyNow' => false],
            $response->last()
        );
    }
}
```

[![Unit Test](/images/2016-12-04-img-01.png)](/images/2016-12-04-img-01.png)

<!--more-->
<div class="spacer">• • •</div>

## 덧. Elastic Search 검색 성능

지난 달에 열린 XECon에서 [안정수](https://www.facebook.com/findstar)님이 [라라벨 Scout](https://laravel.kr/docs/5.3/scout)를 발표했는데, 청중 중에 한 분이 Scout의 성능에 대한 질문을 하셨다. Scout는 Algolia 또는 Elastic Search 등의 검색 엔진을 라라벨 프로젝트에서 사용하기 쉽도록 랩핑한 라이브러리다. 본 포스트의 주제와 무관하지만 필자가 측정한 성능을 남겨 놓는다.

검색 요청을 수신하고 프레임워크를 부팅하고 검색을 수행하는 메서드에 도달하는 데까지 41ms, 검색 요청에는 위/경도를 포함하고 있는데 받은 위/경도에 해당하는 지역 ID를 PostgreSQL을 사용하는 다른 마이크로 서비스에 던져 응답을 받는데까지 걸린 총 시간 481ms, 15만 인덱스에 대고 검색하고 결과를 받아 후처리하는 등 모든 작업을 마치고 응답을 내보기 직전까지 걸린 시간 777ms다.

OS X의 PHP 내장 웹 서버에서 검색 서비스를 구동하고, Elastic Search는 원격에 있는 상태로 테스트했다.

```bash
# storage/logs/lumen.log

[2016-12-04 15:13:22] search.DEBUG: 검색 요청 수신:SearchService.php:69 [0.04101300239563] 
[2016-12-04 15:13:22] search.DEBUG: RegionId 페치 완료(regionId=****):SearchService.php:77 [0.48165106773376] 
[2016-12-04 15:13:22] search.DEBUG: 검색 완료:SearchService.php:87 [0.7775821685791] 
[2016-12-04 15:13:22] search.DEBUG: 성능 요구량 ["메모리(MB) : 6.883152","CPU(%): 1.97802734375"] 
```
