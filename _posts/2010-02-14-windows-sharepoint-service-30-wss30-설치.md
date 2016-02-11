---
layout: post
title: Windows Sharepoint Service 3.0 (WSS3.0) 설치
date: '2010-02-14 13:41:29 +0900'
categories:
- work-n-play
tags:
- se
- wss
---

WSS3.0 설치 작업 결과를 정리해 본다. Server 만 준비되면, WSS3.0 과 Search Server Express 는 Microsoft 에서 무료로 다운로드 받을 수 있다. 기업에서의 사용에도 아무런 제약사항이 없다. 개인지성들을 모아 집단지성으로 발전시키기에 정말 좋은 무료 협업 도구이다.

host name 은 `sbd` 라 하자.

### Install-.net Framework

```bash
\> dotnetfx35sp1.exe
```

### Install-SQL Utilities

```bash
\> sqlcli.msi
\> SQLServer2005_SQLCMD.msi
\> SQLServer2005_SSMSEE.msi
```

### Install-WSS3.0

```bash
\> sharepoint.exe
```

약관동의 -> 고급설치 -> 서버유형:독립실행형 -> 데이터위치: `d:\wss_data` -> "지금 Sharepoint 제품 및 기술 구성 마법사 실행"

<!--more-->

### Configure-SMTP 서버

```
SMTP Server: xxx.xxx.xxx.xxx
```

### Configure-WSS Log

WSS 중앙관리 -> 작업 -> 진단 로깅 활성화

### Configure-Database 를 `C:\` 에서 `D:\` 로 이동

IIS/WSS Service 종료 후, Content Database 이름 확인

중앙관리 -> 응용 프로그램 관리 -> 콘텐츠 데이터베이스: "WSS_Content"

```bash
\> cd C:\Program Files\Microsoft SQL Server\90\Tools\binn
\> sqlcmd -S \.pipemssql$microsoft##sseesqlquery -E
```

```sql
sql> EXEC sp_detach_db @dbname = 'WSS_Content'
sql> Go
```

```bash
\> copy %WINDIR%SYSMSISSEEMSSQL.2005\MSSQLData\WSS_Content.mdf d:\wss_db\
\> copy %WINDIR%SYSMSISSEEMSSQL.2005\MSSQLData\WSS_Content_log.ldf d:\wss_db\
```

```sql
sql> EXEC sp_attach_db @dbname = WSS_Content', @filename1 = 'd:\wss_db\WSS_Content.mdf', @filename2 = 'd:\wss_db\WSS_Content_log.ldf'
sql> Go
```

나머지 데이터베이스 이름도 확인

```sql
sql> select name from sysdatabases
sql> Go
# SharePoint_Config_2e0e9493-bccb-4b66-9e61-ea4c2974a310
# SharePoint_AdminContent_b597bf8d-8ed5-4de7-86dc-774a919cab5c
# WSS_Search_SBD
# WSS_Contents
sql> EXEC sp_detach_db @dbname = 'SharePoint_Config_2e0e9493-bccb-4b66-9e61-ea4c2974a310'
sql> Go
sql> EXEC sp_detach_db @dbname = 'SharePoint_AdminContent_b597bf8d-8ed5-4de7-86dc-774a919cab5c'
sql> Go
sql> EXEC sp_detach_db @dbname = 'WSS_Search_SBD'
sql> Go
```

파일 복사

```bash
\> copy %WINDIR%SYSMSISSEEMSSQL.2005\MSSQLData\*.* d:\wss_db
```

```
sql> EXEC sp_attach_db @dbname = 'SharePoint_Config_2e0e9493-bccb-4b66-9e61-ea4c2974a310', @filename1 = 'd:wss_db\SharePoint_Config_2e0e9493-bccb-4b66-9e61-ea4c2974a310.mdf',
@filename2 = 'd:wss_db\SharePoint_Config_2e0e9493-bccb-4b66-9e61-ea4c2974a310_log.ldf'
sql> Go
sql> EXEC sp_attach_db @dbname = 'SharePoint_AdminContent_b597bf8d-8ed5-4de7-86dc-774a919cab5c',
@filename1 = 'd:wss_db\SharePoint_AdminContent_b597bf8d-8ed5-4de7-86dc-774a919cab5c.mdf',
@filename2 = 'd:wss_db\SharePoint_AdminContent_b597bf8d-8ed5-4de7-86dc-774a919cab5c_log.ldf'
sql> Go
sql> EXEC sp_attach_db @dbname = 'WSS_Search_SBD', @filename1 = 'd:wss_db\WSS_Search_SBD.mdf', @filename2 = 'd:wss_db\WSS_Search_SBD_log.ldf'
sql> Go
```

