FROM ubuntu:20.04

LABEL maintainer="Asim Zeeshan asim@techbytes.pk"

# Install pre-requisites
#=================================================
RUN apt update
RUN apt install htop nano wget
RUN apt install -y ruby rubygems-integration bundler sqlite3 libsqlite3-dev build-essential curl unzip 
RUN apt install -y apache2 libapache2-mod-passenger

# Add tracksapp
#=================================================
RUN wget https://github.com/TracksApp/tracks/archive/v2.4.1.zip -O latest.zip /var/www/

RUN cd /var/www && unzip latest.zip && mv tracks-* tracks && chown -R www-data:www-data tracks

ADD ./database.yml /var/www/tracks/config/


# Setup Tracks
#=================================================
RUN cd /var/www/tracks && bundle install

# Initialize database
#=================================================
RUN cd /var/www/tracks && export RAILS_ENV=production && bundle exec rake db:migrate RAILS_ENV=production && bundle exec rake assets:precompile


# Replace the default sites-available
#=================================================
COPY ./000-default.conf /etc/apache2/sites-available/000-default.conf


# Add dockerize startup script
#=================================================
RUN apt install -y wget
RUN wget https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz
RUN tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v0.6.1.tar.gz
RUN chmod +x /usr/local/bin/dockerize
RUN cd /var/www/ && chown -R www-data:www-data tracks

VOLUME ["/var/www"]

EXPOSE 80

CMD "dockerize" "-stdout=/var/log/apache2/access.log", "-stdout=/var/www/tracks/log/production.log", "-stderr=/var/log/apache2/error.log" "/apache2-foreground"