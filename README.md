# Wanikani Tools

Assorted tools built on top of the wanikani v2 API. So far:

* an API caching layer that rolls up responses,
* a leaches screensaver page

# Users

## Animated leaches display

Go to https://wanikanitools.curiousattemptbunny.com/.

## Set it as your screen saver

### Mac OSX

Follow the instructions at https://www.usethistip.com/add-website-screen-saver-mac-os-x.html.

# Developers

## Wanikani API cache

The following endpoints cache rolled-up responses from Wanikani (use HTTP GET and your v2 API key):

* https://wanikanitools.curiousattemptbunny.com/api/v2/user?api_key=XXX
* https://wanikanitools.curiousattemptbunny.com/api/v2/subjects?api_key=XXX
* https://wanikanitools.curiousattemptbunny.com/api/v2/assignments?api_key=XXX
* https://wanikanitools.curiousattemptbunny.com/api/v2/study_materials?api_key=XXX
* https://wanikanitools.curiousattemptbunny.com/api/v2/summary?api_key=XXX
* https://wanikanitools.curiousattemptbunny.com/api/v2/review_statistics?api_key=XXX

In addition a merged view of the review_statistics endpoint is available via:

* https://wanikanitools.curiousattemptbunny.com/review_data/merged?api_key=XXX

### Cache invalidation

The first page of each request will be made to Wanikani, and if the `date_updated_at` field has changed then the remaining pages will be queried for (and then cached). In other words, each query will result in 1 or more queries to Wanikani.

## Setup

See https://github.com/curious-attempt-bunny/dokku-rails-omniauth-bootstrap-react/blob/master/README.md.

    dokku config:set --no-restart wanikanitools WANIKANI_V2_API_KEY=XXX

## Running locally

    bundle install
    bundle exec rake db:create db:migrate
    WANIKANI_V2_API_KEY=XXX bundle exec rails server
    open http://localhost:3000
