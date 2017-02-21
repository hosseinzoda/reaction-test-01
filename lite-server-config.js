"use strict";
const browserSync = require('browser-sync').get('lite-server');
const less = require('less')
const fs = require('fs')
const child_process = require('child_process')

let watch_change_2_cmd = [
  {
    watch: 'public/assets/less/**/*.less',
    cmd: 'npm -s run gulp -- lessc-style'
  },
  {
    watch: 'public/assets/coffee/**/*.coffee',
    cmd: 'npm -s run gulp -- coffee-path-stdin',
    pathtostdin: true
  }
];

for(let item of watch_change_2_cmd)
  browserSync.watch(item.watch, mkWatchChange2Cmd(item));

function mkWatchChange2Cmd(data) {
  return (evt, file) => {
    if(evt == 'change') {
      var cproc = child_process.exec(data.cmd, (err, stdout, stderr) => {
        if (err) {
          console.error(err);
          return;
        }
        // nothing to do
        // console.log(stdout);
      });
      if(cproc && data.pathtostdin) {
        cproc.stdin.end(file);
      }
    }
  }
}

let lsconfig = module.exports = {
  files: ['public/assets/js/**/*.js',
          'public/assets/css/**/*.css',
          'public/assets/img/**/*',
          'public/assets/template/**/*.html',
          'public/index.html'],
  injectChanges: true,
  server: {
    baseDir: './public'
  },
  browser: ["google-chrome"]
};
