---
layout: post-minimal
title: '라라벨의 엘로퀀트 ORM에서 값 객체 사용하기 2부'
date: 2019-02-08 00:00:00 +0900
categories:
- work-n-play
tags:
- Laravel
- OOP
- DDD
image: //blog.appkr.dev/images/2019-02-08-img-01.png
---

[지난 포스트](/work-n-play/how-to-use-value-object-in-laravel-eloquent/)에 이어서, 이번 포스트에서 두번째 세번째 방법을 설명합니다.

1. 변경자와 접근자(Attribute Mutator & Accessor)를 이용하는 방법
2. LOB(Large Object)를 이용하는 방법
3. 참조(외래키)를 이용하는 방법

[![ORM Basic](/images/2019-02-08-img-01.png)](/images/2019-02-08-img-01.png)

본문 들어가기 전에 잠깐 딴 얘기할게요. 

객체는 어느 순간 소멸됩니다. PHP는 프로세스가 종료되면 메모리 자원을 운영체제에 반환하면서 소멸되겠죠, 또는 가비지 콜렉션에 의해서든지요. 다른 프로세스에서 직전에 사용하던 객체의 상태를 이어서 사용하기 위해서 영속화라는 과정이 필요합니다. 대부분의 애플리케이션이 영속화의 도구로 DB를 사용하죠.

그런데 말입니다. 객체와 DB는 데이터를 다루는 방식이 완전히 다릅니다. 그래서 그림에서 보듯이 객체와 DB간의 차이점을 해결해주는 것이 ORM입니다.

<!--more-->
<div class="spacer">• • •</div>

## 2. LOB를 이용하는 방법

객체를 `serialize()` 함수 또는 `json_encode()`로 직렬화하고, 다시 역직렬화해서 객체로 재생할 수 있으면, 직렬화된 문자 덩어리를 LOB라 부릅니다. LOB는 컴퓨터가 읽기 편한 BLOB(Binary Large Object)와 사람이 읽을 수 있는 CLOB(Character Large Object)로 나눌 수 있습니다.

`serialize()` 함수로 직렬화해서 DB에 저장한 데이터는 PHP에서만 꺼내서 쓸 수 있는 반면, `json_encode()`로 직렬화하면 어떤 컴퓨터 언어에서든 꺼내서 쓸 수 있습니다. 즉 PHP 직렬화는 데이터가 PHP 프로그래밍 언어에 종속되는 결과를 초래하므로 신중하게 생각하고 결정해야 합니다.

1절에서 객체의 필드를 DB 컬럼에 일대일로 맵핑한 반면, LOB를 이용한 방법은 아래 그림처럼 객체를 DB 컬럼 하나에 맵핑하는 방법입니다.

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
| - address: json    |
+--------------------+
```

### 2.1. 스키마 마이그레이션

1절에서 주소 객체의 필드를 DB 컬럼으로 쭈욱 늘어 놓지 않고, 하나의 컬럼에 넣음으로서 스키마는 한결 간편해졌습니다.

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
            $table->json('address')->comment('고객 주소');
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('customers');
    }
}
```

```bash
$ php artisan migrate
#Migrating: 2019_02_07_000000_create_customers_table
#Migrated:  2019_02_07_000000_create_customers_table
```

### 2.2. 엔티티와 값 객체, 그리고 팩토리

1절에서 만든 주소 객체를 그대로 사용하고, `Customer` 모델만 조금 고쳤습니다.

```bash
$ git checkout attr-accessor-mutator -- app/Address.php app/JibunAddress.php app/RoadAddress.php app/Customer.php database/factories/CustomerFactory.php
```

`setAddressAttribute()` 변경자에서 `customers.address:json` 컬럼에 저장하기 위해 JSON으로 직렬화하는 부분을 주목해주세요.

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
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @mixin \Eloquent
 */
class Customer extends Model
{
    public function getAddressAttribute(string $address)
    {
        return AddressFactory::createFromJson($address);
    }

