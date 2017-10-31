"use strict";
const browserSync = require('browser-sync').get('lite-server');
const less = require('less')
const fs = require('fs')
const child_process = require('child_process')

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
