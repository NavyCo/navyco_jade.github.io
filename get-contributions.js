'use strict';

var async = require('async');
var grunt = require('grunt');
var github = require('octonode');

var data = grunt.file.readYAML('jade/data/contributions.yaml');

var ACCESS_TOKEN = '';
try {
  ACCESS_TOKEN = grunt.file.read('gh-access-token.txt').trim();
} catch (e) {
  console.error('Create a plain text file "gh-access-token.txt" which contains your Github access token.');
  process.exit();
}

var client = github.client(ACCESS_TOKEN);

var keys = Object.keys(data);

async.each(keys, function(key, eachNext) {
  var category = data[key];
  
  var result = [];
  async.eachSeries(category, function(val, seriesNext) {
    var requestUrl = '/repos/' + val.replace('/pull/', '/pulls/');
    client.get(requestUrl, {}, function(err, status, body) {
      if (err) {
        console.error('Error requesting ' + requestUrl + ':' + err);
      } else {
        console.log('✔ GET ' + requestUrl);
      }
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

      var _repo = _item.url
        .replace('https://github.com/', '')
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