    public function setAddressAttribute(Address $address)
    {
        $this->attributes['address'] = json_encode($address->toArray());
    }
}
```

PHP 직렬화를 선택했다면 변경자에서 `json_encode()` 대신 `serialize()`로 직렬화해서 저장하고 `unserizlize()`로 꺼내서 바로 PHP 객체로 재생할 수 있습니다. 앞서 언급한 플랫폼 의존성을 피하고자 JSON 형식을 선택했고, DB에서 꺼내 쓸 때는 JSON을 객체로 재생해줘야 합니다. 이 역할을 `AddressFactory`클래스가 담당합니다.

```php
<?php // app/AddressFactory.php

namespace App;

class AddressFactory
{
    public static function createFromJson(string $json)
    {
        $u = json_decode($json);

        $j = $u->jibunAddress ?? null;
        $jibunAddress = new JibunAddress(
            $j->adminDongName ?? null,
            $j->legalDongName ?? null,
            $j->legalRiName ?? null,
            $j->isMountain ?? null,
            $j->jibunNumber ?? null
        );

        $r = $u->roadAddress ?? null;
        $roadAddress = new RoadAddress(
            $r->roadName ?? null,
            $r->isBasement ?? null,
            $r->buildingNumber ?? null
        );

        return new Address(
            $u->siDo ?? null,
            $u->siGunGu ?? null,
            $jibunAddress,
            $roadAddress,
            $u->detailAddress ?? null
        );
    }
}
```

`Address`, `JibunAddress`, `RoadAddress`의 필드 이름이 변경되거나, 추가, 삭제된 경우를 상상해보죠. 재생을 위한 설계도가 되는 클래스가 변경된 상태에서 다시 객체로 생성할 수 있을까요? JSON으로 직렬화했다면 가능합니다. PHP로 직렬화했다면 불가능합니다.

### 2.3. [Optional] 모델 팩토리

1절에서 만든 것을 그대로 사용합니다.

### 2.4. 테스트

아래 코드에서 `Customer.address` 필드에 JSON이 그대로 담겨있는게 보입니다. 엘로퀀트는 활성 레코드 패턴이라 모델 자체가 DB라 볼 수 있고, DB에서 읽은 컬럼의 값을 객체의 필드에 그냥 담아 놓은 것이라 보시면 됩니다. 

접근자를 호출했을 때 비로소 `Address` 객체로 바뀝니다. 접근자를 호출하는 방법은 접근자 함수를 직접 불러도 되지만, `$c1->address` 처럼 필드에 접근하면 호출됩니다. 아래 코드에서 접근자에서 `AddressFactory`를 이용해서 `App\Address {#2958}`로 재생한 것을 볼 수 있습니다.

```bash
$ php artisan tinker
# 엔티티 생성 및 영속화
>>> $c1 = factory(App\Customer::class)->create();
=> App\Customer {#2963
     name: "Ms. Yadira Beatty III",
     address: "{"siDo":"\uc11c\uc6b8\ud2b9\ubcc4\uc2dc","siGuGu":"\uac15\ub0a8\uad6c","jibunAddress":{"adminDongName":"\uc0bc\uc1311\ub3d9","legalDongName":"\uc0bc\uc131\ub3d9","legalRiName":null,"isMountain":false,"jibunNumber":"162-17"},"roadAddress":{"roadName":"\ubd09\uc740\uc0ac\ub85c112\uae38","isBasement":false,"buildingNumber":"6"},"detailAddress":"\uc775\uc131\ube4c\ub529 5\uce35 \uba54\uc26c\ucf54\ub9ac\uc544"}",
     updated_at: "2019-02-07 15:07:49",
     created_at: "2019-02-07 15:07:49",
     id: 1,
   }
>>> $c2 = factory(App\Customer::class)->create();
=> App\Customer {#2969
     name: "Pattie Crist PhD",
     address: "{"siDo":"\uc11c\uc6b8\ud2b9\ubcc4\uc2dc","siGuGu":"\uac15\ub0a8\uad6c","jibunAddress":{"adminDongName":"\uc0bc\uc1311\ub3d9","legalDongName":"\uc0bc\uc131\ub3d9","legalRiName":null,"isMountain":false,"jibunNumber":"162-17"},"roadAddress":{"roadName":"\ubd09\uc740\uc0ac\ub85c112\uae38","isBasement":false,"buildingNumber":"6"},"detailAddress":"\uc775\uc131\ube4c\ub529 5\uce35 \uba54\uc26c\ucf54\ub9ac\uc544"}",
     updated_at: "2019-02-07 15:07:54",
     created_at: "2019-02-07 15:07:54",
     id: 2,
   }

# 엔티티 및 값 객체의 필드 접근
>>> $c1->address;
=> App\Address {#2958}

>>> $c1->address->getSiDo();
=> "서울특별시"

>>> $c1->address->getJibunAddress()->getJibunNumber();
=> "162-17"

>>> $c1->address->toArray();
=> [
     "siDo" => "서울특별시",
     "siGuGu" => null,
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
       "name" => "Ms. Yadira Beatty III",
       "address" => App\Address {#2977},
       "created_at" => "2019-02-07 15:07:49",
       "updated_at" => "2019-02-07 15:07:49",
     ],
     [
       "id" => 2,
       "name" => "Pattie Crist PhD",
       "address" => App\Address {#2961},
       "created_at" => "2019-02-07 15:07:54",
       "updated_at" => "2019-02-07 15:07:54",
     ],
   ]
```

쿼리도 해 볼까요?

```sql
SELECT * FROM customers;
/*
{
    "data":
    [
        {
            "id": 1,
            "name": "Ms. Yadira Beatty III",
            "address": "{\"siDo\": \"서울특별시\", \"siGuGu\": \"강남구\", \"roadAddress\": {\"roadName\": \"봉은사로112길\", \"isBasement\": false, \"buildingNumber\": \"6\"}, \"jibunAddress\": {\"isMountain\": false, \"jibunNumber\": \"162-17\", \"legalRiName\": null, \"adminDongName\": \"삼성1동\", \"legalDongName\": \"삼성동\"}, \"detailAddress\": \"익성빌딩 5층 메쉬코리아\"}",
            "created_at": "2019-02-07 15:07:49",
            "updated_at": "2019-02-07 15:07:49"
        },
        {
            "id": 2,
            "name": "Pattie Crist PhD",
            "address": "{\"siDo\": \"서울특별시\", \"siGuGu\": \"강남구\", \"roadAddress\": {\"roadName\": \"봉은사로112길\", \"isBasement\": false, \"buildingNumber\": \"6\"}, \"jibunAddress\": {\"isMountain\": false, \"jibunNumber\": \"162-17\", \"legalRiName\": null, \"adminDongName\": \"삼성1동\", \"legalDongName\": \"삼성동\"}, \"detailAddress\": \"익성빌딩 5층 메쉬코리아\"}",
            "created_at": "2019-02-07 15:07:54",
            "updated_at": "2019-02-07 15:07:54"
        }
    ]
}
*/
```

1편에서 언급했다시피 컬럼이 쪼개져 있지 않아서, 쿼리하기는 불편합니다. JSON 컬럼으로 선언했다면 아주 불가능하지는 않지만요...

```sql
SELECT 
    id,
    name,
    JSON_EXTRACT(address, "$.siDo") as SI_DO_NAME
FROM customers;

/*
id  name    SI_DO_NAME
1   Ms. Yadira Beatty III   "서울특별시"
2   Pattie Crist PhD    "서울특별시"
*/
```

## 3. 참조를 이용하는 방법

`customers` 테이블과 `customer_addresses` 테이블로 나누고, 각각의 엘로퀀트 모델을 만든 후, `HasOne`/`BelongsTo` 관계로 연결하는 방법입니다. 데이터 중심적인 설계를 하면 이런 결과가 나오는데, 객체 지향스럽지 않아서 권장하지 않습니다.

이는 엘로퀀트ORM의 한계이며, 독트린ORM을 사용하면 엔티티의 속성을 여러 테이블에 나누어 영속화하는 것이 가능합니다(see [https://www.doctrine-project.org/projects/doctrine-orm/en/2.6/tutorials/embeddables.html](https://www.doctrine-project.org/projects/doctrine-orm/en/2.6/tutorials/embeddables.html)).

```bash
+--------------------+
| class Customer     |
+--------------------+
| - name: string     |
| - address: CustomerAddress 
+--------------------+

+--------------------+
| table customers    |
+--------------------+
| - id: int          |
| - name: varchar    |
+--------------------+

+--------------------+
| table customer_addresses
+--------------------+
| - id: int          |
| - customer_id: int |
| - addr_si_do_name: varchar
| - addr_si_gun_gu_name: varchar
| - ...              |
| - addr_detail: varchar
+--------------------+
```

UML & ERD에 맞게 모델, 스키마 마이그레이션, 모델 팩토리를 만듭니다.

```bash
$ php artisan make:model CustomerAddress --migration --factory
#Model created successfully.
#Factory created successfully.
#Created Migration: 2019_02_07_000200_create_customer_addresses_table
```

### 3.1. 스키마 마이그레이션

```php
<?php // database/migrations/2019_02_07_000100_create_customers_table.php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreateCustomersTable extends Migration
{
    public function up()
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->increments('id');
            $table->string('name');
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('customers');
    }
}
```

```php
<?php // database/migrations/2019_02_07_000200_create_customer_addresses_table.php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreateCustomerAddressesTable extends Migration
{
    public function up()
    {
        Schema::create('customer_addresses', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('customer_id')->index();
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

            $table->foreign('customer_id')->references('id')->on('customers');
        });
    }

    public function down()
    {
        Schema::dropIfExists('customer_addresses');
    }
}
```

```bash
$ php artisan migrate
#Migrating: 2019_02_07_000100_create_customers_table
#Migrated:  2019_02_07_000100_create_customers_table
#Migrating: 2019_02_07_000200_create_customer_addresses_table
#Migrated:  2019_02_07_000200_create_customer_addresses_table
```

### 3.2. 엔티티

```php
<?php // app/Customer.php

namespace App;

use Illuminate\Database\Eloquent\Model;

/**
 * App\Customer
 *
 * @property int $id
 * @property string $name
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\CustomerAddress $address
 * @mixin \Eloquent
 */
class Customer extends Model
{
    public function address()
    {
        return $this->hasOne(CustomerAddress::class, 'customer_id', 'id');
    }
}
```

```php
<?php // app/CustomerAddress.php

namespace App;

use Illuminate\Database\Eloquent\Model;

/**
 * App\CustomerAddress
 *
 * @property int $id
 * @property int $customer_id
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
 * @property-read \App\Customer $customer
 * @mixin \Eloquent
 */
class CustomerAddress extends Model
{
    public function customer()
    {
        return $this->belongsTo(Customer::class, 'customer_id', 'id');
    }
}
```

### 3.3. [Optional] 모델 팩토리

```php
<?php // database/factories/CustomerAddressFactory.php

use Faker\Generator as Faker;

$factory->define(App\CustomerAddress::class, function (Faker $faker) {
    return [
        'addr_si_do_name' => '서울특별시',
        'addr_si_gun_gu_name' => '강남구',
        'addr_admin_dong_name' => '삼성1동',
        'addr_legal_dong_name' => '삼성동',
        'addr_legal_ri_name' => null,
        'addr_is_mountain' => false,
        'addr_jibun_number' => '162-17',
        'addr_road_name' => '봉은사로12길',
        'addr_is_basement' => 0,
        'addr_building_number' => '6',
        'addr_detail' => '익성빌딩 5층 메쉬코리아',
    ];
});
```

```php
<?php // database/factories/CustomerFactory.php

use Faker\Generator as Faker;

$factory->define(App\Customer::class, function (Faker $faker) {
    return [
        'name' => $faker->name,
    ];
});

$factory->afterCreating(App\Customer::class, function (App\Customer $customer, Faker $faker) {
    $customer->address()->save(factory(App\CustomerAddress::class)->make());
});
```

### 3.4. 테스트

`CustomerAddress` 모델은 기본 키(`id`)가 있어서 값 객체인지 엔티티인지 모호합니다. 당연히 `$c1->address` 와 `$c2->address`는 서로 다른 메모리 공간을 사용하고 객체의 식별자 해시도 완전히 다릅니다(물론 앞 절에서 처럼 동등 비교 함수를 구현하면 됩니다).

```bash
$ php artisan tinker
# 엔티티 생성 및 영속화
>>> $c1 = factory(App\Customer::class)->create();
=> App\Customer {#2963
     name: "Susanna Effertz",
     updated_at: "2019-02-07 15:32:16",
     created_at: "2019-02-07 15:32:16",
     id: 1,
   }

>>> $c2 = factory(App\Customer::class)->create();
=> App\Customer {#2971
     name: "Pink Gorczany MD",
     updated_at: "2019-02-07 15:32:38",
     created_at: "2019-02-07 15:32:38",
     id: 2,
   }

# 엔티티 및 값 객체의 필드 접근
>>> $c1->address;
=> App\CustomerAddress {#2961
     id: 1,
     customer_id: 1,
     addr_si_do_name: "서울특별시",
     addr_si_gun_gu_name: "강남구",
     addr_admin_dong_name: "삼성1동",
     addr_legal_dong_name: "삼성동",
     addr_legal_ri_name: null,
     addr_is_mountain: 0,
     addr_jibun_number: "162-17",
     addr_road_name: "봉은사로12길",
     addr_is_basement: 0,
     addr_building_number: "6",
     addr_detail: "익성빌딩 5층 메쉬코리아",
     created_at: "2019-02-07 15:32:16",
     updated_at: "2019-02-07 15:32:16",
   }

>>> $c1->address->addr_si_do_name;
=> "서울특별시"

>>> $c1->address->addr_jibun_number;
=> "162-17"

>>> $c1->address->toArray();
=> [
     "id" => 1,
     "customer_id" => 1,
     "addr_si_do_name" => "서울특별시",
     "addr_si_gun_gu_name" => "강남구",
     "addr_admin_dong_name" => "삼성1동",
     "addr_legal_dong_name" => "삼성동",
     "addr_legal_ri_name" => null,
     "addr_is_mountain" => 0,
     "addr_jibun_number" => "162-17",
     "addr_road_name" => "봉은사로12길",
     "addr_is_basement" => 0,
     "addr_building_number" => "6",
     "addr_detail" => "익성빌딩 5층 메쉬코리아",
     "created_at" => "2019-02-07 15:32:16",
     "updated_at" => "2019-02-07 15:32:16",
   ]

# 값 객체의 동등 비교
>>> $c1->address == $c2->address;
=> false

>>> $c1->address->is($c2->address);
=> false

# 값 객체를 이용한 콜렉션 필터링
>>> App\Customer::with('address')->get()->filter(function (App\Customer $c) {
...     return $c->address->addr_si_do_name === '서울특별시';
... })->toArray();
=> [
     [
       "id" => 1,
       "name" => "Susanna Effertz",
       "created_at" => "2019-02-07 15:32:16",
       "updated_at" => "2019-02-07 15:32:16",
       "address" => [
         "id" => 1,
         "customer_id" => 1,
         "addr_si_do_name" => "서울특별시",
         "addr_si_gun_gu_name" => "강남구",
         "addr_admin_dong_name" => "삼성1동",
         "addr_legal_dong_name" => "삼성동",
         "addr_legal_ri_name" => null,
         "addr_is_mountain" => 0,
         "addr_jibun_number" => "162-17",
         "addr_road_name" => "봉은사로12길",
         "addr_is_basement" => 0,
         "addr_building_number" => "6",
         "addr_detail" => "익성빌딩 5층 메쉬코리아",
         "created_at" => "2019-02-07 15:32:16",
         "updated_at" => "2019-02-07 15:32:16",
       ],
     ],
     [
       "id" => 2,
       "name" => "Pink Gorczany MD",
       "created_at" => "2019-02-07 15:32:38",
       "updated_at" => "2019-02-07 15:32:38",
       "address" => [
         "id" => 2,
         "customer_id" => 2,
         "addr_si_do_name" => "서울특별시",
         "addr_si_gun_gu_name" => "강남구",
         "addr_admin_dong_name" => "삼성1동",
         "addr_legal_dong_name" => "삼성동",
         "addr_legal_ri_name" => null,
         "addr_is_mountain" => 0,
         "addr_jibun_number" => "162-17",
         "addr_road_name" => "봉은사로12길",
         "addr_is_basement" => 0,
         "addr_building_number" => "6",
         "addr_detail" => "익성빌딩 5층 메쉬코리아",
         "created_at" => "2019-02-07 15:32:38",
         "updated_at" => "2019-02-07 15:32:38",
       ],
     ],
   ]
```

테이블이 쪼개져 있으니, 조인 쿼리를 하면 되겠네요.

```sql
SELECT * 
FROM customers AS c
LEFT JOIN customer_addresses AS a
    ON c.id = a.customer_id;

/*
{
    "data":
    [
        {
            "id": 1,
            "name": "Susanna Effertz",
            "created_at": "2019-02-07 15:32:16",
            "updated_at": "2019-02-07 15:32:16",
            "id": 1,
            "customer_id": 1,
            "addr_si_do_name": "서울특별시",
            "addr_si_gun_gu_name": "강남구",
            "addr_admin_dong_name": "삼성1동",
            "addr_legal_dong_name": "삼성동",
            "addr_legal_ri_name": null,
            "addr_is_mountain": 0,
            "addr_jibun_number": "162-17",
            "addr_road_name": "봉은사로12길",
            "addr_is_basement": 0,
            "addr_building_number": "6",
            "addr_detail": "익성빌딩 5층 메쉬코리아",
            "created_at": "2019-02-07 15:32:16",
            "updated_at": "2019-02-07 15:32:16"
        },
        {
            "id": 2,
            "name": "Pink Gorczany MD",
            "created_at": "2019-02-07 15:32:38",
            "updated_at": "2019-02-07 15:32:38",
            "id": 2,
            "customer_id": 2,
            "addr_si_do_name": "서울특별시",
            "addr_si_gun_gu_name": "강남구",
            "addr_admin_dong_name": "삼성1동",
            "addr_legal_dong_name": "삼성동",
            "addr_legal_ri_name": null,
            "addr_is_mountain": 0,
            "addr_jibun_number": "162-17",
            "addr_road_name": "봉은사로12길",
            "addr_is_basement": 0,
            "addr_building_number": "6",
            "addr_detail": "익성빌딩 5층 메쉬코리아",
            "created_at": "2019-02-07 15:32:38",
            "updated_at": "2019-02-07 15:32:38"
        }
    ]
}
*/
```

<!--more-->
<div class="spacer">• • •</div>

제가 아는 방법만 나열했을 뿐, 더 많은 방법들이 있을 겁니다. 설계 의사 결정은 각자의 몫입니다.

질문 하나 던져볼까요? 어느날 새로운 비즈니스 요구사항이 들어왔습니다. "고객은 주소를 하나 이상 가질 수 있다" 어떻게 설계하시겠습니까?
