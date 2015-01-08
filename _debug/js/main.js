/*! MIT (c) Shinnosuke Watanabe */
(function() {
  'use strict';
  var $doc, $w, AppView, ContentView, HomeView, NavLabelView, NavPointView, Page, PrevNextButtonView, ProjectImageView, ProjectThumbnailView, Router, ShowMoreCommitsView, TabView, VerticalLineView, VerticalNavView, container, content, hidden, router, visibilityChange, _date;

  if (typeof DEBUG === "undefined" || DEBUG === null) {
    this.DEBUG = true;
  }

  $w = $(window);

  $doc = $(document);

  jQuery.fn.safeAnimate = (function() {
    var _protoSlice;
    _protoSlice = Array.prototype.slice;
    return function() {
      var args, _ref;
      args = _protoSlice.call(arguments, 0);
      return (_ref = this.stop()).animate.apply(_ref, args);
    };
  })();

  if (!$.support.transition) {
    $.fn.transition = $.fn.animate;
  }

  jQuery.fn.centerHeight = function() {
    var $this;
    $this = $(this);
    return Math.round($this.position().top + $this.height() * 0.5);
  };

  jQuery.fn._enableWebP = function() {
    return this;
  };

  Modernizr.on('webp', function(result) {
    if (result) {
      return jQuery.fn._enableWebP = function() {
        this.each(function() {
          var $this, webpPath;
          $this = $(this);
          webpPath = $this.attr('data-original').replace('img/', 'img/webp/').replace('.jpg', '.webp').replace('.png', '.webp');
          return $this.attr('data-original', webpPath);
        });
        return this;
      };
    }
  });

  if (typeof document.hidden !== 'undefined') {
    hidden = 'hidden';
    visibilityChange = 'visibilitychange';
  } else if (typeof document.mozHidden !== 'undefined') {
    hidden = 'mozHidden';
    visibilityChange = 'mozvisibilitychange';
  } else if (typeof document.msHidden !== 'undefined') {
    hidden = 'msHidden';
    visibilityChange = 'msvisibilitychange';
  } else if (typeof document.webkitHidden !== 'undefined') {
    hidden = 'webkitHidden';
    visibilityChange = 'webkitvisibilitychange';
  }

  if (DEBUG) {
    console.log('--- DEBUG MODE ---');
    _date = +new Date();
    $(function() {
      return console.log("jQuery's 'ready' event fired: " + (+new Date() - _date) + " ms");
    });
    $w.on('load', function() {
      return console.log("'load' event fired: " + (+new Date() - _date) + " ms");
    });
  }

  container = content = router = null;

  $(function() {
    var prevNextButton;
    router = new Router();
    container = new AppView({
      model: new Page()
    });
    content = new ContentView();
    prevNextButton = new PrevNextButtonView();
    Backbone.history.start({
      pushState: true,
      root: DEBUG ? '/_debug/' : '/'
    });
    $('.intersection .point > div').css({
      visibility: 'visible'
    });
    return container.refresh();
  });

  Page = Backbone.Model.extend({
    categorize: function() {
      var basename, category, frag, name;
      frag = Backbone.history.fragment;
      category = 'index';
      basename = 'index';
      if (frag.includes('projects')) {
        category = 'projects';
        for (name in routerData) {
          if (location.href.includes("" + name + "/")) {
            basename = name;
          }
        }
      } else if (frag.includes('about')) {
        category = 'about';
        basename = 'about';
      } else if (frag.includes('blog')) {
        category = 'blog';
        basename = 'blog';
      }
      return this.set({
        category: category,
        basename: basename
      });
    }
  });

  Router = Backbone.Router.extend({
    prev: Backbone.history.fragment,
    routes: {
      '': 'index',
      'index.html': 'index',
      'about/': 'about',
      'projects/': 'projects',
      'projects/:name/': 'project-single'
    },
    'index': function() {
      return content.render('/index.html', function() {
        content.show();
        return new HomeView().render();
      });
    },
    'about': function() {
      return content.render('/about/', function() {
        return content.show();
      });
    },
    'projects': function() {
      return content.render('/projects/', function() {
        content.show();
        new ProjectThumbnailView().render();
        return new ShowMoreCommitsView();
      });
    },
    'project-single': function(name) {
      return content.render("/projects/" + name + "/", function() {
        return new ProjectImageView().render();
      });
    }
  });

  NProgress.configure({
    trickleRate: 0.2,
    trickleSpeed: 265,
    showSpinner: false
  });

  AppView = Backbone.View.extend({
    el: '#container',
    events: {
      'click a:not([target])': 'setInternalLink'
    },
    initialize: function() {
      FastClick.attach(this.$el[0]);
      this.menuTabs = new TabView();
      this.verticalNav = new VerticalNavView();
      this.model.on('change:category', (function(_this) {
        return function(model, value) {
          _this.menuTabs.activate(value);
          return _this.verticalNav.setLink(value);
        };
      })(this));
      this.model.on('change:basename', (function(_this) {
        return function(model, value) {
          return _this.verticalNav.render(value);
        };
      })(this));
      return $doc.on(visibilityChange, (function(_this) {
        return function() {
          return _this.verticalNav.render(_this.model.get('basename'));
        };
      })(this));
    },
    setInternalLink: function(e) {
      e.preventDefault();
      return content.hide(function() {
        router.navigate(e.currentTarget.pathname, {
          trigger: true
        });
        if (router.prev === Backbone.history.fragment) {
          content.show();
        }
        return scrollTo(0, 0);
      });
    },
    refresh: function() {
      return this.model.categorize();
    }
  });

  TabView = Backbone.View.extend({
    el: '#tabs > a',
    activate: function(category) {
      return this.$el.filter('.active').removeClass('active').end().filter("[data-category=" + category + "]").addClass('active');
    }
  });

  VerticalNavView = Backbone.View.extend({
    el: 'header div.intersection',
    initialize: function() {
      this.labels = new NavLabelView();
      this.points = new NavPointView();
      return this.line = new VerticalLineView();
    },
    hide: function() {
      this.line.hide();
      return this.$el.fadeOut(42);
    },
    setLink: function(category) {
      var $link, _backToCategory;
      $link = this.$el.find('a');
      _backToCategory = $link.attr('href').replace(/\/[^\/]+?\.html/, "/" + category + ".html");
      return $link.attr('href', _backToCategory);
    },
    render: function(basename) {
      var pageData;
      this.points.show();
      if (basename === 'index') {
        return this.hide();
      } else {
        pageData = routerData[container.model.get('basename')];
        if (pageData.title) {
          $('#first-location').show();
          $('#first-location .label').text(pageData.title);
          $('#article-title, #article-info').fadeOut(42);
          this.line.extendToFirst();
          $('#first-point').css({
            top: "" + ($('#first-location').height() * 0.5) + "px"
          });
        }
        if (pageData.proj_title) {
          $('#first-location .label').text('プロジェクト一覧');
          $('.intersection').show();
          $('#article-info .time').text(pageData.time);
          $('#article-info .roles').text(pageData.role.join(' / '));
          $('#first-point').css({
            top: "" + ($('#first-location').height() * 0.5) + "px"
          });
          $('#article-title-point').css({
            top: "" + ($('#article-title').height() * 0.5) + "px"
          });
          $('#article-info-point').css({
            top: "" + ($('#article-info').height() * 0.5) + "px"
          });
          return this.line.extendToArticleTitle();
        }
      }
    }
  });

  NavPointView = Backbone.View.extend({
    el: 'div.intersection .point > div',
    hide: function() {
      var $first;
      return $first = this.$el.eq(0);
    },
    show: function() {
      return this.$el.fadeIn();
    }
  });

  NavLabelView = Backbone.View.extend({
    el: 'div.intersection > .label'
  });

  VerticalLineView = Backbone.View.extend({
    el: '#vertical-line',
    hide: function() {
      return this.$el.transit({
        height: '0'
      });
    },
    extendToFirst: function() {
      return this.$el.transit({
        height: $('#first-location').centerHeight() + 'px'
      });
    },
    extendToArticleTitle: function() {
      return this.$el.transit({
        height: $('#article-info').centerHeight() + 'px'
      });
    }
  });

  PrevNextButtonView = Backbone.View.extend({
    el: '#prev-article-button, #next-article-button',
    initialize: function() {
      return $w.on('resize', (function(_this) {
        return function() {
          return _this.render();
        };
      })(this));
    },
    render: function() {
      if (Modernizr.mq('only screen and (min-width: 1280px)')) {

      }
    }
  });

  ContentView = Backbone.View.extend({
    el: 'main',
    hide: function(callback) {
      NProgress.set(0.0).start();
      return this.$el.fadeTo(8, 0.010, function() {
        if (callback) {
          return callback();
        }
      });
    },
    show: function(callback) {
      NProgress.done();
      this.$el.fadeTo(80, 1);
      router.prev = Backbone.history.fragment;
      if (callback) {
        return callback();
      }
    },
    render: function(page, callback) {
      if (DEBUG) {
        page = "/_debug" + page;
      }
      return this.$el.load("" + page + " #content", function(responseBody) {
        var $responseBody, docTitle;
        $responseBody = $(responseBody);
        docTitle = $responseBody.filter('title').text();
        $('#article-title > .label').filter(':visible').text(docTitle.replace(/\ -\ .*/, ''));
        document.title = docTitle;
        callback();
        return container.refresh();
      });
    }
  });

  HomeView = Backbone.View.extend({
    el: '.top',
    reset: function() {

      /*
      $('#scroll-down').fadeOut 80, ->
        $(this).remove()
      $('#left-ribbon, #right-ribbon').transition {
        width: 0
      }, 250, ->
        $('#ribbon').remove()
       */
      $('.top .inner').transition({
        paddingTop: '0'
      }, 400);
      $('.wide-image').css('width', '100%');
      return $('.featured-works').css('visibility', 'visible').fadeTo(750, 1);
    },
    render: function() {
      var self;
      self = this;
      $w.one('scoll', self.reset());
      $('#scroll-down').on('click', function() {
        $('html,body').animate({
          scrollTop: "" + ($('header').height()) + "px"
        }, 400);
        return self.reset();
      });
      $('img[data-original]').removeAttr('src')._enableWebP().lazyload({
        effect: 'fadeIn',
        threshold: $w.height() * 0.25,
        skip_invisible: false,
        placeholder: '/img/transparent.gif'
      });
      return $('#logo').delay(200).transition({
        backgroundPosition: '0px 0px'
      }, 500);
    }
  });

  ProjectThumbnailView = Backbone.View.extend({
    el: 'img[data-original]',
    render: function() {
      return this.$el.removeAttr('src')._enableWebP().lazyload({
        effect: 'fadeIn',
        threshold: $w.height() * 0.15,
        placeholder: '/img/transparent.gif'
      });
    }
  });

  ProjectImageView = Backbone.View.extend({
    el: 'img[data-original]',
    render: function() {
      var $imageWrapper, _hasVideo;
      _hasVideo = $('.video-wrapper').length > 0;
      if (_hasVideo) {
        content.show();
      }
      $imageWrapper = $('.image-wrapper');
      return this.$el.removeAttr('src')._enableWebP().lazyload({
        effect: 'fadeIn',
        threshold: $w.height() * 0.5,
        placeholder: '/img/transparent.gif',
        effect_speed: {
          start: function() {
            var $this;
            $this = $(this);
            if (!_hasVideo && $this.is('.project-image:eq(0)')) {
              $this.finish();
              content.show();
            }
            return $imageWrapper.find(this).unwrap();
          }
        }
      });
    }
  });

  ShowMoreCommitsView = Backbone.View.extend({
    el: '#show-more-commits span',
    events: {
      'click': 'show'
    },
    show: function() {
      this.$el.remove();
      return $('#commits-rest').fadeIn();
    }
  });

}).call(this);
