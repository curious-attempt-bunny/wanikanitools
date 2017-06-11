# dokku-rails-omniauth-bootstrap-react

# Installation

## Create your app

On your Dokku server:

    dokku app:create dokku-rails-omniauth-bootstrap-react
    sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git
    dokku postgres:create dokku-rails-omniauth-bootstrap-react-database
    dokku postgres:link dokku-rails-omniauth-bootstrap-react-database dokku-rails-omniauth-bootstrap-react

## Push to Dokku

On you local computer:

    git clone git@github.com:curious-attempt-bunny/dokku-rails-omniauth-bootstrap-react.git
    cd dokku-rails-omniauth-bootstrap-react
    git remote add dokku dokku@yourhostontheinternet:dokku-rails-omniauth-bootstrap-react
    git push dokku master

## Add HTTPS to your app

On your Dokku server:

    sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
    dokku config:set --no-restart dokku-rails-omniauth-bootstrap-react DOKKU_LETSENCRYPT_EMAIL=yourregistrationemail.com
    dokku letsencrypt:cron-job --add    

## Add Google OAuth2 config to your add

On your Dokku server:
    
    dokku config:set dokku-rails-omniauth-bootstrap-react GOOGLE_CLIENT_ID=xxx GOOGLE_CLIENT_SECRET=yyy    

# Running locally

    bundle install
    bundle exec rake db:create db:migrate
    GOOGLE_CLIENT_ID=xxx GOOGLE_CLIENT_SECRET=yyy bundle exec rails server
    open http://localhost:3000

## Add New Relic monitoring

    dokku config:set dokku-rails-omniauth-bootstrap-react NEW_RELIC_LICENSE_KEY=xxx NEW_RELIC_APP_NAME=yyy

# Resources

This was pieced together from:

* http://dokku.viewdocs.io/dokku/deployment/application-deployment/
* https://richonrails.com/articles/google-authentication-in-ruby-on-rails
* http://www.rubyfleebie.com/how-to-use-dokku-on-digitalocean-and-deploy-rails-applications-like-a-pro/
* https://hackhands.com/react-rails-tutorial/
* https://github.com/reactjs/react-rails
* https://github.com/seyhunak/twitter-bootstrap-rails
