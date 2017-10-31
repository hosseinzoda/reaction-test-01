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
const path = require('path')
// const rename = require('gulp-rename');
const gutil = require('gulp-util')

//CONFIG PATHS
const assets_dir = 'public/assets',
      build_dir = './dist';
let iswatch = false;

//TASKS
gulp.task('lessc-style', function () {
  var stream = less({
    paths: [assets_dir+'/less/']
  });
  if(iswatch)
    stream.on('error', function(err) {
      gutil.log(err.toString());
      gutil.beep()
      this.end()
    })
  return gulp.src(assets_dir+'/less/style.less') 
    .pipe(stream)
    .pipe(gulp.dest(assets_dir+'/css/'));
});

function coffee_make(src, dest) {
  var stream = coffee({});
  if(iswatch)
    stream.on('error', function(err) {
      gutil.log(err.toString());
      gutil.beep()
      this.end()
    })
  return gulp.src(src)
    .pipe(sourcemaps.init())
    .pipe(stream)
    .pipe(sourcemaps.write('./maps'))
    .pipe(gulp.dest(dest));
}

gulp.task('coffee-all', () => {
  return coffee_make(assets_dir+'/coffee/**/*.coffee', assets_dir+'/js/')
});

gulp.task('watch', function() {
  iswatch = true
  gulp.watch(assets_dir+'/coffee/**/*.coffee')
    .on('change', (event) => {
      var dir = path.resolve(process.cwd(), assets_dir ),
          relpath = path.relative(dir + '/coffee/', event.path);
      console.log("coffee compile", relpath)
      coffee_make(event.path,
                  path.join(dir + '/js/', path.dirname(relpath)) + "/")
    });
  gulp.watch(assets_dir+'/less/**/*.less', ['lessc-style']);
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
