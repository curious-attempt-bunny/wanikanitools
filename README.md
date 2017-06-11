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