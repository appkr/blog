---
layout: post-minimal
title: '라라벨 마이크로서비스 예제'
date: 2021-02-13 00:00:00 +0900
categories:
- work-n-play
tags:
- PHP
- Laravel
- MSA
- Oauth2
image: /images/2021-02-13-monolithic.png
---

모노리틱<small class="text-muted">monolithic</small> 서비스 구조에서 마이크로 서비스 구조로 전환을 고려할 때 가장 먼저 고려해야할 모듈은 사용자 인증 부분입니다, 아래 그림처럼 말이죠. 

![](/images/2021-02-13-monolithic.svg)
<div class="text-center"><small>모노리틱 서비스 구조</small></div>

![](/images/2021-02-13-microservice.svg)
<div class="text-center"><small>마이크로 서비스 구조</small></div>

이 포스트에서는 라라벨 프레임워크로 마이크로 서비스를 만들때 UAA<small class="text-muted">User Account and Authentication</small> 서버와 연동하는 예제를 설명합니다. 기존의 모노리틱 서비스를 마이크로 서비스로 이전하는 방법은 설명하지 않습니다. 그리고, UAA는 [JhipsterUaa](https://www.jhipster.tech/using-uaa/)를 이용합니다; [Keycloak](https://www.keycloak.org/), [Laravel Passport](https://laravel.com/docs/8.x/passport) 등의 OAuth2 서비스를 사용해도 유사한 방법으로 연동할 수 있습니다.

<!--more-->
<div class="spacer">• • •</div>

## 1 큰 그림

![](/images/2021-02-13-microservice2.svg)

### 각 콤포넌트 설명

#### Client
- curl 또는 postman

#### UAA
- [JhipsterUaa](https://www.jhipster.tech/using-uaa/)
- Port 9999
- 단순함을 위해 `Client`, `Authority` 등의 서브 도메인은 그림에서 생략함
- 단순함을 위해 인증을 위한 엔드포인트외의 리소스 엔드포인트는 표에서 생략함

엔드포인트|설명
---|---
`POST /oauth/token`|토큰 획득 및 갱신
`GET /oauth/token_key`|토큰 인코드, 디코드를 위한 공개키 조회

그랜트|client_id|client_secret
---|---|---
Password|`web_app`|`changeit`
ClientCredentials|`internal`|`internal`

```bash
$ wget https://github.com/appkr/msa-starter/raw/master/jhipster-uaa.zip
$ unzip jhipster-uaa.zip && cd jhipster-uaa && ./gradlew clean bootRun
```

#### Laravel 
- Example 도메인
- 인증/인가된 사용자만 ExampleAPI 사용 가능
- Port 8000

```bash
$ docker-compose -f docker/docker-compose.yml up
```

#### Spring
- Hello 도메인
- 인증/인가된 사용자만 HelloAPI 사용 가능
- Port 8080

```bash
$ cd hello-service && ./gradlew clean bootRun
```

### ① 로그인 및 토큰 획득
- Client는 `web_app`/`changeit` 사용자 계정과 Password 그랜트를 이용하여 `UAA`로부터 JWT<small class="text-muted">Json Web Token</small>를 발급 받는다
```bash
$ RESPONSE=curl -L -X POST 'http://localhost:9999/oauth/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Accept: application/json' \
  -H 'Authorization: Basic  d2ViX2FwcDpjaGFuZ2VpdA==' \
  --data-urlencode 'grant_type=password' \
  --data-urlencode 'username=user' \
  --data-urlencode 'password=user' \
  --data-urlencode 'scope=openid'
```
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJ1c2VyIiwic2NvcGUiOlsib3BlbmlkIl0sImV4cCI6MTYxMjQ5ODAyMywiaWF0IjoxNjEyNDk3NzIzLCJhdXRob3JpdGllcyI6WyJST0xFX1VTRVIiXSwianRpIjoiREJmM0g0NHRlVFhOVmNEWjBBeWJTQUY3dFBZIiwiY2xpZW50X2lkIjoid2ViX2FwcCJ9.Y4py8MMHJdMwbXxpocdQPrMEevRnl2nkEUuXw6UeRmtB7qWDFADmzO-xQz8Hkvmz2LT0U4gPSHvRSOEWGuZ_Nack8MRU7ICWGRl53WZyiPTzt7ucLcO0w1eOBUPFxsHQHffyZ4XzrDJWlqWadhzlnxw9oJUcvi8aAKkBtBSVOCslxYMkBNzs7vjxbLHNQIAjZbb1YetBzpAQOq8RJCdSQNDcMSZ9eZG705ucaFBv3LgDf5sxK47Yqqqk3oCMDdyMXB2MW2bsFivpf6BZd3ydfHrCgcrU5y2Vl2g6fG6PsADkaJ4Fv31UdVj0QG-kX8fgj9GL7MjZUyI-bWruiLNTgw",
  "token_type": "bearer",
  "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJ1c2VyIiwic2NvcGUiOlsib3BlbmlkIl0sImF0aSI6IkRCZjNINDR0ZVRYTlZjRFowQXliU0FGN3RQWSIsImV4cCI6MTYxMzEwMjUyMywiaWF0IjoxNjEyNDk3NzIzLCJhdXRob3JpdGllcyI6WyJST0xFX1VTRVIiXSwianRpIjoicDhWQVB5aWhHU3NGYXlma1pMWnd1MURLSHBrIiwiY2xpZW50X2lkIjoid2ViX2FwcCJ9.gD4uoRwk_kbX19uUBxnUdvmu3KDZBrTLWeY0h6lj-UVvhKaUF7BNH1AzwSfX10y-tYjdfElk7_m7x6Vo9gG93HMUPtnSQPPNknI6KcE4sFRRs-Wk15o74S7ukiSjvdtq9Bx2u7t6EEd3e1UHHcRYLFwxJUND53YRM7VR38QWhJgxGW6aA6EK4Rz7fgqFaylK8xWlFjhYoFl3w_VBErqDZWyprKRl9IDDrd6xCo-5RIauuLGGvMTim9IhedaSwTDN7fJz68tyJinfejIjEVjnw90MPCAKzwYY2As30i7AdIPzUrvJPHSjhlZnZ9lSU6_BufQUw1caBQe-vSbtXx0pMw",
  "expires_in": 299,
  "scope": "openid",
  "iat": 1612497723,
  "jti": "DBf3H44teTXNVcDZ0AybSAF7tPY"
}
```

### ② ExampleAPI 사용 
- `Client`는 발급 받은 JWT로 `Laravel` 서비스의 Example 리소스를 조회하고 변경한다
```bash
$ ACCESS_TOKEN=$(echo $RESPONSE | jq .access_token | xargs)
$ curl -s -H 'Accept:application/json' -H "Authorization: bearer ${ACCESS_TOKEN}" http://localhost:8000/api/examples
```
```json
{
  "data": [
    {
      "id": 1,
      "title": "이문세 5집",
      "created_at": "2021-02-05T02:18:46.000000Z",
      "updated_at": "2021-02-05T02:18:46.000000Z",
      "created_by": "d593f9ef-d089-44fe-abe7-05c30219bb4c",
      "updated_by": "d593f9ef-d089-44fe-abe7-05c30219bb4c"
    }
  ],
  "page": {
    "size": 10,
    "totalElements": 1,
    "totalPages": 1,
    "number": 1
  }
}
```

### ③ Laravel -> HelloAPI 사용
- `Laravel` 서비스는 `internal`/`internal` 클라이언트 계정과 ClientCredentials 그랜트를 이용하여 UAA로부터 JWT를 발급 받는다
- 발급 받은 JWT로 HelloAPI 리소스를 조회한다

```bash
curl -s -H 'Accept:application/json' -H "Authorization: bearer ${ACCESS_TOKEN}" http://localhost:8000/api/hello
```
```json
"Hello from non-laravel service"
```

### ④ 토큰 유효성 검사
- `Laravel`, `Spring` 서비스는 클라이언트가 제출한 JWT의 유효성 검증을 위해 `UAA`로부터 공개키를 조회한다

```bash
$ curl -L -X GET 'http://localhost:9999/oauth/token_key'
{
    "alg": "SHA256withRSA",
    "value": "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlo/L8mU9Isiihp1ksxeOrJzPn4915xZC/pnbO+ur/ccZL23BYHP/wUxpWZy8Gh94+GK8/gcjVEk66acg4Gk7NH0uQGxdrq8WDMywPIAawekwiQJd6l/yVNXIDhuk0LzcgmU+1ESyeTNdlx84Z0X3HI6w8SH6OE4RBcr9rGfIt0ytXmHj1P4zxmJt/YhZyyyUq0WGuBq31UaQTOiJa0rp1kDKSMN0Hvz4UmkYtUvgtqUujrqNcWkSEummO8WyuhnCs+zAaF2KA5XSalEXFNiILwFPtQFxqIQrjjiWcI61vvTxtor4zI5r4X6aDteYIJidAzYwkIiuacnLWX5ziL3j+wIDAQAB\n-----END PUBLIC KEY-----"
}
```

## 2 OAuth2 이해하기
## 3 JWT 이해하기
## 4 구현
## 5 검증
## 6 요약

전체 예제코드는 [https://github.com/appkr/laravel-msa-example](https://github.com/appkr/laravel-msa-example)에서 볼 수 있습니다.

<p class="lead">To be continued...</p> 

<!--
{:.linenos}
```php
```
-->
