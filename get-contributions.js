'use strict';

var fs = require('fs');

var async = require('async');
var github = require('octonode');
var readYaml = require('read-yaml');

var ACCESS_TOKEN = '';
try {
  ACCESS_TOKEN = fs.readFileSync('gh-access-token.txt', 'utf8').trim();
} catch (e) {
  console.warn('Create a plain text file "gh-access-token.txt" which contains your Github access token.');
  process.exit(1);
}

var client = github.client(ACCESS_TOKEN);

readYaml('jade/data/contributions.yaml', function(err, data) {
  if (err) {
    throw err;
  }

  var keys = Object.keys(data);

  async.each(keys, function(key, eachNext) {
    var category = data[key];

    var result = [];
    async.eachSeries(category, function(val, seriesNext) {
      var requestUrl = '/repos/' + val.replace('/pull/', '/pulls/');
      client.get(requestUrl, {}, function(err, status, body) {
        if (err) {
          console.warn('Error requesting ' + requestUrl + ':' + err);
          seriesNext();
          return;
        }
        console.log('✔ GET ' + requestUrl);
        result.push(body);
        seriesNext();
      });
    }, function(err) {
      if (err) {
        throw err;
      }

      fs.writeFileSync(
        'tmp/all/commits_' + key + '_raw.json',
        JSON.stringify(result, null, 2)
      );

      var filteredResult = result.map(function(commit) {
        var item = {
          html_url: commit.html_url,
          title: commit.title,
          state: commit.state,
          created_at: commit.created_at
        };

        var _repo = _item.url
          .replace('https://github.com/', '')
          .split('/');

        item.repo_owner = _repo[0];
        item.repo_name = _repo[1];

        if (commit.issue_url) {
          item.type = 'pull';
        } else {
          item.type = 'issue';
        }

        return item;
      });
      fs.writeFileSync(
        'tmp/commits_' + key + '.json',
        JSON.stringify(filteredResult, null, 2)
      );
      eachNext();
    });
  });
});
