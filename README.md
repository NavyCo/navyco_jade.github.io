# Shinnosuke Watanabe's Website

[![endorse](https://api.coderwall.com/shinnn/endorsecount.png)](https://coderwall.com/shinnn)

[![devDependency Status](https://david-dm.org/shinnn/shinnn.github.io/dev-status.png)](https://david-dm.org/shinnn/shinnn.github.io#info=devDependencies)

## Features

* Fast browsing and clean URL with [pjax](https://github.com/defunkt/jquery-pjax/)
* Responsive web design
* Flexible template system with Jade and Frontmatter

## Development

Make sure you have installed [Grunt](http://gruntjs.com/), [Sass](http://sass-lang.com/) and [Compass](http://compass-style.org/).

### Building the site

At first, run `npm install` command in the project's root directory to install all dependencies described in [`package.json`](./package.json).

To build the site and run it in a server, run `grunt` command. Then the [Grunt tasks](./Gruntfile.coffee) generate the `master` directory which contains compiled files, and you can view the site at `http://localhost:8000`.

### Managing client-side JavaScript libraries

This project uses [bower](http://bower.io/) to manage client-side libraries, and uses [grunt-bower-task](https://github.com/yatskevich/grunt-bower-task) to override directory structure of the bower components.

Basically, installed bower components are minified and concatenated into single script file. However, if you describe `exportsOverride` in `bower.json` to specify export destination of the components, you can use them in other ways:

* The files exported to `public` is not concatenated and directly copied to the `master` directory.

* The files exported to `ie` is minified and concatenated into `vendor.ie.js` and it will be loaded in `head` tag.

## Deployment

You can easily host the site on [Github Pages](http://pages.github.com/) in the following way:

1. Run `grunt deploy` command.
2. Enter the commit message.
3. Enter username and password of your Github account.

If successful, all files in the `master` directory will be copied to the `master` branch.

## License

Copyright (c) 2013 Shinnosuke Watanabe All rights reserved.

Unless otherwise stated, all source code in this repository are licensed under the [MIT license](http://opensource.org/licenses/mit-license.php).
