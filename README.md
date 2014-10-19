rich_citations
==============

[![master Build Status](https://travis-ci.org/ploslabs/rich_citations.svg?branch=master)](https://travis-ci.org/ploslabs/rich_citations)
[![feature/api_v0 Build Status](https://travis-ci.org/ploslabs/rich_citations.svg?branch=feature%2Fapi_v0)](https://travis-ci.org/ploslabs/rich_citations)

Live version: http://alpha.richcitations.org/

Installing
----------
Requirements:
`Ruby 2.1.2`,`bundler`,`java`

```
$ cd rich_citations
$ bundle install
$ cp config/database.example.yml config/database.yml
$ bundle exec rake db:migrate
$ bundle exec rails server
```

Visit <http://localhost:3000/> to see the Rich Citations API.


 - [Ubuntu 14.04 Install Guide](https://github.com/ploslabs/rich_citations/wiki/Install-Guide)
