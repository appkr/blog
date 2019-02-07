---
layout: post-minimal
title: '라라벨의 엘로퀀트 ORM에서 값 객체 사용하기'
date: 2019-02-06 00:00:00 +0900
categories:
- work-n-play
tags:
- Laravel
- OOP
- DDD
---

이 포스트에서는 엘로퀀트 모델에서 값 객체(Value Object)를 사용하는 몇 가지 방법을 고객 모델을 예제로 설명합니다.

1. 변경자와 접근자(Attribute Mutator & Accessor)를 이용하는 방법
2. LOB(Large Object)를 이용하는 방법
3. 참조(외래키)를 이용하는 방법

먼저 이 포스트에서 사용할 용어를 설명하겠습니다.

**모델**
현실 세계의 복잡한 물체 또는 사상을 목적에 적합하도록 핵심만 간소화한 것. x:1 비행기 프라모델은 실물을 본따 만든 모형입니다. 웹 서비스를 개발하는 컨텍스트에서 모델은 비즈니스에 참여하는 여러 실체의 본질적인 특징만 뽑아 추상화한 것입니다. e.g. 고객 모델

**엔티티와 값 객체**
모델은 다시 1) "엔티티"와 2) "값 객체"로 분류할 수 있습니다. 고객#1과 고객#2는 고유한 식별자로 구분지을 수 있으므로 엔티티라 하는 반면, 고객의 주소는 전체 값으로만 서로 같고 다름을 식별할 수 있으므로 값 객체라 합니다. 값 객체는 밸류 오브젝트, 또는 줄여서 밸류라고 부르기도 합니다. e.g. 고객 1번과 고객 2번은 식별자에 의해 서로 다른 모델. 고객 1번과 2번은 가족인데, 이들의 주소 '서울특별시 강남구 삼성동 162-17'과 '서울특별시 강남구 삼성동 162-17'은 전체 문자열이 같으므로 같은 주소임.

