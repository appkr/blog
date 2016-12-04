---
layout: post
title:  블로그 플랫폼 이전 4 - Build Automation with Gulp
slug: jekyll-blogging-part4
date: 2016-02-12 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- Jekyll
---
Wordpress 에서 Jekyll 로 마이그레이션 과정에서 배운 내용을 총 5 편의 포스트로 정리해 본다.

1. [개발자로서의 새로운 삶](/work-n-play/블로그-플랫폼-이전-1-개발자로서의-새로운-삶)
2. [Goodbye Wordpress, Hello Jekyll](/work-n-play/블로그-플랫폼-이전-2-goodbye-wordpress-hello-jekyll)
3. [Publishing](/work-n-play/블로그-플랫폼-이전-3-publishing)
4. _Build Automation with Gulp_
5. [Disqus & Facebook](/work-n-play/블로그-플랫폼-이전-5-disqus-facebook)

지난 2 주일 동안 일어난 우여곡절들을 기억을 되살려 최대한 복기해 두었다.

<div class="spacer">• • •</div>

## Jekyll Serve

Jekyll 은 로컬 테스트 서버를 포함하고 있다. 콘솔 메시지를 자세히 보면, 빌드 대상이 되는 파일들을 컴파일하여 `public` 디렉토리에 출판하고, `public` 디렉토리를 Document Root 로 하는 `http://localhost:4000` 로컬 웹 서버를 띄운다는 것을 알 수 있다. 서버를 뛰우지 않고 빌드만 하려면, `$ jekyll build`. 오오~ 멋지다~   

```bash
$ jekyll serve
# Configuration file: /.../blog/_config.yml
#             Source: /.../blog
#        Destination: public
#  Incremental build: disabled. Enable with --incremental
#       Generating...
#                     done in 1.432 seconds.
#  Auto-regeneration: enabled for '/.../blog'
# Configuration file: /.../blog/_config.yml
#     Server address: http://127.0.0.1:4000/
#   Server running... press ctrl-c to stop.
```

[![Preview with Jekyll built-in web server](/images/2016-02-12-img-01.png)](/images/2016-02-12-img-01.png)

그런데 2% 가 부족했다.

<!--more-->

## Resort to Gulp

