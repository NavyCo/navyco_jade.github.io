module.exports = (grunt) ->
  'use strict'

  require('jit-grunt') grunt, {bower: 'grunt-bower-task'}

  path = require 'path'

  _ = require 'lodash'
  saveLicense = require 'uglify-save-license'
  yfm = require 'assemble-front-matter'
  sizeOf = require 'image-size'
  jade = require 'jade'
  
  settings = grunt.file.readYAML 'settings.yaml'

  BIN = "#{ process.cwd() }/node_modules/.bin/"

  # Add '/' to the string if its last character is not '/'
  _addLastSlash = (str) ->
    if str.charAt(str.length - 1) is '/' or str is ''
      str
    else
      "#{ str }/"

  SRC = _addLastSlash(settings.srcPath) or ''
  DEST = _addLastSlash(settings.destPath) or 'site/'

  HOME_DIR = process.env.HOME or
    process.env.HOMEPATH or
    process.env.USERPROFILE
  
  JS = "#{ SRC }js/"
  
  grunt.initConfig
    bower:
      options:
        targetDir: "#{ DEST }.tmp/bower_exports/"
        cleanTargetDir: true
        bowerOptions:
          production: true
      
      install: {}
      
    modernizr:
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
  
    lodash:
      options:
        modifier: 'legacy'
        #include: []
        flags: ['--minify']
      custom:
        dest: "#{ JS }vendor/lodash.gruntbuild.js"

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
      dist:
        files: [
          expand: true
          cwd: '<%= compass.options.cssDir%>'
          src: ['{,*/}*.css']
          dest: "#{ DEST }css/"
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
        src: ["#{ JS }main/*.coffee"]
        dest: "#{ DEST }debug/js/main.js"
      dist:
        src: ['js/main/*.coffee']
        dest: "#{ DEST }.tmp/main.js"
    
    uglify:
      options:
        preserveComments: saveLicense
      
      main:
        options:
          banner: "/*! Copyright (c) 2013 #{ settings.author } | MIT License */\n"
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
            '!{,*/,*/*/}*{.min,-min}.js', '!debug/{,*/}*.js'
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
      main:
        src: ["#{ DEST }debug/js/vendor.js", '<%= uglify.main.dest %>']
        dest: "#{ DEST }js/main.js"
    
    clean:
      site: path.resolve DEST
      tmpfiles: ["#{ DEST }.tmp"]
      debugFiles: ["#{ DEST }debug"]
      
    imagemin:
      all:
        options:
          progressive: false
        files: [
          expand: true
          cwd: "#{ SRC }img/"
          src: ['**/*.{png,jpg,gif}']
          dest: "#{ DEST }img/"
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
          src: ['*.svg']
          dest: "#{ DEST }img/"
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
    
    watch:
      options:
        livereload: '<%= connect.options.livereload %>'

      bower:
        files: ["#{ SRC }bower.json"]
        tasks: ['bower', 'uglify:bower']
      compass:
        files: ["#{ SRC }scss/*.scss"]
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
        tasks: ['imagemin:all']
      svg:
        files: ["#{ SRC }img/**/*.svg"]
        tasks: ['flexSVG', 'svgmin']
      jade:
        files: ["#{ SRC }jade/**/*.{jade,json,yaml,yml}"]
        tasks: ['jadeTemplate:dev', 'jadeTemplate:dist']
      copy:
        files: ["#{ SRC }public/**/*"]
        tasks: ['copy:public']
        
    'gh-pages':
      options:
        base: DEST
        branch: 'master'
        message: 'deployed by grunt-gh-pages'
      site:
        src: '**/*'
    
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

    concurrent:
      preparing: [
        'bower', 'shell'
      ]
      dev: ['coffee:dev', 'jadeTemplate:dev']
      dist: [
        'compass'
        'coffee:dist'
        'jadeTemplate:dist'
        'imagemin'
        'flexSVG'
      ]
  
  # Compile .jade files with frontmatter
  grunt.registerTask 'jadeTemplate',
  'Compile Jade files with front-matter', (mode) ->
    
    devMode = mode isnt 'dist'

    globalData = {}
    
    grunt.file.recurse "#{ SRC }jade/data/",
      (abspath, rootdir, subdir, filename) ->
        _basename = path.basename filename, path.extname(filename)
    
        if path.extname(filename) is '.json'
          globalData[_basename] = grunt.file.readJSON abspath

        if path.extname(filename) is '.yaml' or
        path.extname(filename) is '.yml'
          globalData[_basename] = grunt.file.readYAML abspath
    
    getComponentVer = (name) ->
      require("./#{ SRC }bower_components/#{ name }/bower.json").version

    globalData.jquery_ver = getComponentVer 'jquery'
    globalData.jquery1_ver = getComponentVer 'jquery1'

    mapOptions =
      cwd: "#{ SRC }jade/pages/"
      filter: 'isFile'
      ext: '.html'
      rename: (dest, src) ->
        dest + (if devMode then 'debug/' else '') + src
    
    fileMap = grunt.file.expandMapping '**/*.jade', DEST, mapOptions
        
    compileOptions =
      pretty: false
      # HTMLファイルのパスは書き出し先のフォルダのルートが基準となる
      filename: mapOptions.cwd + '../'
    
    for filePath in fileMap
      srcPath = filePath.src[0]
      destPath = filePath.dest
      
      raw = yfm.extract srcPath
      
      localData = raw.context
      
      jadeTxt = """
      extend ../templates/#{ localData.template or localData.layout }
      block content
      #{ raw.content.replace(/\n/g, '\n  ') }
      """
      
      # helper
      ## ディレクトリ名と拡張子を取り除いたファイル名
      localData.basename = path.basename srcPath, '.jade'

      ## プロジェクトの画像のファイルパス、サイズ
      localData.projectImages = []

      projectImagePaths = grunt.file.expand {
        cwd: SRC
      }, "img/projects/#{ localData.basename }/**/*.{png,jpg,gif}"
      
      for imagePath, i in projectImagePaths
        _dimesions = sizeOf imagePath
        
        localData.projectImages[i] =
          path: imagePath
          width: _dimesions.width
          height: _dimesions.height
          
      
      allData = _.assign globalData, localData, compileOptions
      
      if devMode
        allData = _.assign allData, {DEBUG: true, pretty: true}
      
      jade.render jadeTxt, allData, (err, html) ->
        if err
          console.warn err
        else
          grunt.file.write destPath, html
          console.log "File \"#{ destPath }\" created."
      
  
  # Remove 'width' and 'height' properties from SVG
  grunt.registerTask 'flexSVG', 'An internal task.', ->
    _cwd = "#{ SRC }img/"
    srcSVGs = grunt.file.expand {cwd: _cwd}, '*.svg'
    srcSVGs.forEach (filepath) ->
      svgString = grunt.file.read _cwd + filepath
      match = svgString.match /width([^)]+)viewBox/
      if match?
        svgString = svgString.replace match, 'viewBox'
      grunt.file.write "#{ DEST }.tmp/svg/#{ filepath }", svgString
  
  grunt.registerTask 'addNoJekyll',
    'Add .nojekyll if needed',
    ->
      if grunt.file.expand("#{ DEST }**/_*").length > 0
        grunt.file.write  "#{ DEST }.nojekyll", ''
        console.log "File \"#{ DEST }.nojekyll\" created."
  
  grunt.registerTask 'postprocessCSS', ['autoprefixer', 'cssmin']

  defaultTasks = [
    'clean:site' #reset
    'concurrent:preparing'
    'copy'
    'concurrent:dev', 'concurrent:dist'
    'uglify', 'concat' #minify JS
    'postprocessCSS'
    'svgmin'
    'connect'
  ]
  
  grunt.registerTask 'build', defaultTasks
  
  grunt.registerTask 'default', ['build', 'watch']
  
  # task list for 'dist' tasks
  distTasks = _(defaultTasks)
    .without('concurrent:dev')
    .union(['clean:tmpfiles', 'clean:debugFiles', 'addNoJekyll'])
    .valueOf()
  
  grunt.registerTask 'dist',
    'Generate only the files to publish a website',
    distTasks
  
  grunt.registerTask 'deploy',
    'Deploy to Github Pages',
    ->
      grunt.loadNpmTasks 'grunt-prompt'
      grunt.loadNpmTasks 'grunt-gh-pages'
      grunt.loadNpmTasks 'grunt-open'
      
      ini = require 'ini'
      gitConfig = ini.parse grunt.file.read "#{ HOME_DIR }/.gitconfig"
      
      grunt.config.set 'gh-pages.options.user', gitConfig.user

      grunt.task.run 'dist', 'prompt', 'gh-pages', 'open'
