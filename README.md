# [Shinnosuke Watanabe's Website](http://shinnn.github.io)

[![devDependency Status](https://david-dm.org/shinnn/shinnn.github.io/dev-status.png)](https://david-dm.org/shinnn/shinnn.github.io#info=devDependencies)
[![Built with Grunt](https://cdn.gruntjs.com/builtwith.png)](http://gruntjs.com/)

## Features

* Fast browsing and clean URL by using [pjax](https://github.com/defunkt/jquery-pjax/)
* [Responsive web design](http://en.wikipedia.org/wiki/Responsive_web_design)
* Flexible template system with [Jade](http://jade-lang.com/) and Frontmatter inspired by [Jekyll](http://jekyllrb.com/)
  * Based on this project, I'm developing a Yeoman generator *[generator-jade-frontmatter](https://github.com/shinnn/generator-jade-frontmatter)*.

## Development

Make sure you have installed latest [Grunt](http://gruntjs.com/), [Sass](http://sass-lang.com/) and [Compass](http://compass-style.org/).

### Building the site

At first, run `npm install` command in the project's root directory to install all dependencies described in [`package.json`](./package.json).

To build the site and run it in a server, run `grunt` command. Then the [Grunt tasks](./Gruntfile.coffee) generate the `master` directory which contains compiled files, and you can view the site at `http://localhost:8000`.

### Managing client-side JavaScript libraries

This project uses [Bower](http://bower.io/) to manage client-side libraries, and uses [grunt-bower-task](https://github.com/yatskevich/grunt-bower-task) to override directory structure of the bower components.

Basically, installed bower components are minified and concatenated into single script file. However, if you describe `exportsOverride` in `bower.json` to specify export destination of the components, you can use them in other ways:

* The files exported to `public` are not concatenated and directly copied to the `master` directory.

* The files exported to `ie` are minified and concatenated into `vendor.ie.js` and they will be loaded in `head` tag.

## Deployment

You can easily host the site on [Github Pages](http://pages.github.com/) in the following way:

1. Run `grunt deploy` command.
2. Enter the commit message.
3. Enter username and password of your Github account.

If successful, all files in the `master` directory will be copied to the [`master` branch](https://github.com/shinnn/shinnn.github.io/tree/master).

## License

Copyright (c) 2013 [Shinnosuke Watanabe](https://github.com/shinnn) All rights reserved.

Unless otherwise stated, all source code in this repository is licensed under the [MIT license](http://opensource.org/licenses/mit-license.php).

[![endorse](https://api.coderwall.com/shinnn/endorsecount.png)](https://coderwall.com/shinnn)
