---
layout: post-minimal
title: 'MySQL 테이블 잠금 실험'
date: 2017-08-04 00:00:00 +0900
categories:
- cheatsheet
tags:
- 개발자
- 데이터베이스
---

MySQL의 잠금 특성을 확인하기 위한 실험 결과입니다.
1. 읽기 잠금의 동작 특성
2. 쓰기 잠금의 동작 특성
3. 트랜잭션과 Row 잠금
4. 라라벨에서 트랜잭션과 잠금

<!--more-->
<div class="spacer">• • •</div>

테스트 테이블 생성

```sql
CREATE DATABASE lock_test 
DEFAULT CHARACTER SET = utf8 DEFAULT COLLATE = utf8_unicode_ci;

CREATE TABLE messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  message VARCHAR(140)
) ENGINE=INNODB;

SHOW TABLE STATUS WHERE NAME = "messages";
```

## 1. 읽기 잠금의 동작 특성

```sql
mysql1> LOCK TABLES messages READ;
mysql1> SHOW PROCESSLIST; -- Query ok
```

```sql
-- 다른 프로세스(=~커넥션=~세션)에서 실행
mysql2> LOCK TABLES messages WRITE; -- ...
```

`mysql1` 프로세스에서 테이블 전체에 대해 읽기 잠금을 걸었으므로, `mysql2` 프로세스는 무한 뺑글이.

```sql
mysql1> SHOW PROCESSLIST; -- "Waiting for table metadata lock" <= mysql2 프로세스의 상태
mysql1> UNLOCK TABLES;
```

`mysql1`이 테이블 잠금을 푸는 순간 `mysql2` 프로세스는 뺑글이 사라지고, 쓰기 잠금 얻어감.

```sql
mysql1> SELECT * FROM messages; -- ...
```

`mysql2` 프로세스가 테이블에 대해 쓰기 잠금을 얻어 갔으므로, `mysql1` 프로세스는 무한 뺑글이.
 
 ```sql
-- 무한 뺑글이 돌던 SELECT 쿼리 취소 후
mysql1> UNLOCK TABLES;
mysql1> SHOW OPEN TABLES FROM lock_test; -- 1
```

`mysql2` 프로세스가 잠금을 가지고 있으므로 다른 프로세스에서 잠금 해제 불가.

```sql
mysql2> UNLOCK TABLES;
```

```sql
mysql1> SELECT * FROM messages; -- Query ok.
mysql1> LOCK TABLES messages READ;
mysql1> SELECT * FROM messages; -- Query ok.
```

```sql
mysql2> SELECT * FROM messages; -- Query ok.
mysql2> INSERT INTO messages (message) VALUES ('FOO'); -- ...
```

`mysql1` 프로세스가 읽기 잠금을 걸었으므로, `mysql2` 프로세스에서도 읽기는 가능하지만, 쓰기를 시도하면 무한 뺑글이.

```sql
mysql1> INSERT INTO messages (message) VALUES ('BAR'); -- Table 'messages' was locked with a READ lock and can't be updated
```

읽기 잠금을 건 `mysql1` 프로세스도 쓰기 불가능을 마찬가지임.

```sql
mysql1> UNLOCK TABLES;
```

테이블에 걸린 모든 잠금이 풀렸으므로, 뺑글이를 돌던 `mysql2`의 뺑글이는 사라지고 `INSERT` 쿼리가 작동함.
 
 ```sql
mysql1> SELECT * FROM messages;
```

`mysql2` 프로세스에서 `INSERT`한 레코드 확인 가능.

### 1.1. 결론

-   `READ`/`WRITE` 무관한게 먼저 테이블을 잠근 프로세스가 잠금을 반환하기 전에 다른 프로세스는 잠금을 얻을 수 없다.
-   `READ` 잠금이 걸린 상태에서 
    -   다른 프로세스에서 테이블을 읽는 것은 가능하다. 
    -   `READ` 잠금은 건 프로세스를 포함해 모든 프로세스에서 테이블에 쓰기 작업은 할 수 없다.   
    -   잠금을 가진 프로세스에서 쓰기를 시도하면 바로 오류가 발생하지만, 다른 프로세스에서는 잠금이 풀릴 때 까지 기다린다.

## 2. 쓰기 잠금의 동작 특성

```sql
mysql1> LOCK TABLES messages WRITE;
mysql1> INSERT INTO messages (message) VALUES ('BAZ');
mysql1> SELECT * FROM messages; -- Query ok.
```

```sql
mysql2> SELECT * FROM messages; -- ...
```

`mysql2` 프로세스에서는 무한 뺑글이.

```sql
mysql1> RENAME TABLE messages TO new_messages; -- Can't execute the given command because you have active locked tables or an active transaction
```

`WRITE` 잠금을 가진 `mysql1` 프로세스지만, 테이블 이름을 변경하는 등의 DDL은 불가능함.

```sql
mysql1> UNLOCK TABLES;
```

테이블에 걸린 모든 잠금이 풀렸으므로, 뺑글이를 돌던 `mysql2`의 뺑글이는 사라지고 `SELECT` 쿼리가 작동함.

