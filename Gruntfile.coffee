module.exports = (grunt) ->
  'use strict'

  require('jit-grunt') grunt, {
    bower: 'grunt-bower-task'
  }

  path = require 'path'

  _ = require 'lodash'
  frontmatter = require 'gray-matter'
  sizeOf = require 'image-size'
  
  settings = grunt.file.readYAML 'settings.yaml'

  BIN = "node_modules/.bin/"

  SRC = settings.srcPath or ''
  DEST = settings.destPath or 'site/'
  JS = "#{ SRC }js/"

  grunt.initConfig
    bower:
      options:
        targetDir: "#{ DEST }.tmp/bower_exports/"
        cleanTargetDir: true
      install:
        options:
          bowerOptions:
            production: true
      
    modernizr:
      dist:
        devFile: 'remote'
        outputFile: "#{ SRC }public/js/modernizr.js"
        extra:
          # Modernizr won't includes the HTML5 Shiv.
          # Instead, the Shiv will be included in the IE-fix script file.
          # It saves 2kb on modern browser.
          shiv: false
          printshiv: false
          mq: true
        extensibility:
          svg: true
          touch: true
          cssanimations: true
          rgba: true
          history: true
          img_webp: true
  
    lodash:
      options:
        modifier: 'backbone'
        #plus: ['create']
        flags: ['--minify']
      custom:
        dest: "#{ JS }vendor/lodash.gruntbuild.min.js"

    copy:
      public:
        files: [
          expand: true
          cwd: "#{ SRC }public"
          src: ['**', '!**/{.DS_Store,Thumbs.db}']
          dest: DEST
          dot: true
        ]
      bower:
        files: [
          expand: true
          cwd: '<%= bower.options.targetDir %>/public'
          src: ['**', '!**/{.DS_Store,Thumbs.db}']
          dest: "#{ DEST }bower_components"
          dot: true
        ]
      bower_debug:
        files: [
          expand: true
          cwd: '<%= bower.options.targetDir %>/debug'
          src: ['**', '!**/{.DS_Store,Thumbs.db}']
          dest: "#{ DEST }/debug/bower_components"
          dot: true
        ]

    compass:
      options:
        config: "#{ SRC }scss/config.rb"
        cssDir: "#{ DEST }debug/css-readable"
        environment: 'development'
      all: {}
    
    autoprefixer:
      all:
        src: '<%= compass.options.cssDir%>{,*/}*.css'
      
    cssmin:
      options:
        report: 'min'
      dist:
        files: [
          expand: true
          cwd: '<%= compass.options.cssDir%>'
          src: ['{,*/}*.css']
          dest: "#{ DEST }css/"
        ]
    
    coffee:
      options:
        sourceMap: true
      dev:
        options:
          bare: true
        src: ["#{ JS }main/*.coffee", "#{ DEST }.tmp/router_data.coffee"]
        dest: "#{ DEST }debug/js/main.js"
      dist:
        src: '<%= coffee.dev.src %>'
        dest: "#{ DEST }.tmp/main.min.js"
    
    uglify:
      options:
        preserveComments: require 'uglify-save-license'
      main:
        options:
          banner: '/*! Copyright (c) ' +
            "2013 - #{ grunt.template.today('yyyy') } " +
            "#{ settings.author } | " +
            "MIT License */\n"
          compress:
            global_defs:
              DEBUG: false
            dead_code: true
        src: '<%= coffee.dist.dest %>'
        dest: '<%= uglify.main.src %>'
      bower:
        options:
          compress:
            # For /*cc_on!*/ comments
            dead_code: false
        files: [
          expand: true
          cwd: '<%= bower.options.targetDir %>'
          src: [
            '{,*/,*/*/}*.js',
            '!{,*/,*/*/}*{.,-}min.js', '!debug/{,*/}*.js'
          ]
          dest: '<%= bower.options.targetDir %>'
        ]
    
    concat:
      vendor:
        src: [
          "#{ JS }vendor/{,*/}*.js"
          '<%= bower.options.targetDir %>{,*/,*/*/}*.js'
          '!<%= bower.options.targetDir %>{public,ie,debug}{,*/,*/*/}*.js'
        ]
        dest: "#{ DEST }debug/js/vendor.js"
      vendor_ie:
        src: [
          "#{ JS }vendor-ie/{,*/}*.js"
          '<%= bower.options.targetDir %>/ie/{,*/}*.js'
        ]
        dest: "#{ DEST }js/vendor.ie.js"
      router_data:
        options:
          banner: 'routerData = '
        src: '<%= merge_data.router_data.dest %>'
        dest: "#{ DEST }.tmp/router_data.coffee"
      main:
        src: ["#{ DEST }debug/js/vendor.js", '<%= uglify.main.dest %>']
        dest: "#{ DEST }js/main.js"
    
    clean:
      site: [DEST]
      dev: ["#{ DEST }{.tmp,debug}"]
      
    imagemin:
      all:
        options:
          progressive: false
          use: [
            require('imagemin-pngcrush') {reduce: true}
            require('imagemin-zopfli') {more: true}
            require('imagemin-jpegtran')()
          ]
        files: [
          expand: true
          cwd: "#{ SRC }img/"
          src: ['**/*.{png,jpg,gif}']
          dest: "#{ DEST }img/"
        ]
    
    webp:
      options:
        quality: 100
        multiThreading: true
      all:
        files: [
          expand: true
          cwd: "#{ SRC }img/"
          src: ['**/*.{png,jpg}']
          dest: "#{ DEST }img/webp/"
        ]
    
    flex_svg:
      dist:
        files: [
          expand: true
          cwd: "#{ SRC }img"
          src: ['{,*/}*.svg']
          dest: "#{ DEST }.tmp/svg/"
        ]

    svgmin:
      options:
        plugins: [
          removeViewBox: false
        ]
      dist:
        files: [
          expand: true
          cwd: "#{ DEST }.tmp/svg/"
          src: ['{,*/}*.svg']
          dest: "#{ DEST }img/"
        ]
    
    merge_data:
      jade_data:
        options:
          data: ->
            getComponentVer = (name) ->
              grunt.file.readJSON(
                "#{ SRC }bower_components/#{ name }/bower.json"
              ).version

            {
              jquery_ver: getComponentVer 'jquery'
              jquery1_ver: getComponentVer 'jquery1'
            }
        src: [
          "#{ SRC }jade/data/*.{json,yaml}"
          "#{ SRC }tmp/commits_*.json"
        ]
        dest: "#{ DEST }.tmp/jade-data.json"
      router_data:
        options:
          data: (data) ->
            result = {}
            data.projects.forEach (project) ->
              result[project.name] =
                proj_title: project.title
                time: project.time
                role: project.role
            
            result.index = {}
            result.about =
              title: '渡邉伸之介について'
            result.projects =
              title: 'プロジェクト一覧'
            data = {}
            result
        src: ["#{ SRC }jade/data/projects.yaml"]
        dest: "#{ DEST }.tmp/router-data.json"
    
    jade:
      options:
        data: (dest, src) ->
          data = grunt.file.readJSON "#{ DEST }.tmp/jade-data.json"
          _.assign data, grunt.config 'jade.__context'

          data.basename = path.basename dest, '.html'
          
          ## path and file size of project image
          data.projectImages = []
          
          projectImagePaths = grunt.file.expand {
            cwd: SRC
          }, "img/projects/#{ data.basename }/**/*.{png,jpg,gif}"
          
          for imagePath, i in projectImagePaths
            _dimesions = sizeOf imagePath
        
            data.projectImages[i] =
              path: imagePath
              width: _dimesions.width
              height: _dimesions.height

          data.DEBUG = dest.indexOf('debug/') isnt -1
          data
        basedir: __dirname
        processContent: (original) ->
          { context, content } = frontmatter original
          grunt.config 'jade.__context', context

          """
          extend /jade/templates/#{ context.template or context.layout }
          block content
          #{ content.replace /^/gm, '  ' }
          """
      dev:
        options:
          pretty: true
        files: [
          expand: true
          cwd: "#{ SRC }jade/pages/"
          src: ['{,*/,*/*/}*.jade']
          dest: "#{ DEST }debug/"
          ext: '.html'
        ]
      dist:
        options:
          pretty: false
        files: [
          expand: true
          cwd: "#{ SRC }jade/pages/"
          src: ['{,*/,*/*/}*.jade']
          dest: DEST
          ext: '.html'
        ]
    
    shell:
      coffeelint:
        command:
          "#{ BIN }coffeelint #{ JS }main/*.coffee"
        options:
          stdout: true
      coffeelint_grunt:
        command:
          "#{ BIN }coffeelint #{ __filename }"
        options:
          stdout: true
    
    connect:
      options:
        livereload: 35729
        port: settings.liveReloadPort
      site:
        options:
          base: DEST
    
    open:
      site:
        # stackoverflow.com/questions/1349404/#comment13539914_8084248
        path: "#{ settings.siteURL }?v=#{
          Math.random()
            .toString(36)
            .substr(2, 5)
        }"
        app: 'Google Chrome'
    
    'gh-pages':
      options:
        base: DEST
        branch: 'master'
        message: 'deployed by grunt-gh-pages'
      site:
        src: ['**/*']
    
    prompt:
      message:
        options:
          questions: [
            {
              config: 'gh-pages.options.message'
              type: 'input'
              message: 'Enter the commit message.'
              default: 'deployed by grunt-gh-pages'
            }
          ]
    
    watch:
      options:
        livereload: '<%= connect.options.livereload %>'

      bower:
        files: ["#{ SRC }bower.json"]
        tasks: ['bower', 'uglify:bower']
      compass:
        files: ["#{ SRC }scss/*{,/*}.scss"]
        tasks: ['compass', 'postprocessCSS']
      coffee:
        files: ["#{ JS }main/*.coffee"]
        tasks: ['shell:coffeelint', 'coffee', 'uglify:main', 'concat:main']
      coffee_grunt:
        files: 'Gruntfile.coffee'
        tasks: ['shell:coffeelint_grunt']
      concat_vendor:
        files: '<%= concat.vendor.src %>'
        tasks: ['concat:vendor', 'concat:main']
      concat_vendor_ie:
        files: '<%= concat.vendor_ie.src %>'
        tasks: ['concat:vendor_ie']
      images:
        files: ["#{ SRC }img/**/*.{png,jpg,gif}"]
        tasks: ['concurrent:images']
      svg:
        files: ["#{ SRC }img/**/*.svg"]
        tasks: ['flex_svg', 'svgmin']
      jade:
        files: ["#{ SRC }jade/**/*.{jade,json,yaml,yml}"]
        tasks: ['merge_data', 'concurrent:jade']
      copy:
        files: ["#{ SRC }public/**/*"]
        tasks: ['copy:public']

    concurrent:
      preparing: [
        'bower', 'shell'
      ]
      dev: ['coffee:dev', 'jade:dev']
      dist: [
        'compass'
        'coffee:dist'
        'jade:dist'
        'imagemin'
        'webp'
        'flex_svg'
      ]
      finishing: [
        'concat'
        'postprocessCSS'
        'svgmin'
      ]
      jade: [
        'jade:dev'
        'jade:dist'
      ]
      images: [
        'imagemin'
        'webp'
        'jade'
      ]
  
  grunt.registerTask 'postprocessCSS', ['autoprefixer', 'cssmin']

  buildTasks = [
    'clean:site'
    'concurrent:preparing'
    'merge_data'
    'copy'
    'concat:router_data'
    'concurrent:dev', 'concurrent:dist'
    'uglify'
    'concurrent:finishing'
  ]
  
  grunt.registerTask 'build', buildTasks
  
  grunt.registerTask 'default', ['build', 'connect', 'watch']
  
  # task list for 'dist' tasks
  distTasks = _(buildTasks)
    .without('concurrent:dev')
    .union(['clean:dev'])
    .valueOf()
  
  grunt.registerTask 'dist',
    'Generate only the files to publish a website',
    distTasks
  
  grunt.registerTask 'deploy',
    'Deploy to Github Pages',
    ->
      gitConfig = require('git-config').sync()
      
      grunt.config 'gh-pages.options.user', gitConfig.user

      grunt.task.run 'dist', 'prompt', 'gh-pages', 'open'
