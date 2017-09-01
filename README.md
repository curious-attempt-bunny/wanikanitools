# Setup

See https://github.com/curious-attempt-bunny/dokku-rails-omniauth-bootstrap-react/blob/master/README.md.

    dokku config:set --no-restart wanikanitools WANIKANI_V2_API_KEY=XXX

# Running locally

    bundle install
    bundle exec rake db:create db:migrate
    WANIKANI_V2_API_KEY=XXX bundle exec rails server
    open http://localhost:3000
