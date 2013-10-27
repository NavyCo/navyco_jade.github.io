'use strict'

yamlFront = require 'yaml-front-matter'
jade = require 'jade'

module.exports = (grunt) ->
  require('load-grunt-tasks')(grunt)
  
  _ = grunt.util._
  
  settings = grunt.file.readYAML 'settings.yaml'
  
  BIN = "#{ process.cwd() }/node_modules/.bin/"

  # 文字列の末尾が '/' でなければ、それを追加する
  _addLastSlash = (str) ->
    if str.charAt(str.length - 1) is '/' or str is ''
      str
    else
      "#{ str }/"

  SRC_ROOT = _addLastSlash(settings.srcPath) or ''
  DEST_ROOT = _addLastSlash(settings.destPath) or 'site/'
  
  JS_ROOT = "#{ SRC_ROOT }js/"

  # For Uglify
  getCommentIsBanner = do ->
    prevCommentLine = 0

    return (node, comment) ->
      if comment.type is 'comment2' and
      (/^\!|@preserve|@license|@cc_on/mi.test comment.value)
        return true
      
      # コメントが先頭行にあるか、先頭行から連なるコメントである場合、バナーであると判断する
      result = comment.line <= 1 or comment.line is prevCommentLine + 1

      # コメントがバナーに含まれる場合、そのコメントの行番号を保存する
      # コメントがバナーではない場合、行番号の保存をリセットする
      if result
        prevCommentLine = comment.line
      else
        prevCommentLine = 0
        
      return result
  
  # For Jade
  DEBUG = true
  
  globalJadeData = ->
    data = {}
    
    grunt.file.recurse "#{ SRC_ROOT }jade/data/",
    (abspath, rootdir, subdir, filename) ->
      filename_WO_ext = filename.replace(/\..+/, '')
      
      if filename.indexOf('.json') isnt -1
        data[filename_WO_ext] = grunt.file.readJSON abspath

      if filename.indexOf('.yaml') isnt -1 or filename.indexOf('.yml') isnt -1
        filename_WO_ext = filename.replace(/\..+/, '')
        data[filename_WO_ext] = grunt.file.readYAML abspath
    
    return data
  
  grunt.initConfig
    bower:
      options:
        targetDir: "#{ DEST_ROOT }.tmp/bower_exports"
        cleanTargetDir: true
        
      install: {}
      
    modernizr:
      devFile: 'remote'
      outputFile: "#{ SRC_ROOT }public/js/modernizr.js"
      extra:
        shiv : false
        printshiv : false
        mq: true
      extensibility:
        svg: true
        touch: true
        cssanimations: true
        css_mask: true
        video: true
        rgba: true
  
    lodash:
      options:
        modifier: 'legacy'
        #include: []
        flags: ['--minify']
      custom:
        dest: "#{ JS_ROOT }vendor/lodash.gruntbuild.js"

    casperjs:
      files: ["#{ SRC_ROOT }casperjs/**/*.js", "#{ SRC_ROOT }casperjs/**/*.coffee"]
      
    copy:
      public:
        files: [
          expand: true
          cwd: "#{ SRC_ROOT }public"
          src: ['**', '!**/{.DS_Store,Thumbs.db}']
          dest: DEST_ROOT
          dot: true
        ]
      bower:
        files: [
          expand: true
          cwd: '<%= bower.options.targetDir %>/public'
          src: ['**', '!**/{.DS_Store,Thumbs.db}']
          dest: "#{ DEST_ROOT }bower_components"
          dot: true
        ]
      bower_debug:
        files: [
          expand: true
          cwd: '<%= bower.options.targetDir %>/debug'
          src: ['**', '!**/{.DS_Store,Thumbs.db}']
          dest: "#{ DEST_ROOT }/debug/bower_components"
          dot: true
        ]

    compass:
      options:
        config: "#{ SRC_ROOT }scss/config.rb"
      dev:
        options:
          cssDir: "#{ DEST_ROOT }debug/css-readable/"
          environment: 'development'
      dist:
        options:
          cssDir: "#{ DEST_ROOT }css/"
          environment: 'production'
    
    autoprefixer:
      all:
        src: [
          "#{ DEST_ROOT }debug/css-readable/**/*.css"
          "#{ DEST_ROOT }css/**/*.css"
        ]
    
    csslint:
      lax:
        options:
          import: false
          ids: false
        src: ['<%= compass.readable.options.cssDir %>/*.css']
    
    coffee:
      options:
        sourceMap: true

      dev:
        options:
          bare: true
        src: ["#{ JS_ROOT }main/*.coffee"]
        dest: "#{ DEST_ROOT }debug/js/main.js"
      dist:
        src: ['js/main/*.coffee']
        dest: "#{ DEST_ROOT }.tmp/main.js"
    
    uglify:
      options:
        preserveComments: getCommentIsBanner
        
      main:
        options:
          banner: do ->
            if grunt.file.isFile "#{ JS_ROOT }main/banner.js"
              grunt.file.read "#{ JS_ROOT }main/banner.js"
            else
              ''
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
          src: ['**/*.js', '!**/*{.min,-min}.js', '!debug/**/*']
          dest: '<%= bower.options.targetDir %>'
        ]
    
    concat:
      vendor:
        src: [
          "#{ JS_ROOT }vendor/**/*.js"
          '<%= bower.options.targetDir %>/**/*.js'
          '!<%= bower.options.targetDir %>/{public,ie,debug}/**/*.js'
        ]
        dest: "#{ DEST_ROOT }debug/js/vendor.js"
      vendor_ie:
        src: [
          "#{ JS_ROOT }vendor-ie/*.js"
          '<%= bower.options.targetDir %>/ie/**/*.js'
        ]
        dest: "#{ DEST_ROOT }js/vendor.ie.js"
      main:
        src: ["#{ DEST_ROOT }debug/js/vendor.js", '<%= uglify.main.dest %>']
        dest: "#{ DEST_ROOT }js/main.js"
    
    clean:
      site: DEST_ROOT
      tmpfiles: ["#{ DEST_ROOT }.tmp"]
      debugFiles: ["#{ DEST_ROOT }debug"]
      
    prettify:
      options:
        indent_size: 2
      files:
        expand: true
        cwd: DEST_ROOT
        src: ['**/*.html', '!debug/**/*', '!**/*-debug.html']
        dest: "#{ DEST_ROOT }debug/html-readable"
        
    imagemin:
      all:
        options:
          progressive: false
        files: [
          expand: true
          cwd: "#{ SRC_ROOT }img/"
          src: ['**/*.{png,jpg,gif}']
          dest: "#{ DEST_ROOT }img/"
        ]

    svgmin:
      options:
        plugins: [
          removeViewBox: false
        ]
      dist:
        files: [
          expand: true
          cwd: "#{ DEST_ROOT }.tmp/svg/"
          src: ['*.svg']
          dest: "#{ DEST_ROOT }svg/"
        ]
    
    shell:
      coffeelint:
        command:
          "#{ BIN }coffeelint #{ JS_ROOT }main/*.coffee"
        options:
          stdout: true
      coffeelint_grunt:
        command:
          "#{ BIN }coffeelint Gruntfile.coffee"
        options:
          stdout: true
    
    connect:
      site:
        options:
          base: DEST_ROOT
    
    open:
      site:
        path: 'http://shinnn.github.io/'
        app: 'Google Chrome'
    
    watch:
      options:
        # http://feedback.livereload.com/knowledgebase/articles/86242
        # if you want to use it with local files,
        # be sure to enable “Allow access to file URLs” checkbox
        # in Tools > Extensions > LiveReload after installation.
        livereload: true
      bower:
        files: ["#{ SRC_ROOT }bower.json"]
        tasks: ['bower']
      compass:
        files: ["#{ SRC_ROOT }scss/*.scss"]
        tasks: ['compass', 'autoprefixer']
      coffee:
        files: ["#{ JS_ROOT }main/*.coffee"]
        tasks: ['shell:coffeelint', 'coffee', 'uglify', 'concat:main']
      coffee_grunt:
        files: ['Gruntfile.coffee']
        tasks: ['shell:coffeelint_grunt']
      concat_vendor:
        files: ["#{ JS_ROOT }vendor/*.js"]
        tasks: ['concat:vendor']
      concat_vendor_ie:
        files: ["#{ JS_ROOT }vendor-ie/*.js"]
        tasks: ['concat:vendor_ie']
      concat_dist:
        files: ["#{ DEST_ROOT }js/debug/*.js"]
        tasks: ['concat:dist', 'clean:tmpfiles']
      images:
        files: ["#{ SRC_ROOT }img/**/*.{png,jpg,gif}"]
        tasks: ['imagemin']
      svg:
        files: ["#{ SRC_ROOT }/svg/*.svg"]
        tasks: ['flexSVG', 'svgmin']
      jade:
        files: ["#{ SRC_ROOT }jade/**/*.{jade,json,yaml,yml}"]
        tasks: ['jadeTemplate', 'prettify']
      copy:
        files: ["#{ SRC_ROOT }/public/**/*"]
        tasks: ['copy', 'imagemin']
      html:
        files: ['index.html']
        
    'gh-pages':
      site:
        options:
          base: DEST_ROOT
          branch: 'master'
          message: 'deployed by grunt-gh-pages'
          user:
            name: 'shinnn'
        src: '**/*'
    
    prompt:
      message:
        options:
          questions: [
            {
              config: 'gh-pages.site.options.message'
              type: 'input'
              message: 'Please enter the commit message for your changes.'
              default: 'deployed by grunt-gh-pages'
            }
          ]

    concurrent:
      beginning: ['bower', 'flexSVG', 'shell:coffeelint_grunt', 'shell:coffeelint']
      dev: ['compass:dev', 'coffee:dev', 'jadeTemplate:dev']
      dist: ['compass:dist', 'coffee:dist', 'jadeTemplate:dist', 'imagemin']
  
  grunt.task.registerTask 'jadeTemplate',
  'Compile Jade Files with front-matter', (mode) ->
    readOptions =
      cwd: "#{ SRC_ROOT }jade/pages/"
      filter: 'isFile'
    
    jadeFiles = grunt.file.expand readOptions, '**/*.jade'
    
    compileOptions =
      # 可読化する際は grunt-prettify で行う
      pretty: false
      # HTMLファイルのパスは書き出し先のフォルダのルートが基準となる
      filename: readOptions.cwd + '../'
    
    for file in jadeFiles
      raw = grunt.file.read readOptions.cwd + file
      splitted = yamlFront.loadFront(raw)
      
      localData = _.omit splitted, '__content'
      
      addition = ''
      
      # テンプレートファイルの参照先のパス
      _templatePath = ''
      _dirDepth = file.match(/\//g)?.length or 0
      _templatePath += '../' while _dirDepth--
      
      if localData.template
        addition += "extend ../templates/#{ localData.template }\n"
      if localData.layout
        addition += "extend ../layouts/#{ localData.layout }\n"

      jadeTxt = addition + splitted.__content
      
      # ヘルパー
      ## ディレクトリ名と拡張子を取り除いたファイル名 
      localData.basename = file.substring file.lastIndexOf('/')+1, file.lastIndexOf('.')
      
      ## インライン JavaScript
      ## tmp
      # localData.inline = 
      
      allData = _.extend globalJadeData(), localData, compileOptions
      
      if(mode isnt 'dev')      
        jade.render jadeTxt, allData, (err, html) ->
          if err
            console.warn err
          else
            grunt.file.write DEST_ROOT + file.replace('.jade', '.html'), html
            console.log "File \"#{ DEST_ROOT +
              readOptions.cwd +
              file.replace('.jade', '.html') }\" created."
      
      if(mode isnt 'dist')
        allDataDebug = _.extend allData, {DEBUG: true}
        jade.render jadeTxt, allDataDebug, (err, html) ->
          if err
            console.warn err
          else
            grunt.file.write "#{ DEST_ROOT }debug/#{ file.replace('.jade', '.html') }", html

  
  # SVG の width, height 属性を取り除く
  grunt.task.registerTask 'flexSVG', 'An internal task.', ->
    _cwd = 'svg/'
    srcSVGs = grunt.file.expand {cwd: _cwd}, '*.svg'
    srcSVGs.forEach (filepath) ->
      svgString = grunt.file.read _cwd + filepath
      match = svgString.match /width([^)]+)viewBox/
      if match?
        svgString = svgString.replace match, 'viewBox'
      grunt.file.write "#{ DEST_ROOT }.tmp/svg/#{ filepath }", svgString
  
  defaultTasks = [
    'clean:site' #reset
    'concurrent:beginning'
    'copy'
    'concurrent:dev', 'concurrent:dist'
    'uglify', 'concat' #minify JS
    'prettify', 'autoprefixer'
    'flexSVG', 'svgmin' # optimize SVG
    'clean:tmpfiles'
    'connect', 'watch'
  ]
  
  grunt.task.registerTask 'default', defaultTasks
  
  # task list for 'dist' tasks
  distTasks = _.reject defaultTasks, (val) ->
    val is 'prettify' or val.indexOf('dev') isnt -1

  # 'watch'タスクを取り除き、新たなタスクを追加
  distTasks.splice distTasks.length-1, 1, 'clean:debugFiles'

  grunt.task.registerTask 'dist',
  'Generate only the files to publish a website', distTasks
  
  grunt.task.registerTask 'deploy',
  'Deploy to Github Pages', ['dist', 'prompt', 'gh-pages', 'open']
  