IIS/WSS 서비스 재 구동 후, SQL Management Studio에서 Database 파일들이 정상적으로 이동되었는 지 확인.

### Install-Search Server 2008 Express

```bash
\> SearchServerExpress.exe
```

서버유형: 독립실행형 -> Index파일 위치: `d:\sse_index`

"Sharepoing 제품 및 기술 구성 마법사" -> "Shared Service Provider (SSP): `http://sbd/ssp/admin`" -> "SSP Database" -> 데이터베이스 서버: SBDOfficeServers -> 데이터베이스 이름: SharedServices1_DB -> "검색 Database" -> 데이터베이스 이름: `SharedServices1_Search_DB` -> "인덱스 서버" -> 인덱스 파일 경로 위치: `d:\sse_index\Office Server\Applications`

### Configure-Search Server 사이트 만들기

### Configure-중앙관리

작업 -> 진단 로깅 설정 -> 추적 로그 경로: `d:\wss_log` -> 응용 프로그램 관리 -> 웹 응용 프로그램 일반 설정 -> 기본 표준 시간대 : GMT+9 서울 -> 최대 업로드 크기 : `999MB` -> 응용 프로그램 관리 -> 웹 응용 프로그램 정책 -> NT AUTHORITY\LOCAL SERVICE: `전체 읽기`

### Install-Application Template Core

```bash
\> cd C:Program Files\Common Files\microsoft shared\Web Server Extensions12\BIN
\> Stsadm -o addsolution -filename ApplicationTemplateCore.wsp
\> Stsadm -o deploysolution -name ApplicationTemplateCore.wsp -allowgacdeployment -immediate
\> Stsadm -o copyappbincontent
\> Stsadm -o execadmsvcjobs
```

### Pdf icon 표시하기

Pdf icon 구하기 -> C:\Program Files\Common Files\Microsoft Shared\web server extensions12\TEMPLATE\IMAGES 에 pdf icon 복사 -> C:\Program Files\Common Files\Microsoft Shared\web server extensions\12\TEMPLATE\XMLDOCICON.XML 에 레코드 추가

```xml
<!-- XMLDOCICON.XML -->
<Mapping Key="pdf" Value="PDFICON.gif"/>
```

```bash
\> iisreset
```

### Configure-작업 예약

중앙관리 -> 작업 -> 사용현황분석프로세스 -> 로그파일 위치 : `d:\wss_user_log` -> 분석 시간 : `오전 03:00~04:00`

제어판 -> 작업예약 -> C:\Program Files\Common Files\Microsoft Shared\web server extensions\12\BIN\wss_backup.bat -> 매일 오전 05:00

```bash
# wss_backup.bat
stsadm.exe -o backup -directory d:wss_backup -backupmethod differential
```

제어판 -> 작업예약 -> C:\Program Files\Common Files\Microsoft Shared\web server extensions\12\BIN\wss_backup_network.bat -> 매주 일요일 오전 07:00

```bash
# wss_backup_network.bat
NET USE z: \xxx.xxx.xxx.xxx\SBDBackup USERPASS /USER:USERNAME@DOMAIN
xcopy d:\wss_backup z: /S /Y
NET USE z: /DELETE
```

### Configure-계산된 열에 html 허용

[http://blog.ray1.net/2008/01/enabling-html-andor-images-in.html](http://blog.ray1.net/2008/01/enabling-html-andor-images-in.html)

```bash
\> notepad C:\Program Files\Common Files\Microsoft Shared\web server extensions\12\TEMPLATE\XMLFLDTYPES.XML
```

```xml
<!-- XMLFLDTYPES.XML -->
<RenderPattern Name="DisplatPattern">
<Default> <Column HTMLEncode="TRUE"/>
<Column/>
```

```bash
\> iisreset
```

### Install-iFilter6.0

```bash
\> ifilter.exe
```

IISAdmin -> Server 중지

```bash
\> cd c:\Program files\adobe\pdf ifilter 6.0
\> regsvr32.exe pdffilt.dll
```

Server Reboot 후, Search Server 전체 크롤링
