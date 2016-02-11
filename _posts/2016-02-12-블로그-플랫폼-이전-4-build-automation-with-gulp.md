---
layout: post
title:  블로그 플랫폼 이전 4 - Build Automation with Gulp
date: 2016-02-12 00:00:00 +0900
categories:
- work-n-play
tags:
- 개발자
- jekyll
---
Wordpress 에서 Jekyll 로 마이그레이션 과정에서 배운 내용을 총 4 편의 포스트로 정리해 본다.

1. [개발자로서의 새로운 삶](/work-n-play/블로그-플랫폼-이전-1-개발자로서의-새로운-삶)
2. [Goodbye Wordpress, Hello Jekyll](/work-n-play/블로그-플랫폼-이전-2-goodbye-wordpress-hello-jekyll)
3. [Publishing](/work-n-play/블로그-플랫폼-이전-3-publishing)
4. _Build Automation with Gulp_

<div class="spacer">• • •</div>

Jekyll 은 로컬 테스트 서버를 포함하고 있다.

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

그런데 문제가 있었다.

<!--more-->

### Resort to Gulp

처음부터 Gulp 를 사용한 것은 아니다. Jekyll 이 Sass/SCSS/Coffee 컴파일을 지원한다는 사실이 좋았다. 그런데, JS 는 어떻하지? 이미지 최적화나 파일/디렉토리 복사, 배포는 또 어떻게 해야 하지? 구글링을 했지만, 마음에 드는 레시피를 찾지는 못한 상태였는데... '정적 페이지이니 Gulp 를 못 쓸 이요는 없을 것 같은데?" 라고 자문하고, 바로 작업에 들어갔다.

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

### 작성 중 ...