프로젝트 시작부터 [Gulp](http://gulpjs.com/) 를 사용한 것은 아니었다. Jekyll 이 Sass/SCSS/Coffee 컴파일을 지원한다는 사실이 좋았다. 그런데, JS 는 어떻하지? 이미지 최적화나 파일/디렉토리 복사, 배포는 또 어떻게 해야 하지? 구글링을 했지만, 마음에 드는 레시피를 찾지는 못한 상태였는데... "Gulp 를 못 쓸 이유는 없을 것 같은데?" 라고 자문하고, 바로 작업에 들어갔다.

Gulp 스크립트 구동에 필요한 의존성 패키지들은 `package.json` 에 정의되어 있는데... 좀 많긴하다.

```bash
$ echo "{}" > package.json
$ npm install --save-dev babel-core babel-preset-es2015 browser-sync del gulp gulp-autoprefixer gulp-babel gulp-clean gulp-concat gulp-if gulp-imagemin gulp-load-plugins gulp-minify-css gulp-newer gulp-sass gulp-size gulp-sourcemaps gulp-subtree gulp-uglify run-sequence
```

```javascript
// https://github.com/appkr/blog/blob/master/package.json

{
  "devDependencies": {
    "babel-core": "^6.0.15",
    "babel-preset-es2015": "^6.0.15",
    "browser-sync": "^2.9.0",
    "del": "^2.0.2",
    "gulp": "^3.9.0",
    "gulp-autoprefixer": "^3.1.0",
    "gulp-babel": "^6.0.0",
    "gulp-clean": "^0.3.1",
    "gulp-concat": "^2.5.2",
    "gulp-if": "^2.0.0",
    "gulp-imagemin": "^2.0.0",
    "gulp-load-plugins": "^1.0.0",
    "gulp-minify-css": "^1.1.6",
    "gulp-newer": "^1.0.0",
    "gulp-sass": "^2.0.0",
    "gulp-size": "^2.0.0",
    "gulp-sourcemaps": "^1.3.0",
    "gulp-subtree": "^0.1.0",
    "gulp-uglify": "^1.0.1",
    "run-sequence": "^1.0.1"
  }
}
```

## Gulpfile.babel.js

아래는 전체 스크립트이다. 특징은 [BrowserSync](https://browsersync.io/) 이용한다는 점과, [ES2015](https://babeljs.io/docs/learn-es2015/) 사용한다는 점 등을 들 수 있다.

```javascript
// https://github.com/appkr/blog/blob/master/gulpfile.babel.js
// Referenced from Google Web Starter Kit
// @see https://github.com/google/web-starter-kit

'use strict';

import cp from 'child_process';
import gulp from 'gulp';
import del from 'del';
import runSequence from 'run-sequence';
import browserSync from 'browser-sync';
import gulpLoadPlugins from 'gulp-load-plugins';
import pkg from './package.json';

const $ = gulpLoadPlugins();
const reload = browserSync.reload;

/**
 * Task 'clean' : Clean output directory
 */
gulp.task('clean', cb => del(['.tmp', 'images', 'scripts', 'styles', 'public'], {dot: true}));

/**
 * Task 'jekyll' : Build jekyll sites
 */
gulp.task('jekyll', (done) => {
  return cp.spawn('jekyll', ['build'], {stdio: 'inherit'}).on('close', done);
});

/**
 * Task 'images' : Optimize images
 */
gulp.task('images', () =>
  gulp.src('_assets/images/**/*.*')
  .pipe($.imagemin({progressive: true, interlaced: true}))
  .pipe(gulp.dest('images'))
  .pipe($.size({title: 'images'}))
);

/**
 * Task 'styles' : Compile and automatically prefix stylesheets
 */
gulp.task('styles', () => {
  const AUTOPREFIXER_BROWSERS = [
    'ie >= 10',
    'ie_mob >= 10',
    'ff >= 30',
    'chrome >= 34',
    'safari >= 7',
    'opera >= 23',
    'ios >= 7',
    'android >= 4.4',
    'bb >= 10'
  ];

  return gulp.src([
    '_assets/styles/main.scss'
  ])
  .pipe($.newer('.tmp/styles'))
  .pipe($.sourcemaps.init())
  .pipe($.sass({precision: 10}).on('error', $.sass.logError))
  .pipe($.autoprefixer(AUTOPREFIXER_BROWSERS))
  .pipe(gulp.dest('.tmp/styles'))
  .pipe($.concat('main.min.css'))
  .pipe($.if('*.css', $.minifyCss()))
  .pipe($.size({title: 'styles'}))
  .pipe($.sourcemaps.write('./'))
  .pipe(gulp.dest('styles'));
});

/**
 * Task 'scripts' : Concatenate and minify JavaScript.
 */
gulp.task('scripts', () =>
  gulp.src([
    '_assets/vendor/fastclick/lib/fastclick.js',
    '_assets/vendor/jquery/dist/jquery.js',
    '_assets/vendor/simple-jekyll-search/dest/jekyll-search.js',
    '_assets/vendor/bootstrap-sass/assets/javascripts/bootstrap.js',
    '_assets/vendor/bootstrap-material-design/scripts/material.js',
    '_assets/vendor/bootstrap-material-design/scripts/ripples.js',
    '_assets/scripts/main.js'
  ])
  .pipe($.sourcemaps.init())
  .pipe($.babel())
  .pipe($.sourcemaps.write())
  .pipe(gulp.dest('.tmp/scripts'))
  .pipe($.concat('main.min.js'))
  .pipe($.uglify({preserveComments: 'some'}))
  .pipe($.size({title: 'scripts'}))
  .pipe($.sourcemaps.write('.'))
  .pipe(gulp.dest('scripts'))
);

/**
 * Task 'serve' : Watch files for changes & reload
 */
gulp.task('serve', ['images', 'styles', 'scripts', 'jekyll'], () => {
  browserSync({
    notify: false,
    logPrefix: 'Jekyll',
    server: ['public'],
    port: 3000
  });

  gulp.watch(['_assets/styles/**/*.{scss,css}'], ['styles', 'jekyll', reload]);
  gulp.watch(['_assets/scripts/**/*.js'], ['scripts', 'jekyll', reload]);
  gulp.watch(['_assets/images/**/*'], ['images', 'jekyll', reload]);
  gulp.watch(['**/*.{html,md,markdown}', '!public/**/*.*'], ['jekyll', reload]);
});

/**
 * Task 'default' : Build production files, the default task
 */
gulp.task('default', [], cb => runSequence('styles', 'scripts', 'images', 'jekyll', cb));

/**
 * Task 'deploy' : This will run the build task, then push it to the gh-pages branch
 */
gulp.task('deploy', [], () => {
  cp.spawn('sed', ['-i', "''", 's/public/#public/', '.gitignore'], { stdio: 'inherit' });
  gulp.src('public').pipe($.subtree());
  return cp.spawn('git', ['checkout', '.gitignore'], { stdio: 'inherit' });
});
```

## How to Run

```bash
$ gulp {taskName}
```

## Tasks

### clean

빌드 과정에서 생성된 임시 디렉토리 (`.tmp`) 와 빌드 결과를 담는 디렉토리 (`public`) 등을 삭제하고 초기화하는 작업을 수행한다.

```bash
$ gulp clean
```

### jekyll

`$ jekyll build` 를 수행한다.

```bash
$ gulp jekyll
```

### images

`_assets/images` 디렉토리에 담긴 이미지를 최적화하여 `images` 디렉토리로 출판한다.

```bash
$ gulp images
```

### styles

`_assets/styles` 에 있는 모든 Stylesheets (css, scss, sass) 에 대해 

- Sass/SCSS Compile
- Vendor Prefix
- 모든 파일을 main.min.css 로 합침
- Minification
- Source Map 작성

한 후, `styles` 디렉토리로 출판한다.

```bash
$ gulp styles
```

### scripts

`gulp.src()` 에서 인자로 받은 Javascripts 에 대해

- Babelify (Ecma Script 에서 Legacy JS 로 변환)
- 모든 파일을 main.min.js 로 합침
- Uglify (난독화, 파일 사이즈 축소 목적)
- Source Map 작성

한 후, `scripts` 디렉토리에 출판한다.

```bash
$ gulp scripts
```

### serve

`images`, `styles`, `scripts`, `jekyll` Task 를 순차적으로 수행한 후, `http://localhost:3000` 웹 서버를 띄우고 BrowserSync 를 구동시킨다. BrowserSync 구동 이후, `_assets` 디렉토리 하위의 Stylesheets, Javascripts, Image 및 `.html`, `.md` 파일의 변경을 감시한다. 파일 변경이 있으면, 현재 `http://localhost:3000` 이 열려있는 모든 브라우저를 리프레시 한다.

```bash
$ gulp serve
```

[![gulp serve](/images/2016-02-12-img-02.png)](/images/2016-02-12-img-02.png)

#### 덧

BrowerSync 를 이용하면, 동일한 서브넷에 접속되어 있는 모바일 기기를 포함한 다른 Machine 에서도 페이지에 접속할 수 있다. iOS 디바이스에서는 Safari 브라우저를 이용하면 [리모트 디버깅](https://developers.google.com/web/tools/chrome-devtools/debug/remote-debugging/remote-debugging#remote-debugging-on-ios-with-safari-web-inspector) 도 가능하다. Android 디바이스는 당연히 Chrome Browser 를 이용해 리모트 디버깅할 수 있다. 

[![BrowserSync across Multiple Devices](/images/2016-02-12-img-03.png)](/images/2016-02-12-img-03.png)

BrowserSync 의 고유기능인데, 현재 열려있는 모든 브라우저에서의 키보드 입력, 스크롤등은 동기화된다. 가령 iOS 디바이스에서 페이지를 스크롤하면 데스크탑 브라우저에 열려 있는 페이지도 같이 스크롤된다. 코드 변경사항 또한 모든 브라우저에 반영된다. 

### default

`images`, `styles`, `scripts`, `jekyll` 빌드 작업만 수행하고, 웹 서버 구동, BrowserSync 구동, 파일 감시는 하지 않는다.

```bash
$ gulp
```

### deploy

현재 프로젝트를 `gh-pages` 브랜치로 checkout 한 후, [Github Page](https://pages.github.com/) 에 배포한다.

```bash
$ gulp deploy
```

<div class="spacer">• • •</div>

[Github Page](https://pages.github.com/) 를 이용한 호스팅은 무료이다. Github Page 에서는 백엔드 플랫폼을 쓸 수 없기에, 정적 페이지를 미리 컴파일할 수 있는 Jekyll 과 궁합이 아주 잘 맞다. 많은 개발자들이 Github Page + Jekyll 조합으로 웹 서비스를 하고 있다.
