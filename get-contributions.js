'use strict';

var async = require('async');
var grunt = require('grunt');
var github = require('octonode');

var data = grunt.file.readYAML('jade/data/contributions.yaml');

var ACCESS_TOKEN = grunt.file.read('gh-access-token.txt').trim();
var client = github.client(ACCESS_TOKEN);

var keys = Object.keys(data);

async.each(keys, function(key, eachNext) {
  var category = data[key];
  
  var result = [];
  async.eachSeries(category, function(val, seriesNext) {
    var _url = '/repos/' + val.replace('/pull/', '/pulls/');
    console.log('Requesting... ' + _url);
    client.get(_url, {}, function(err, status, body) {
      result.push(body);
      seriesNext();
    });
  }, function(err) {
    if (err) throw err;
    grunt.file.write(
      'tmp/all/commits_' + key + '_raw.json',
      JSON.stringify(result, null, 2)
    );
    
    var filteredResult = result.map(function(commit) {
      var _item = {
        url: commit.html_url,
        title: commit.title,
        state: commit.state,
        date: commit.created_at
      };
    
      var _repo = commit.url
        .replace('https://api.github.com/repos/', '')
        .split('/');
    
      _item.repo_owner = _repo[0];
      _item.repo_name = _repo[1];
    
      if (commit.issue_url) {
        _item.type = 'pull';
      } else {
        _item.type = 'issue';
      }
    
      return _item;
    });
    grunt.file.write(
      'tmp/commits_' + key + '.json',
      JSON.stringify(filteredResult, null, 2)
    );
    eachNext();
  });
});