### 2.1. 결론

-   `WRITE` 잠금을 가진 프로세스에서만 읽기, 쓰기 가능하다.
-   다른 프로세스에서는 잠금이 풀릴 때가지 읽기, 쓰기 모두 불가능하다.

## 3. 트랜잭션과 Row 잠금

`SELECT ... LOCK IN SHARE MODE` for READ, `SELECT ... FOR UPDATE` for UPDATE and DELETE.

```sql
mysql1> START TRANSACTION; 
mysql1> SELECT * FROM messages WHERE id = 1 LOCK IN SHARE MODE;
```

```sql
mysql2> SELECT * FROM messages WHERE id = 1; -- Query ok.
mysql2> START TRANSACTION; 
mysql2> DELETE FROM messages WHERE id = 1; 
mysql2> COMMIT; -- ...
-- Lock wait timeout exceeded; try restarting transaction
```

`mysql1` 프로세스에서 1번 Row를 잠궜지만, `mysql2` 프로세스에서 읽기는 가능. 반면, 쓰기 동작을 하려하면 50초 동안 뺑글이를 돌다가 쿼리 실패함. 50초에 대한 힌트는 아래 쿼리에서 찾을 수 있음.

```sql
mysql> SHOW VARIABLES WHERE VARIABLE_NAME LIKE "%innodb_lock%"; -- innodb_lock_wait_timeout: 50
```

```sql
mysql2> DELETE FROM messages WHERE id = 1; 
mysql2> COMMIT; -- ...
```

`mysql2` 프로세스에서 뺑글이가 돌고 있는 상태에서 쨉싸게 `mysql1` 프로세스에서 같은 Row 1번을 지움.

```sql
mysql1> DELETE FROM messages WHERE id = 1; 
mysql1> COMMIT; -- No errors; 1 row affected
```

한편 mysql2 프로세스에서는... 데드락이 발생함.

```sql
-- [ERROR in query 2] Deadlock found when trying to get lock; try restarting transaction
mysql2> SHOW ENGINE INNODB STATUS;
```

### 3.1. 결론

-   Row 잠금이 걸려도 다른 프로세스에서 읽기는 가능하지만, 쓰기는 불가능하다.
-   Row 잠금이 걸린 상태에서 다른 프로세스에서 쓰기를 시도하려 하면, `innodb_lock_wait_timeout` 옵션으로 설정된 시간 만큼 기다리다가 잠금을 얻는 것을 포기하고 쿼리 실패한다.
-   같은 Row에 대해 여러 개의 프로세스가 동시에 쓰기를 시도할 때 Dead Lock(교착상태)이 발생할 수 있다.

## 4. 라라벨에서 트랜잭션과 잠금

```php
<?php // https://github.com/appkr/db-lock-poc/blob/master/core/Myshop/Infrastructure/Eloquent/EloquentProductRepository.php#L22-L25

DB::beginTransaction();

try {
    $product = Product::lockForUpdate()->findOrFail($id);
    $product->prime = 10000;
    $product->save();
    DB::commit();
} catch (\Exception $e) {
    DB::rollBack();
    throw $e;
}
```

<div class="spacer">• • •</div>

```sql
-- http://minsql.com/mysql/information_schema-innodb_xxx-%EB%A5%BC-%ED%99%9C%EC%9A%A9%ED%95%9C-lock-%EC%A0%95%EB%B3%B4-%ED%99%95%EC%9D%B8/

mysql> SELECT connection_id();

mysql> SELECT * FROM information_schema.INNODB_LOCK_WAITS;

mysql> SELECT * FROM information_schema.INNODB_LOCKS;

mysql> SELECT * FROM information_schema.INNODB_TRX;

mysql> SELECT straight_join
   w.trx_mysql_thread_id waiting_thread,
   w.trx_id waiting_trx_id,
   w.trx_query waiting_query,
   b.trx_mysql_thread_id blocking_thread,
   b.trx_id blocking_trx_id,
   b.trx_query blocking_query,
   bl.lock_id blocking_lock_id,
   bl.lock_mode blocking_lock_mode,
   bl.lock_type blocking_lock_type,
   bl.lock_table blocking_lock_table,
   bl.lock_index blocking_lock_index,
   wl.lock_id waiting_lock_id,
   wl.lock_mode waiting_lock_mode,
   wl.lock_type waiting_lock_type,
   wl.lock_table waiting_lock_table,
   wl.lock_index waiting_lock_index
 FROM
   information_schema.INNODB_LOCK_WAITS ilw ,
   information_schema.INNODB_TRX b , 
   information_schema.INNODB_TRX w , 
   information_schema.INNODB_LOCKS bl , 
   information_schema.INNODB_LOCKS wl
 WHERE
   b.trx_id = ilw.blocking_trx_id
   AND w.trx_id = ilw.requesting_trx_id
   AND bl.lock_id = ilw.blocking_lock_id
   AND wl.lock_id = ilw.requested_lock_id;
```
