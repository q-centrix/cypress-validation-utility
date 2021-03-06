FROM rails:4.2.5

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES 1

ADD Gemfile /rails/cypress-validation-utility/Gemfile
ADD Gemfile.lock /rails/cypress-validation-utility/Gemfile.lock

WORKDIR /rails/cypress-validation-utility

RUN bundle install --without development test

ADD . /rails/cypress-validation-utility

RUN chmod 755 /rails/cypress-validation-utility/rails-entrypoint.sh

RUN mkdir log/

RUN bundle exec rake assets:precompile

EXPOSE 3000
