rich_citations
==============

[![master Build Status](https://travis-ci.org/ploslabs/rich_citations.svg?branch=master)](https://travis-ci.org/ploslabs/rich_citations)
[![feature/api_v0 Build Status](https://travis-ci.org/ploslabs/rich_citations.svg?branch=feature%2Fapi_v0)](https://travis-ci.org/ploslabs/rich_citations)

Installing
----------

```
$ cd rich_citations
$ bundle install
$ cp config/database.example.yml config/database.yml
$ bundle exec rake db:migrate
$ bundle exec rails server
```

Visit <http://localhost:3000/> to see the Rich Citations API.