**원시 타입과 박스 타입**
PHP 언어에서 int, float, string, array, bool과 같은 데이터 타입을 원시 타입(Primitive Type)이라 합니다. 64bit 환경에서는 int라 쓰지만 4byte가 아니라 8bytes 즉 2^64 메모리 공간을 차지하고, float도 double과 같은 표현 범위를 가집니다(see http://php.net/manual/en/language.types.php). 
여튼, 아래 예처럼 고객을 의미할 때 `customer:string`처럼 원시타입으로 표현하기 보다는 `customer:Customer`로 쓰는 것이 더 많은 컨텍스트를 전달 할 수 있습니다. 여기서 후자를 박스 타입(Boxed Type)이라 부를 수 있습니다. 이를 다시 맥락에 따라서 엔티티나 값 객체로 부를 수도 있고요.

```php
$c = '홍길동';

// v.s.

$c = new Customer('홍길동');
```

<!--more-->
<div class="spacer">• • •</div>

## 0. 예제를 위한 뼈대 코드 준비

새 라라벨 프로젝트를 만듭니다. `laravel` 명령어를 쓸 수 없다면, [매뉴얼](https://laravel.com/docs/5.7#installing-laravel)을 참고해서 Laravel Installer를 설치합니다.

```bash
$ laravel new eloquent-value-object
$ cd eloquent-value-object
$ php artisan --version
#Laravel Framework 5.7.25
$ cp .env.example .env
```

`.env`파일에서 `DB_DATABASE` 값은 `eloquent_value_object`로 변경했습니다. 설정한대로 데이터베이스와 사용자를 만듭니다.

```mysql
mysql> CREATE DATABASE eloquent_value_object DEFAULT CHARACTER SET = utf8 DEFAULT COLLATE = utf8_unicode_ci;
mysql> CREATE USER "homestead"@"%" IDENTIFIED BY "secret";
mysql> GRANT All PRIVILEGES ON eloquent_value_object.* TO "homestead"@"%";
mysql> FLUSH PRIVILEGES;
```

`artisan` CLI로 모델, 스키마 마이그레이션, 모델 팩토리 뼈대 코드를 만듭니다.

```bash
$ php artisan make:model Customer --migration --factory
#Model created successfully.
#Factory created successfully.
#Created Migration: 2019_02_07_000000_create_customers_table
```

## 1. 변경자와 접근자를 이용하는 방법

접근자와 변경자를 처음 들어봤다면 [라라벨 매뉴얼](https://laravel.com/docs/5.7/eloquent-mutators#accessors-and-mutators)을 참고합니다.

이 방법은 주소에 관련된 DB 컬럼은 정규화된 형태로 사용하되, 엘로퀀트 모델에서는 주소와 관련된 DB 컬럼을 조합해서 의미있는 PHP 객체로 사용하는 방법입니다. 다시 말하면, 엘로퀀트 모델을 DB에 영속화할 때는 변경자를 이용해서 객체의 필드를 DB 컬럼으로 각각 맵핑시키고, DB 컬럼을 읽어서 엘로퀀트 모델로 재생할 때는 접근자를 이용해서 객체의 필드로 셋팅하는 겁니다. 

아래 그림에서 `Customer.address` 필드는 `Address` 타입의 값 객체인데, `customers.addr_si_do_name`, `customers.addr_si_gun_gu_name`, `...`, `customers.addr_detail` 컬럼과 맵핑됩니다.

```bash
+--------------------+
| class Customer     |
+--------------------+
| - name: string     |
| - address: Address |
+--------------------+

+--------------------+
| table customers    |
+--------------------+
| - id: int          |
| - name: varchar    |
| - addr_si_do_name: varchar
| - addr_si_gun_gu_name: varchar
| - ...              |
| - addr_detail: varchar
+--------------------+
```

### 1.1. 스키마 마이그레이션

```php
<?php // database/migrations/2019_02_07_000000_create_customers_table.php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreateCustomersTable extends Migration
{
    public function up()
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->increments('id');
            $table->string('name')->comment('고객 이름');
            $table->string('addr_si_do_name')->comment('시도');
            $table->string('addr_si_gun_gu_name')->nullable()->comment('시군구');
            $table->string('addr_admin_dong_name')->nullable()->comment('행정동');
            $table->string('addr_legal_dong_name')->nullable()->comment('법정동');
            $table->string('addr_legal_ri_name')->nullable()->comment('법정리');
            $table->boolean('addr_is_mountain')->default(false)->comment('산 여부 (0:대지, 1:산)');
            $table->string('addr_jibun_number')->nullable()->comment('지번');
            $table->string('addr_road_name')->nullable()->comment('도로명');
            $table->unsignedTinyInteger('addr_is_basement')->default(0)->comment('지하 여부 (0:지상, 1:지하, 2:공중)');
            $table->string('addr_building_number')->nullable()->comment('건물번호');
            $table->string('addr_detail')->nullable()->comment('상세주소 (건물명 등)');
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('customers');
    }
}
```

스키마 마이그레이션을 적용합니다.

```bash
$ php artisan migrate
#Migration table created successfully.
$Migrating: 2019_02_07_000000_create_customers_table
$Migrated:  2019_02_07_000000_create_customers_table
```

### 1.2. 엔티티와 값 객체

야래 코드의 `setAddressAttribute()` 변경자에서 `Address` 객체의 각 필드를 DB 컬럼에 맵핑하고 있습니다. 한편 `getAddressAttribute()` 접근자에서는 DB 컬럼을 `Address` 객체의 각 필드로 맵핑하고 있습니다.

`Cusomer`의 모든 데이터가 메모리에서 객체로 존재하는 런타임에는 DB 컬럼과의 관계는 몰라도 되므로, 엘로퀀트의 `$hidden` 속성을 이용해서 숨겼습니다.

```php
<?php // app/Customer.php

namespace App;

use Illuminate\Database\Eloquent\Model;

/**
 * App\Customer
 *
 * @property int $id
 * @property string $name 고객 이름
 * @property Address $address 고객 주소
 * @property string $addr_si_do_name 시도
 * @property string|null $addr_si_gun_gu_name 시군구
 * @property string|null $addr_admin_dong_name 행정동
 * @property string|null $addr_legal_dong_name 법정동
 * @property string|null $addr_legal_ri_name 법정리
 * @property int $addr_is_mountain 산 여부 (0:대지, 1:산)
 * @property string|null $addr_jibun_number 지번
 * @property string|null $addr_road_name 도로명
 * @property int $addr_is_basement 지하 여부 (0:지상, 1:지하, 2:공중)
 * @property string|null $addr_building_number 건물번호
 * @property string|null $addr_detail 상세주소 (건물명 등)
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @mixin \Eloquent
 */
class Customer extends Model
{
    protected $hidden = [
        'addr_si_do_name',
        'addr_si_gun_gu_name',
        'addr_admin_dong_name',
        'addr_legal_dong_name',
        'addr_legal_ri_name',
        'addr_is_mountain',
        'addr_jibun_number',
        'addr_road_name',
        'addr_is_basement',
        'addr_building_number',
        'addr_detail',
    ];

    public function getAddressAttribute()
    {
        return new Address(
            $this->addr_si_do_name,
            $this->addr_si_gun_gu_name,
            new JibunAddress(
                $this->addr_admin_dong_name,
                $this->addr_legal_dong_name,
                $this->addr_legal_ri_name,
                $this->addr_is_mountain,
                $this->addr_jibun_number
            ),
            new RoadAddress(
                $this->addr_road_name,
                $this->addr_is_basement,
                $this->addr_building_number
            ),
            $this->addr_detail
        );
    }

    public function setAddressAttribute(Address $address)
    {
        $this->attributes['addr_si_do_name'] = $address->getSiDo();
        $this->attributes['addr_si_gun_gu_name'] = $address->getSiGunGu();
        $this->attributes['addr_detail'] = $address->getDetailAddress();

        $jibunAddress = $address->getJibunAddress();
        $this->attributes['addr_admin_dong_name'] = $jibunAddress->getAdminDongName();
        $this->attributes['addr_legal_dong_name'] = $jibunAddress->getLegalDongName();
        $this->attributes['addr_legal_ri_name'] = $jibunAddress->getLegalRiName();
        $this->attributes['addr_is_mountain'] = $jibunAddress->isMountain();
        $this->attributes['addr_jibun_number'] = $jibunAddress->getJibunNumber();

        $roadAddress = $address->getRoadAddress();
        $this->attributes['addr_road_name'] = $roadAddress->getRoadName();
        $this->attributes['addr_is_basement'] = $roadAddress->isBasement();
        $this->attributes['addr_building_number'] = $roadAddress->getBuildingNumber();
    }
}
```

`Customer` 클래스가 의존하는 값 객체, `Address`, `JibunAddress`, `RoadAddress` 클래스를 만듭니다. 주목할 점은 `isEqualTo()` 함수입니다. 앞서 설명한 바와 같이, 값 객체간의 동등 비교를 위해 모든 필드의 값을 비교하는 것을 볼 수 있습니다.

```php
<?php // app/Address.php

namespace App;

class Address
{
    private $siDo;
    private $siGunGu;
    private $jibunAddress;
    private $roadAddress;
    private $detailAddress;

    public function __construct(
        string $siDo = null,
        string $siGunGu = null,
        JibunAddress $jibunAddress = null,
        RoadAddress $roadAddress = null,
        string $detailAddress = null
    ) {
        $this->siDo = $siDo;
        $this->siGunGu = $siGunGu;
        $this->jibunAddress = $jibunAddress;
        $this->roadAddress = $roadAddress;
        $this->detailAddress = $detailAddress;
    }

    public function getSiDo()
    {
        return $this->siDo;
    }

    public function getSiGunGu()
    {
        return $this->siGunGu;
    }

    public function getJibunAddress()
    {
        return $this->jibunAddress;
    }

    public function getRoadAddress()
    {
        return $this->roadAddress;
    }

    public function getDetailAddress()
    {
        return $this->detailAddress;
    }

    public function isEqualTo(Address $other)
    {
        return $this->siDo === $other->getSiDo()
            && $this->siGunGu === $other->getSiGunGu()
            && $this->jibunAddress->isEqualTo($other->getJibunAddress())
            && $this->roadAddress->isEqualTo($other->getRoadAddress());
    }

    public function toArray()
    {
        return [
            'siDo' => $this->siDo,
            'siGuGu' => $this->siGunGu,
            'jibunAddress' => $this->jibunAddress->toArray(),
            'roadAddress' => $this->roadAddress->toArray(),
            'detailAddress' => $this->detailAddress,
        ];
    }
}
```

```php
<?php // App/JibunAddress.php

namespace App;

class JibunAddress
{
    private $adminDongName;
    private $legalDongName;
    private $legalRiName;
    private $isMountain;
    private $jibunNumber;

    public function __construct(
        string $adminDongName = null,
        string $legalDongName = null,
        string $legalRiName = null,
        bool $isMountain = null,
        string $jibunNumber = null
    ) {
        $this->adminDongName = $adminDongName;
        $this->legalDongName = $legalDongName;
        $this->legalRiName = $legalRiName;
        $this->isMountain = $isMountain;
        $this->jibunNumber = $jibunNumber;
    }

    public function getAdminDongName()
    {
        return $this->adminDongName;
    }

    public function getLegalDongName()
    {
        return $this->legalDongName;
    }

    public function getLegalRiName()
    {
        return $this->legalRiName;
    }

    public function isMountain()
    {
        return $this->isMountain;
    }

    public function getJibunNumber()
    {
        return $this->jibunNumber;
    }

    public function isEqualTo(JibunAddress $other)
    {
        return $this->adminDongName === $other->getAdminDongName()
            && $this->legalDongName === $other->getLegalDongName()
            && $this->legalRiName === $other->getLegalRiName()
            && $this->isMountain === $other->isMountain()
            && $this->jibunNumber === $other->getJibunNumber();
    }

    public function toArray()
    {
        return [
            'adminDongName' => $this->adminDongName,
            'legalDongName' => $this->legalDongName,
            'legalRiName' => $this->legalRiName,
            'isMountain' => $this->isMountain,
            'jibunNumber' => $this->jibunNumber,
        ];
    }
}
```

```php
<?php // App/RoadAddress.php

namespace App;

class RoadAddress
{
    private $roadName;
    private $isBasement;
    private $buildingNumber;

    public function __construct(
        string $roadName = null,
        bool $isBasement = null,
        string $buildingNumber = null
    ) {
        $this->roadName = $roadName;
        $this->isBasement = $isBasement;
        $this->buildingNumber = $buildingNumber;
    }

    public function getRoadName()
    {
        return $this->roadName;
    }

    public function isBasement()
    {
        return $this->isBasement;
    }

    public function getBuildingNumber()
    {
        return $this->buildingNumber;
    }

    public function isEqualTo(RoadAddress $other)
    {
        return $this->roadName === $other->getRoadName()
            && $this->isBasement === $other->isBasement()
            && $this->buildingNumber === $other->getBuildingNumber();
    }

    public function toArray()
    {
        return [
            'roadName' => $this->roadName,
            'isBasement' => $this->isBasement,
            'buildingNumber' => $this->buildingNumber,
        ];
    }
}
```

### 1.3. [Optional] 모델 팩토리

테스트를 편의를 위해 모델 팩토리를 만들었습니다.

```php
<?php // database/factories/CustomerFactory.php

use Faker\Generator as Faker;

$factory->define(App\Customer::class, function (Faker $faker) {
    return [
        'name' => $faker->name,
        'address' => new \App\Address(
            '서울특별시',
            '강남구',
            new \App\JibunAddress(
                '삼성1동',
                '삼성동',
                null,
                false,
                '162-17'
            ),
            new \App\RoadAddress(
                '봉은사로112길',
                0,
                '6'
            ),
            '익성빌딩 5층 메쉬코리아'
        ),
    ];
});
```

### 1.4. 테스트

테스트 클래스나, 컨트롤러를 만들지 않았으므로, 팅커 콘솔을 이용해서 기본 기능을 테스트해봅니다.

```bash
$ php artisan tinker
# 엔티티 생성 및 영속화
>>> $c1 = factory(App\Customer::class)->create();
=> App\Customer {#2963
     name: "Ted Muller",
     updated_at: "2019-02-07 12:58:01",
     created_at: "2019-02-07 12:58:01",
     id: 1,
   }

>>> $c2 = factory(App\Customer::class)->create();
=> App\Customer {#2969
     name: "Dorris Bednar",
     updated_at: "2019-02-07 12:58:16",
     created_at: "2019-02-07 12:58:16",
     id: 2,
   }

# 엔티티 및 값 객체의 필드 접근
>>> $c1->address;
=> App\Address {#2968}

>>> $c1->address->getSiDo();
=> "서울특별시"

>>> $c1->address->getJibunAddress()->getJibunNumber();
=> "162-17"

>>> $c1->address->toArray();
=> [
     "siDo" => "서울특별시",
     "siGuGu" => "강남구",
     "jibunAddress" => [
       "adminDongName" => "삼성1동",
       "legalDongName" => "삼성동",
       "legalRiName" => null,
       "isMountain" => false,
       "jibunNumber" => "162-17",
     ],
     "roadAddress" => [
       "roadName" => "봉은사로112길",
       "isBasement" => false,
       "buildingNumber" => "6",
     ],
     "detailAddress" => "익성빌딩 5층 메쉬코리아",
   ]

# 값 객체의 동등 비교
>>> $c1->address->isEqualTo($c2->address);
=> true

# 값 객체를 이용한 콜렉션 필터링
>>> App\Customer::get()->filter(function (App\Customer $c) {
...     return $c->address->getSiDo() === '서울특별시';
... })->toArray();
=> [
     [
       "id" => 1,
       "name" => "Ted Muller",
       "created_at" => "2019-02-07 12:58:01",
       "updated_at" => "2019-02-07 12:58:01",
       "address" => App\Address {#2975},
     ],
     [
       "id" => 2,
       "name" => "Dorris Bednar",
       "created_at" => "2019-02-07 12:58:16",
       "updated_at" => "2019-02-07 12:58:16",
       "address" => App\Address {#2976},
     ],
   ]
```

DB에 영속화가 잘 되었나 쿼리해봅니다.

```sql
SELECT * FROM customers;
/* SequelPro > Bundle > Copy > Copy as JSON
{
    "data":
    [
        {
            "id": 1,
            "name": "Ted Muller",
            "addr_si_do_name": "서울특별시",
            "addr_si_gun_gu_name": "강남구",
            "addr_admin_dong_name": "삼성1동",
            "addr_legal_dong_name": "삼성동",
            "addr_legal_ri_name": null,
            "addr_is_mountain": 0,
            "addr_jibun_number": "162-17",
            "addr_road_name": "봉은사로112길",
            "addr_is_basement": 0,
            "addr_building_number": "6",
            "addr_detail": "익성빌딩 5층 메쉬코리아",
            "created_at": "2019-02-07 12:58:01",
            "updated_at": "2019-02-07 12:58:01"
        },
        {
            "id": 2,
            "name": "Dorris Bednar",
            "addr_si_do_name": "서울특별시",
            "addr_si_gun_gu_name": "강남구",
            "addr_admin_dong_name": "삼성1동",
            "addr_legal_dong_name": "삼성동",
            "addr_legal_ri_name": null,
            "addr_is_mountain": 0,
            "addr_jibun_number": "162-17",
            "addr_road_name": "봉은사로112길",
            "addr_is_basement": 0,
            "addr_building_number": "6",
            "addr_detail": "익성빌딩 5층 메쉬코리아",
            "created_at": "2019-02-07 12:58:16",
            "updated_at": "2019-02-07 12:58:16"
        }
    ]
}
*/
```

<!--more-->
<div class="spacer">• • •</div>

포스트가 너무 길어져서 여기서 끊고, 다음 포스트에서 이어서 쓰겠습니다. 혹시 포스트를 못 쓰더라도 예제 코드는 꼭 작성할겁니다.

- 저장소: https://github.com/appkr/eloquent-value-object
- 변경자와 접근자 브랜치: https://github.com/appkr/eloquent-value-object/tree/attr-accessor-mutator

각 설계 방식의 특징을 미리 정리해봅니다.

**변경자와 접근자**
- 컬럼이 나뉘어 있어서 DB에서 쿼리하기 편하다
- 객체에서 여러 가지 연산을 수행하기 편리하다
- 보일러플레이트 코드를 많이 써야 한다

**LOB**
- 컬럼이 나뉘어 있지 않아서, DB 스키마가 깔끔하다
- 상대적으로 보일러플레이트 코드의 양이 적다
- PHP 직렬화 또는 JSON으로 한 컬럼에 저장되므로 쿼리하기 힘들다
- 직렬화의 대상이되는 클래스를 변경할 때, 과거에 직렬화한 데이터에 대한 호환성을 주의해야 한다

**참조(외래키)**
- 구현이 가장 쉽다
- 중복 레코드가 발생한다
