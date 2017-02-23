'use strict';

const gulp = require('gulp');
const less = require('gulp-less');
const coffee = require('gulp-coffee');
const clean = require('gulp-clean');
const filter = require('gulp-filter');
const merge = require('merge-stream');
const concat_stream = require('concat-stream')
const sourcemaps = require('gulp-sourcemaps')
const sequence = require('run-sequence');
// const rename = require('gulp-rename');

//CONFIG PATHS
const assets_dir = 'public/assets',
    build_dir = './dist',
    coffee_defs = [
      {
        'src': assets_dir+'/coffee/**/*.coffee',
        'options': {},
        'dest': assets_dir+'/js/'
      }
    ];

//TASKS
gulp.task('lessc-style', function () {
  return gulp.src(assets_dir+'/less/style.less') 
    .pipe(less({
      paths: [assets_dir+'/less/']
    }))
    .pipe(gulp.dest(assets_dir+'/css/'));
});

gulp.task('coffee-path-stdin', function() {
  process.stdin.pipe(concat_stream(function(data) {
    var path = data.toString('utf-8')
    console.log('path', path)
    // coffee all code
    for(let acoffee of coffee_defs)
      gulp.src(acoffee.src)
      .pipe(filter([path]))
      .pipe(sourcemaps.init())
      .pipe(coffee(acoffee.options))
      .pipe(sourcemaps.write('./maps'))
      .pipe(gulp.dest(acoffee.dest));
  }));
});

gulp.task('coffee-all', function () {
  var all = [];
  for(let acoffee of coffee_defs)
    all.push(gulp.src(acoffee.src)
             .pipe(sourcemaps.init())
             .pipe(coffee(acoffee.options))
             .pipe(sourcemaps.write('./maps'))
             .pipe(gulp.dest(acoffee.dest)));
  return merge(all)
});

gulp.task('build',[],function(done) {
  sequence('lessc-style', 'coffee-all', 'copy', done)
});

gulp.task('clean', function(){
	return gulp.src( build_dir , {read: false})
		.pipe(clean());
});

gulp.task('copy', ['clean'],function () {
	return gulp.src(['public/**/*'])
    .pipe(filter(['**',
                  '!'+assets_dir+'/less/**', '!'+assets_dir+'/coffee/**',
                  '!'+assets_dir+'/less', '!'+assets_dir+'/coffee']))
	  .pipe(gulp.dest(build_dir));
});

gulp.task('default', function() {
 console.log( "\nCommand List \n" );
 console.log( "----------------------------\n" );
 console.log( "gulp build" );
 console.log( "gulp clean" );
 console.log( "gulp lessc-style" );
 console.log( "gulp coffee-all \n" );
 console.log( "----------------------------\n" );
});
