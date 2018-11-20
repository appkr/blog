---
layout: post-minimal
title: 'One to Many 조인에서 Many 쪽 최종 레코드만 조회하기'
date: 2018-11-20 00:00:00 +0900
categories:
- work-n-play
tags:
- Database
---

> 고객 목록에 고객별 최근 주문 1건에 대한 요약 정보를 보여주세요.

라는 요구사항이 있습니다.

"고객" 객체와 "주문" 객체간의 관계는 다음과 같습니다.

```
+------------+           0..* +------------+
|  Customer  | <>-----------> |   Order    |
+------------+                +------------+
```

애플리케이션 레이어에서 구현한다면, ORM을 통해 구한 `Collection<Customer>`을 순회하면서, `Customer`객체의 멤버 필드인 `Collection<Order>`를 대상으로 최근 Order 객체만 필터링했거나, 적절한 순서로 정렬하여 뽑아 쓰기 쉽도록 했을겁니다. 요런 느낌으로요(검증 안된 Pseudo Code 입니다).

```php
// Service Layer
public function listCustomers()
{
    return $customers->map(function (Customer $customer) {
        $sorted = $customer->orders->sortByDesc('id')->values();
        $customer->setRelation('orders', $sorted);
        return $customer;
    });
}

// Controller/View 등
foreach ($customers as $customer) {
    $lastOrder = $customer->orders->first();
    $lastOrder->order_number; // 최근 주문 번호   
}
```

문제점들이 눈에 띕니다.

- 시간복잡도는 O(m x n)입니다.
- CPU와 메모리를 혹사시킵니다.
- `Customer.orders: Collection<Order>`를 미리 로드하지 않았다면, N + 1 문제가 발생합니다.
- 이 외에도 제가 보지 못한 문제점들이 더 있을 겁니다...

읽기 전용 쿼리이므로 ORM을 쓰지 않아도 됩니다. 싸고, 빠르고, 안전하게 SQL만으로 뽑아내는 방법을 찾아봤습니다. 

<!--more-->
<div class="spacer">• • •</div>

## 1. 테이블 스키마

간결함을 위해 주변 테이블과 정규화등은 모듀 생략합니다(e.g. `order_lines`, `products`, ...).

```
+------------+                +------------+
|  customers | -|----------o< |   orders   |
+------------+                +------------+
```

```sql
CREATE TABLE customers (
  customer_id int(11) unsigned NOT NULL AUTO_INCREMENT,
  name varchar(40),
  zipcode varchar(5),
  phonenumber varchar(13),
  PRIMARY KEY (customer_id)
);
```

```sql
INSERT INTO customers (name, zipcode, phonenumber)
VALUES ('이덕승', '34603', '01012345678'),
       ('임희일', '06035', '01011112222'),
       ('신초아', '06611', '01043218765')
;
```

```sql
CREATE TABLE orders (
  order_number int(11) unsigned NOT NULL AUTO_INCREMENT,
  customer_id int(11) unsigned,
  order_total int(11),
  created_at datetime,
  PRIMARY KEY (order_number),
  CONSTRAINT orders_customer_id_foreign FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);
```

```sql
INSERT INTO orders (customer_id, order_total, created_at)
VALUES (1, 150, "2018-01-01 12:00:00"),
       (1, 120, "2018-08-25 13:00:00"),
       (1, 200, "2018-11-20 14:00:00"),
       (3, 100, "2018-05-05 09:00:00"),
       (3, 100, "2018-10-01 10:00:00"),
;
```

## 2. 고객과 주문 테이블 LEFT 조인

고객번호 1번 "이덕승" 고객의 주문 3건과, 고객번호 3번 "신초아" 고객의 주문 2건, 한번도 주문한 적이 없는 고객번호 2번 "임희일" 고객의 NULL을 포함해 총 6건의 결과가 출력됩니다.

```sql
SELECT 
    c.customer_id AS cid,
    o1.order_number AS o1n
FROM customers AS c
LEFT JOIN orders AS o1 ON c.customer_id = o1.customer_id
; -- No errors; 6 rows affected
```

```bash
cid o1n
1   1
1   2
1   3
2   NULL
3   4
3   5
```

참고로, 한번이라도 주문한 고객의 고객별...과 같은 요구사항이었다면, LEFT JOIN 대신 INNER JOIN을 이용했을테고, 5건의 결과가 출력됐을 겁니다.

## 3. 고객과 주문 테이블 LEFT 조인

조인은 두 테이블을 조인해 중간 결과 집합을 만든 후, 이 결과 집합과 다음 테이블을 조인하는 식으로 동작한다고 알고 있습니다. 2절의 선행 조인에서 만들어진 결과 집합의 각 로우와 주문 테이블 o2를 한번 더 LEFT 조인합니다. 

```sql
SELECT 
    c.customer_id AS cid,
    o1.order_number AS o1n,
    o2.order_number AS o2n
FROM customers AS c
LEFT JOIN orders AS o1 ON c.customer_id = o1.customer_id
LEFT JOIN orders AS o2 ON c.customer_id = o2.customer_id
; -- No errors; 14 rows affected
```

```bash
cid o1n o2n
1   1   1
1   1   2
1   1   3
1   2   1
1   2   2
1   2   3
1   3   1
1   3   2
1   3   3
2   NULLNULL
3   4   4
3   4   5
3   5   4
3   5   5
```

