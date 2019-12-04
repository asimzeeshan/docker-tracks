FROM ruby:stretch

LABEL maintainer="Asim Zeeshan asim@techbytes.pk"

# Install pre-requisites
#=================================================
RUN apt-get update && apt-get install -y apt-transport-https apt-utils

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update
RUN apt-get install -y htop nano wget
RUN apt-get install -y ruby rubygems-integration bundler sqlite3 libsqlite3-dev build-essential curl unzip zlib1g-dev 
RUN apt-get install -y --no-install-recommends yarn
RUN apt-get install -y apache2 libapache2-mod-passenger

# Add tracksapp
#=================================================
RUN wget https://github.com/TracksApp/tracks/archive/v2.4.1.zip -O /var/www/latest.zip

RUN cd /var/www/ && unzip latest.zip && mv tracks-2.4.1 tracks && chown -R www-data:www-data /var/www/tracks

COPY ./database.yml /var/www/tracks/config/
COPY ./site.yml /var/www/tracks/config/


# Setup Tracks
#=================================================
COPY Gemfile* /var/www/tracks/
RUN gem install bundler
RUN gem install RedCloth
RUN bundle config git.allow_insecure true
RUN cd /var/www/tracks && bundle install --jobs 4

# Initialize database
#=================================================
RUN cd /var/www/tracks && export RAILS_ENV=production && bundle exec rake db:migrate RAILS_ENV=production && bundle exec rake assets:precompile


# Replace the default sites-available
#=================================================
COPY ./000-default.conf /etc/apache2/sites-available/000-default.conf
RUN service apache2 restart


# Add dockerize startup script
#=================================================
RUN chown -R www-data:www-data /var/www/tracks

VOLUME ["/var/www"]

EXPOSE 80

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]