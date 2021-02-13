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

모노리틱<small class="text-muted">monolithic</small> 서비스 구조에서 마이크로 서비스 구조로 전환을 고려할 때 가장 먼저 고려해야할 모듈은 사용자 인증입니다, 아래 그림처럼 말이죠. 

![](/images/2021-02-13-monolithic.svg)
<div class="text-center"><small>모노리틱 서비스 구조</small></div>

![](/images/2021-02-13-microservice.svg)
<div class="text-center"><small>마이크로 서비스 구조</small></div>

이 포스트에서는 라라벨 프레임워크로 마이크로 서비스를 만들때 UAA<small class="text-muted">User Account and Authentication</small> 서버와 연동하는 예제를 설명합니다. 기존의 모노리틱 서비스를 마이크로 서비스로 이전하는 방법은 설명하지 않습니다. 그리고, UAA는 [JhipsterUaa](https://www.jhipster.tech/using-uaa/)를 이용합니다; [Keycloak](https://www.keycloak.org/), [Laravel Passport](https://laravel.com/docs/8.x/passport) 등의 OAuth2 서비스를 사용해도 유사한 방법으로 연동할 수 있습니다.

<!--more-->
<div class="spacer">• • •</div>

## 1 큰 그림

![](/images/2021-02-13-microservice2.svg)
<div class="text-center"><small>마이크로 서비스 콤포넌트</small></div>

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

![](/images/2021-02-13-microservice3.svg)
<div class="text-center"><small>마이크로 서비스 시퀀스</small></div>

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

OAuth2에 대한 지식이 부족하기도 하거니와, 방대한 주제라 블로그 포스트에서 설명하기는 어렵습니다. [thephpleague의 문서](https://oauth2.thephpleague.com/authorization-server/which-grant/)를 차분히 읽어보실 것을 권장합니다. 이 예제에서는 Password와 ClientCredentials 그랜트만 사용합니다. 

**`Password` 그랜트는 1st Party 클라이언트**, 즉 내부에서 만든 클라이언트 애플리케이션을 위한 인증 방법입니다. Facebook을 예로 들어볼까요? Facebook 입장에서 공식 앱은 1st Party 클라이언트입니다. 페북 공식 앱을 사용하기 위해선 페북 사용자 아이디와 비밀번호를 제출해야하죠? 계정 정보가 정확하면 페북 인증 서버는 공식 앱에 `access_token`을 발급하고, 공식 앱은 발급 받은 토큰을 제출하면서 내 타임라인 데이터를 조회하고, 조회한 데이터를 뷰에 바인딩해서 렌더링할겁니다.

**`ClientCredentials` 그랜트는 주로 1st Party 서버**를 위한 인증 방법입니다. 예를들어 페북 친구 서비스는 중요한 리소스라 아무나 조회하거나 변경해서는 안됩니다. 친구 추천 서버가 친구 서버와 통신할 때, 페북 인증 서버에서 받은 `access_token`으로 자격증명을 제출할 겁니다.

어떤 그랜트를 쓰든 보호된 리소스를 요청할 때 `Authorization` 요청 헤더에 `access_token`을 제출해야 합니다, 이렇게 말이죠.

```http
GET /api/resources
Authorization: bearer access_token
```

## 3 JWT 이해하기

OAuth2 인증 서버가 `access_token`으로 꼭 JWT를 제공할 필요는 없습니다. 만약 `Password` 또는 `ClientCredentials` 그랜트 인증 요청에 대해 난수 토큰을 제공했다 가정해보죠. 클라언트는 마이크로 서비스의 보호된 리소스를 사용하기위해 난수 토큰을 제출할테고, 요청을 받은 마이크로 서비스를 받은 난수 토큰의 유효성을 검증해야 하는데... 아마도 마이크로 서비스가 받은 난수 토큰이 유효한지 OAuth2 인증 서버에 물어봐야겠죠~ 뿐더러 `createdBy`, `updatedBy` 등의 필드 값을 채우려면 난수 토큰에 해당하는 사용자 정보도 조회하고 메모리에 보관하고 있어야 할 겁니다.

JWT는 토큰 본문 안에 여러 가지 정보를 담은 `access_token`을 만들 수 있기 때문에 앞서 언급한 문제점들을 해결할 수 있습니다.

[https://jwt.io](https://jwt.io)에서 1절에서 받은 `access_token`을 파싱해보겠습니다. 아래 그림의 왼쪽 입력 박스에 토큰을 붙여 넣으면, 오른쪽에 파싱된 정보가 나옵니다. 

![](/images/2021-02-13-jwt.png)
<div class="text-center"><small>JWT 파싱</small></div>

### HEADER
- `alg`: 알고리즘
- `typ`: 토큰 타입 (jwt OR jwk)

### PAYLOAD
- `iat`: 발급일
- `exp`: 만료일
- `jti`: JWT ID
- `user_name`, `scope`, `authorities`, `client_id`: 커스텀 클레임

### SIGNATURE
- 1절 "④ 토큰 유효성 검사"에서 조회한 공개 키를 입력 박스에 넣는다; 공개 키를 넣지 않아도 파싱은 된다
- **공개 키를 넣어서 토큰 유효성이 검증되면 네트워크 구간에서 토큰이 변조되지 않았음을 확신할 수 있다**

### JWT 라이브러리 설치
```bash
$ composer require firebase/php-jwt
```

전체 예제코드는 [https://github.com/appkr/laravel-msa-example](https://github.com/appkr/laravel-msa-example)에서 볼 수 있습니다.

<p class="lead">2부에서 계속...</p> 
<!--
## 4 구현
## 5 검증
## 6 요약

{:.linenos}
```php
```
-->