- 선행 결과 집합의 {cid:1, o1n:1} 로우와 조인되는 주문 테이블 o2의 로우는 customer_id가 1인 로우 3개입니다. 
- 선행 결과 집합의 {cid:1, o1n:2} 로우와 조인되는 주문 테이블 o2의 로우는 customer_id가 1인 로우 3개입니다. 
- 선행 결과 집합의 {cid:1, o1n:3} 로우와 조인되는 주문 테이블 o2의 로우는 customer_id가 1인 로우 3개입니다.
- 선행 결과 집합의 {cid:2, o1n:NULL} 로우와 조인되는 주문 테이블 o2의 로우는 없습니다.
- 선행 결과 집합의 {cid:3, o1n:4} 로우와 조인되는 주문 테이블 o2의 로우는 customer_id가 3인 로우 2개입니다.
- 선행 결과 집합의 {cid:3, o1n:5} 로우와 조인되는 주문 테이블 o2의 로우는 customer_id가 3인 로우 2개입니다.

왜 결과가 14행이 나왔는지 이해되셨죠?

## 4. LEFT 조인 조건 추가

왼쪽 또는 오른쪽 어느 쪽이든 무관하지만, 여기서는 왼쪽(선행 결과 집합) 테이블의 레코드를 버리도록 하겠습니다. 버리는 조건은 "나한테 가위바위보 진 사람 전부 앉아!"와 비슷합니다. 왼쪽이 오른쪽보다 작은 주문번호를 가졌다면 버리는 겁니다.

주문번호가 더 크다면 더 최근에 주문한 건이며, 같은 고객을 대상으로 주문번호가 가장 큰 녀석을 골라내는 과정이라 이해할 수 있습니다. 버린다고 표현했지만, 엄밀히 말하면 LEFT JOIN의 조건식을 충족하지 못하는 것입니다. 

그런데 LEFT JOIN이므로 2절에서 도출한 선행 결과 집합은 그대로 유지해야 합니다. {cid:1, o1n:3} 및 {cid:3, o1n:5} 로우는 충족하는 오른쪽 값이 없네요. 그럼에도 선행 결과 집합 유지를 위해 NULL이라고 표현하고 있습니다.

```bash
cid o1n o2n
1   1   1   (1 < 1) 버림
1   1   2   (1 < 2) 남김
1   1   3   (1 < 3) 남김
1   2   1   (2 < 1) 버림
1   2   2   (2 < 2) 버림
1   2   3   (2 < 3) 남김
1   3   1   (3 < 1) 버림
1   3   2   (3 < 2) 버림
1   3   3   (3 < 3) 버림
3   4   4   (4 < 4) 버림
3   4   5   (4 < 5) 남김
3   5   4   (5 < 4) 버림
3   5   5   (5 < 5) 버림
```

```sql
SELECT 
    c.customer_id AS cid,
    o1.order_number AS o1n,
    o2.order_number AS o2n
FROM customers AS c
LEFT JOIN orders AS o1 ON c.customer_id = o1.customer_id
LEFT JOIN orders AS o2 ON c.customer_id = o2.customer_id
    AND o1.order_number < o2.order_number
; -- No errors; 7 rows affected
```

```sql
cid o1n o2n
1   1   2
1   1   3
1   2   3
1   3   NULL
2   NULLNULL
3   4   5
3   5   NULL
```

이해를 돕기 위해 (사실은 제가 이해하기 위해) 3절과 4절을 구분 동작으로 표현했지만, 실제로는 연속 동작으로 진행됩니다.  

## 5. WHERE 조건절 추가

부등 조인 조건의 결과가 없다는 것은 가장 큰 값이란 의미입니다. 따라서 o2 테이블 쪽에 NULL을 품고 있는 로우가 고객별 최근 주문입니다.

```sql
SELECT 
    c.customer_id AS cid,
    o1.order_number AS o1n,
    o2.order_number AS o2n
FROM customers AS c
LEFT JOIN orders AS o1 ON c.customer_id = o1.customer_id
LEFT JOIN orders AS o2 ON c.customer_id = o2.customer_id
    AND o1.order_number < o2.order_number
WHERE o2.order_number IS NULL   
; -- No errors; 2 rows affected
```

```bash
cid o1n o2n
1   3   NULL
2   NULLNULL
3   5   NULL
```

## 6. 최종 쿼리

고객 목록에 최근 주문 요약을 표현하기 위한 최종 쿼리입니다.

```sql
SELECT 
    c.customer_id AS "고객번호", 
    c.name AS "고객명",
    o1.order_number AS "주문번호",
    o1.order_total AS "주문금액",
    o1.created_at AS "주문일시"
FROM customers AS c
LEFT JOIN orders AS o1 ON c.customer_id = o1.customer_id
LEFT JOIN orders AS o2 ON c.customer_id = o2.customer_id
    AND o1.order_number < o2.order_number
WHERE o2.order_number IS NULL   
; -- No errors; 2 rows affected
```

```bash
고객번호  고객명  주문번호  주문금액  주문일시
1       이덕승  3       200    2018-11-20 14:00:00
3       신초아  5       100    2018-10-01 10:00:00
2       임희일  NULL    NULL   NULL
```

## 7. 애플리케이션에서 어떻게 사용해요?

대략 이런 모습일겁니다(검증 안된 Pseudo Code 입니다).

```php
// Service Layer
public function queryCustomersWithRecentOrderSummary()
{
    $builder = Customer::query();
    $builder->leftJoin('orders AS o1', 'customers.customer_id', '=', 'o1.customer_id');
    $builder->leftJoin('orders AS o2', function ($join) {
        $join->on('customers.customer_id', '=', 'o2.customer_id');
        $join->on('o2.order_number', '<', 'o1.order_number');
    });
    $builder->whereNull('o2.order_number');
    $builder->select(['customers.*', 'o1.*']);
    return $builder->get();
}
```

이상 쿼리는 MySQL에서만 검증했습니다. 제가 DB 전문가가 아니므로, 본문에 사용한 용어들이 정확하지 않을 수 있습니다.
