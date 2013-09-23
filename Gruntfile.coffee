yamlFront = require 'yaml-front-matter'
jade = require 'jade'

module.exports = (grunt) ->
  devDeps = grunt.file.readJSON('package.json').devDependencies

  for taskName of devDeps
    if 'grunt-' is taskName.substring 0, 6
      grunt.loadNpmTasks taskName
  
  _ = grunt.util._
  
  settings = grunt.file.readYAML 'settings.yaml'
  
  BIN = "#{ process.cwd() }/node_modules/.bin/"

  SRC_ROOT = settings.srcPath or ''
  DEST_ROOT = settings.destPath or 'site/'
  
  JS_ROOT = "#{ SRC_ROOT }js/"
  
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
    compass:
      options:
        config: "#{ SRC_ROOT }scss/config.rb"
        sassDir: "#{ SRC_ROOT }scss/"
      dev:
        options:
          cssDir: "#{ DEST_ROOT }/debug/css-readable/"
          environment: 'development'
          outputStyle: 'expanded'
      dist:
        options:
          cssDir: "#{ DEST_ROOT }css/"
          environment: 'production'
          outputStyle: 'compressed'
    
    csslint:
      lax:
        options:
          import: false
          ids: false
        src: ['<%= compass.readable.options.cssDir %>/*.css']
    
    lodash:
      options:
        modifier: 'legacy'
        include: []
        flags: ['--minify']
      custom:
        dest: "#{ JS_ROOT }vendor/lodash.gruntbuild.js"
    
    coffee:
      dev:
        options:
          bare: true
          sourceMap: true
        src: ["#{ JS_ROOT }main/*.coffee"]
        dest: "#{ DEST_ROOT }debug/js/main.js"
      dist:
        options:
          sourceMap: true
        src: ['js/main/*.coffee']
        dest: "#{ DEST_ROOT }.tmp/main.js"
    
    uglify:
      main:
        options:
          preserveComments: 'true'
          banner: grunt.file.read "#{ JS_ROOT }main/banner.js"
          compress:
            global_defs:
              DEBUG: false
            dead_code: true
        src: '<%= coffee.dist.dest %>'
        dest: '<%= uglify.main.src %>'
    
    concat:
      vendor:
        src: ["#{ JS_ROOT }vendor/*.js"]
        dest: "#{ DEST_ROOT }debug/js/vendor.js"
      vendor_ie:
        src: ["#{ JS_ROOT }vendor-ie/*.js"]
        dest: "#{ DEST_ROOT }js/vendor.ie.js"
      dist:
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

    modernizr:
      devFile: 'remote'
      outputFile: "#{ JS_ROOT }vendor/modernizr.gruntbuild.js"
      extensibility:
        mq: true
        svg: true
        touch: true
        cssanimations: true
        css_mask: true
        video: true
        rgba: true
    
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
    
    copy:
      public:
        files: [
          expand: true
          cwd: "#{ SRC_ROOT }public/"
          src: ['**', '!**/.DS_Store', '!**/Thumbs.db']
          dest: DEST_ROOT
          dot: true
        ]
    
    connect:
      site:
        options:
          base: DEST_ROOT
    
    open:
      site:
        path: 'http://127.0.0.1:8000/'
        app: 'Google Chrome'
    
    watch:
      options:
        # http://feedback.livereload.com/knowledgebase/articles/86242
        # if you want to use it with local files,
        # be sure to enable “Allow access to file URLs” checkbox
        # in Tools > Extensions > LiveReload after installation.
        livereload: true
      compass:
        files: ["#{ SRC_ROOT }scss/*.scss"]
        tasks: ['compass']
      coffee:
        files: ["#{ JS_ROOT }main/*.coffee"]
        tasks: ['shell:coffeelint', 'coffee', 'uglify', 'concat:dist']
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
      svg:
        files: ["#{ SRC_ROOT }/svg/*.svg"]
        tasks: ['flexSVG', 'svgmin']
      jade:
        files: ["#{ SRC_ROOT }jade/**/*.jade"
                "#{ SRC_ROOT }jade/**/*.json"
                "#{ SRC_ROOT }jade/**/*.yaml", "#{ SRC_ROOT }jade/**/*.yml"]
        tasks: ['jadeTemplate', 'prettify']
      copy:
        files: ["#{ SRC_ROOT }/public/**/*"]
      html:
        files: ['index.html']
        
    'gh-pages':
      site:
        options:
          base: DEST_ROOT
          branch: 'master'
          message: 'auto commit by grunt-gh-pages'
          user:
            name: 'shinnn'
            email: 'snnskwtnb@gmail.com'
        src: '**/*'

    concurrent:
      beginning: ['flexSVG', 'shell:coffeelint_grunt', 'shell:coffeelint']
      dev: ['compass:dev', 'coffee:dev', 'jadeTemplate:dev']
      dist: ['compass:dist', 'coffee:dist', 'jadeTemplate:dist']
      
  grunt.task.registerTask 'jadeTemplate',
  'Compile Jade Files with front-matter', (mode) ->
    readOptions =
      cwd: "#{ SRC_ROOT }jade/pages/"
      filter: 'isFile'
    
    jadeFiles = grunt.file.expand readOptions, '**/*.jade'
    
    compileOptions =
      pretty: false
      filename: readOptions.cwd + '/../'
    
    for file in jadeFiles
      raw = grunt.file.read readOptions.cwd + file
      splitted = yamlFront.loadFront(raw)
      
      localData = _.omit splitted, '__content'
    
      addition = ''
      if localData.template
        addition += "extend ../templates/#{ localData.template }\n"
      if localData.layout
        addition += "extend ../layouts/#{ localData.layout }\n"

      jadeTxt = addition + splitted.__content
      
      allData = grunt.util._.extend globalJadeData(), localData, compileOptions
      
      if(mode isnt 'dev')      
        jade.render jadeTxt, allData, (err, html) ->
          if err then throw err
          grunt.file.write DEST_ROOT + file.replace('.jade', '.html'), html
      
      if(mode isnt 'dist')
        allDataDebug = _.extend allData, {DEBUG: true}
        jade.render jadeTxt, allDataDebug, (err, html) ->
          if err then throw err
          grunt.file.write DEST_ROOT + file.replace('.jade', '-debug.html'), html

  
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
    'prettify'
    'flexSVG', 'svgmin' # optimize SVG
    'clean:tmpfiles'
    'connect', 'watch'
  ]
  
  grunt.task.registerTask 'default', defaultTasks
  
  # task list for 'dist' tasks
  distTasks = grunt.util._.reject defaultTasks, (val) ->
    val is 'prettify' or val.indexOf('dev') isnt -1

  # タスクの配列の最後から2番目、'watch'タスクに入る前に、新たなタスクを追加
  distTasks.splice distTasks.length-2, 0, 'clean:debugFiles', 'open'

  grunt.task.registerTask 'dist',
  'Generate only the files to publish a website', distTasks
  
  grunt.task.registerTask 'deploy',
  'Deploy to Github Pages', ['dist', 'gh-pages']
  