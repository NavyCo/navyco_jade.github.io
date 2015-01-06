'use strict'

var path = require('path');

var $ = require('gulp-load-plugins')();
var autoprefixer = require('autoprefixer-core');
var bowerFiles = require('bower-files');
var browserSync = require('browser-sync');
var deepExtend = require('deep-extend-stream');
var File = require('vinyl');
var frontmatter = require('gray-matter');
var glob = require('glob');
var gulp = require('gulp');
var imageSize = require('image-size');
var mergeStream = require('merge-stream');
var jade = require('jade');
var jpegRecompress = require('imagemin-jpeg-recompress');
var objectAssign = require('object-assign');
var pngquant = require('imagemin-pngquant');
var readYaml = require('read-yaml-promise');
var reload = browserSync.reload;
var saveLicense = require('uglify-save-license');
var vinylYamlData = require('vinyl-yaml-data');
var webp = require('imagemin-webp');

var SRC = '';
var DEST = 'master';
var DEST_DEBUG = path.join(DEST, 'debug');

var locals;
var bowerPaths = bowerFiles();
var imageminPlugins = [jpegRecompress(), pngquant()];

gulp.task('lint', function() {
  return gulp.src('*.js', {cwd: SRC})
    .pipe($.jscs('package.json'));
});

gulp.task('copy:public', function() {
  return gulp.src('public/**/*', {cwd: SRC})
    .pipe($.size({title: 'copy'}))
    .pipe(gulp.dest(DEST));
});

gulp.task('copy:js', function() {
  var jquery = gulp.src(['jquery{,1}/dist/jquery.min.js'], {cwd: 'bower_components'})
    .pipe($.rename(function(filePath) {
      filePath.basename = filePath.dirname.replace('/dist', '');
      filePath.dirname = '';
    }))
    .pipe(gulp.dest('js', {cwd: DEST}));

  var ltIe9 = gulp.src(['lt-ie-9/lt-ie-9.min.js'], {cwd: 'bower_components'})
    .pipe($.rename('ltie9.js'))

  return mergeStream(jquery, ltIe9)
    .pipe(gulp.dest('js', {cwd: DEST}));
});

gulp.task('copy', ['copy:public', 'copy:js']);

gulp.task('styles:deps', function() {
  return gulp.src(bowerPaths.css, {cwd: SRC})
    .pipe($.concat('deps.css'))
    .pipe(gulp.dest('css', {cwd: DEST_DEBUG}));
});

gulp.task('styles:main', function() {
  return gulp.src('scss/styles.scss', {cwd: SRC})
    .pipe($.rubySass({
      sourcemapPath: 'scss',
      compass: true
    }))
    .pipe($.if('*.css', $.postcss([
      autoprefixer()
    ])))
    .pipe(gulp.dest('css', {cwd: DEST_DEBUG}));
});

gulp.task('styles', ['styles:deps', 'styles:main'], function() {
  return gulp.src('css/*.css', {cwd: DEST_DEBUG})
    .pipe($.concat('min.css'))
    .pipe($.minifyCss())
    .pipe(gulp.dest('css', {cwd: DEST}));
});

gulp.task('scripts:deps', function(cb) {
  return gulp.src(['js/vendor/*.js'].concat(bowerPaths.js), {cwd: SRC})
    .pipe($.ignore.exclude(/.*(dist\/jquery|lt-ie-9).*/))
    .pipe($.concat('deps.js'))
    .pipe(gulp.dest('js', {cwd: DEST_DEBUG}));
});

gulp.task('scripts:router', function(cb) {
  readYaml(path.resolve(SRC, 'jade/data/projects.yaml')).then(function(projects) {
    var routerData = projects.reduce(function(result, project) {
      result[project.name] = {
        proj_title: project.title,
        time: project.time,
        role: project.role
      };
      return result;
    }, {
      index: {},
      about: {title: '渡邉伸之介について'},
      projects: {title: 'プロジェクト一覧'}
    });

    gulp.dest('js', {cwd: DEST_DEBUG})
      .on('finish', cb)
      .on('error', cb)
      .end(new File({
        path: 'router-data.js',
        contents: new Buffer(
          'window.routerData = ' +
          JSON.stringify(routerData, null, '  ') +
          ';\n'
        )
      }));
  }, cb).catch(cb);
});

