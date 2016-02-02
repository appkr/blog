'use strict';

import fs from 'fs';
import path from 'path';
import gulp from 'gulp';
import del from 'del';
import runSequence from 'run-sequence';
import browserSync from 'browser-sync';
import swPrecache from 'sw-precache';
import gulpLoadPlugins from 'gulp-load-plugins';
import pkg from './package.json';

// Added for gh-pages deploy
var subtree = require('gulp-subtree');

const $ = gulpLoadPlugins();
const reload = browserSync.reload;

/**
 * Task 'images' : Optimize images
 */
gulp.task('images', () => gulp.src('_assets/images/**/*.*')
  .pipe($.cache(
    $.imagemin({
      progressive: true,
      interlaced: true
    })
  ))
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
    .pipe($.sass({
      precision: 10
    }).on('error', $.sass.logError))
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
 * Task 'clean' : Clean output directory
 */
gulp.task('clean', cb => del(['.tmp', 'public'], {dot: true}));

/**
 * Task 'serve' : Watch files for changes & reload
 */
gulp.task('serve', ['styles', 'scripts'], () => {
  browserSync({
    notify: false,
    logPrefix: 'Jekyll',
    server: ['.tmp', 'public'],
    port: 3000
  });

  gulp.watch(['**/*.{html,md,markdown}'], reload);
  gulp.watch(['_assets/styles/**/*.{scss,css}'], ['styles', reload]);
  gulp.watch(['_assets/scripts/**/*.js'], ['scripts']);
  gulp.watch(['_assets/images/**/*'], reload);
});

/**
 * Task 'default' : Build production files, the default task
 */
gulp.task('default', [], cb => runSequence(
    'styles',
    'scripts',
    'images',
    cb
  )
);

/**
 * Task 'deploy' : This will run the build task, then push it to the gh-pages branch
 */
gulp.task('deploy', [], () => {
  return gulp.src('public')
    .pipe($.subtree());
});
