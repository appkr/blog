---
layout: post-minimal
title: 'SQL Injection 방어'
date: 2018-10-20 00:00:00 +0900
categories:
- learn-n-think
tags:
- Database
- Security
image: https://imgs.xkcd.com/comics/exploits_of_a_mom.png
---

![Exploit of a mom](https://imgs.xkcd.com/comics/exploits_of_a_mom.png)
<small>그림출처: [Exploits of a Mom](https://xkcd.com/327/)</small>

```
Cut#1 (학교) 여기 학교인데요. 전화 드린 이유는, 학교에 컴퓨터 문제가 좀 있어서요.
```
```
Cut#2 (엄마) 우리 애가 사고쳤나요?
     (학교) 예... 일종의...
```
```
Cut#3 (학교) 그런데, 정말로 아들 이름을 "Robert'); DROP TABLE students;--" 로 지으신게 맞나요?
      (엄마) 예 맞아요. 그래서 집에서는 우리 애를 "리틀 바비 테이블"이라고 불러요.
```
```
Cut#4 (학교) ;;; 기뻐하실 지 모르겠지만, 학생 테이블의 레코드 전체를 잃어 버렸어요.
      (엄마) 적어도 이번 사건 덕분에 DB에 입력할 값을 잘 필터링 해야 한다는 사실 정도는 배우셨겠군요~
```

<div class="spacer">• • •</div>

프레임웍을 쓰면 쉽게 안전성을 확보할 수 있는데요. 그럼에도 불구하고, 아래 코드의 `queryStoresByParams()` 함수처럼 Raw 쿼리를 써야 할 때가 있죠. 이 때 SQL Injection을 당하지 않도록 주의해야 합니다.

```php
<?php // 회사 코드에서 일부 발췌

class StoreRetriever
{
    // 라라벨 프레임웍이 제공하는 엘로퀀트 ORM과 쿼리 빌더를 이용하는 경우
    // PDO와 Prepared Statement를 이용하므로 SQL Injection은 자동 방어됨
    public function retrieveStoresByParams(StoreSearchParamDto $dto, array $eagerLoads = [])
    {
        $builder = !empty($eagerLoads)
            ? Store::query()->with($eagerLoads)->select('stores.*')
            : Store::query()->select('stores.*');
        $this->applySearchParams($builder, $dto);
        $this->applyOrderBy($builder, $dto);

        return $builder->paginate($dto->getSize(), ['*'], 'page', $dto->getPage());
    }

    // Raw 쿼리를 쓸 때 사용자로부터 받은 문자열을 직접 쿼리에 끼워 넣으면 SQL Injection에 무방비 상태가 됨
    // e.g. $query[] = "and stores.created_at >= {$from}";
    //
    // 여기서 Raw 쿼리를 왜 썼는가? "성능". 소위 말하는 "Query Model"
    // PHP7 with Xdebug on Docker, 테이블 조인 5개 & 12,000 레코드 조회시 API 응답 시간
    // 	 - retrieveStoresByParams(): around N sec 
    //   - queryStoresByParams(): under N/10 sec
    public function queryStoresByParams(StoreSearchParamDto $dto, array $columns = ['stores.*'])
    {
        $columnString = implode(',', $columns);
        $query[] = "select {$columnString} from stores";
        $bindings = [];

        $query[] = "where 1 = 1";

        $from = $dto->getFrom();
        if ($from !== null) {
            $query[] = "and stores.created_at >= :from";
            $bindings['from'] = $from;
        }

        // ...

        return \DB::select(implode(' ', $query), $bindings);
    }

    private function applySearchParams(Builder $builder, StoreSearchParamDto $dto)
    {
        $from = $dto->getFrom();
        if ($from !== null) {
            $builder->where('stores.created_at', '>=', $from);
        }
    
        // ...
    }
    
    private function applyOrderBy(Builder $builder, StoreSearchParamDto $dto)
    {
        foreach ($dto->getOrderBy() as $order) {
            $builder->orderBy($order['sortKey'], $order['sortDirection']);
        }
    }
}
```