gulp.task('scripts:main', function(cb) {
  return gulp.src('js/main/*.coffee', {cwd: SRC})
    .pipe($.coffeelint())
    .pipe($.concat('main.js'))
    .pipe($.coffee())
    .pipe($.header('/*! MIT (c) Shinnosuke Watanabe */\n'))
    .pipe(gulp.dest('js', {cwd: DEST_DEBUG}));
});

gulp.task('scripts', ['scripts:deps', 'scripts:router', 'scripts:main'], function() {
  return gulp.src('js/*.js', {cwd: DEST_DEBUG})
    .pipe($.uglify({
      compress: {
        global_defs: {DEBUG: false},
      },
      preserveComments: saveLicense
    }))
    .pipe($.concat('min.js'))
    .pipe(gulp.dest('js', {cwd: DEST}));
});

gulp.task('clear', $.cache.clearAll.bind($.cache));

gulp.task('images', function() {
  return gulp.src('img/**/*.{png,jpg,gif,svg}', {cwd: SRC})
    .pipe($.size({title: 'images:source'}))
    .pipe($.cache($.imagemin({
      progressive: true,
      optimizationLevel: 7,
      svgoPlugins: [{removeViewBox: false}],
      use: imageminPlugins
    })))
    .pipe($.if('**/*.svg', $.flexSvg()))
    .pipe($.size({title: 'images:optimized'}))
    .pipe(gulp.dest('img', {cwd: DEST}))
    .pipe($.cache(webp({quality: 100, method: 6})()))
    .pipe($.if('**/*.webp', gulp.dest('img/webp', {cwd: DEST})));
});

gulp.task('data', function() {
  locals = {
    jquery_ver: '2.1.3',
    jquery1_ver: '1.11.2',
    commits_selected: require('./tmp/commits_selected.json'),
    commits_rest: require('./tmp/commits_rest.json')
  };

  return gulp.src('jade/data/**/*.y{,a}ml')
    .pipe(vinylYamlData())
    .pipe(deepExtend(locals));
});

gulp.task('html', ['data'], function() {
  return gulp.src('jade/pages/{,*/,*/*/}*.jade', {cwd: SRC})
    .pipe($.frontMatter())
    .pipe($.data(function(file, done) {
      var basename = path.basename(file.path, '.jade');
      var projectImages = [];

      glob.sync('img/projects/' + basename + '/*.{png,jpg,gif}', {
        cwd: SRC
      }).forEach(function(imagePath) {
        var dimesions = imageSize(imagePath);

        projectImages.push({
          path: imagePath,
          width: dimesions.width,
          height: dimesions.height
        });
      });

      done(null, objectAssign({}, locals, file.frontMatter, {
        basename: basename,
        projectImages: projectImages
      }));
    }))
    .pipe($.jade({
      jade: jade,
      pretty: true,
      basedir: __dirname,
    }))
    .pipe(gulp.dest(DEST_DEBUG))
    .pipe($.htmlReplace({
      js: '/js/min.js',
      css: '/css/min.css'
    }))
    .pipe($.htmlmin({
      removeComments: true,
      collapseWhitespace: true,
      removeCommentsFromCDATA: true,
      removeCDATASectionsFromCDATA: true,
      minifyJS: {mangle: false}
    }))
    .pipe($.size({title: 'html:minified'}))
    .pipe(gulp.dest(DEST));
});

gulp.task('serve', ['watch'], function() {
  browserSync({
    server: DEST,
    open: false
  });
});

gulp.task('deploy', ['build'], function() {
  return gulp.src([
    path.join(DEST, '**/*'),
    '!' + path.join(DEST_DEBUG, '**/*'),
    '**/!{.DS_Store,Thumbs.db}'
  ])
    .pipe($.size({title: 'deploy'}))
    .pipe($.ghPages({branch: 'master'}));
});

function watch(path, tasks) {
  gulp.watch(path, {cwd: SRC}, tasks.concat(reload));
}

gulp.task('watch', ['build'], function() {
  watch('*.js', ['lint']);
  watch('public/**/*', ['copy']);
  watch('jade/**/*.jade', ['html']);
  watch('scss/{,*/}*.scss', ['styles']);
  watch('js/main/*.coffee', ['scripts']);
});

gulp.task('build', ['lint', 'copy', 'images', 'styles', 'scripts', 'html']);
gulp.task('default', ['serve']);
