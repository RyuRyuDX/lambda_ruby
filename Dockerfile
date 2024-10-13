FROM ruby:3.2.2

# Install node.js
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs

# Install yarn
RUN npm install -g yarn

# Install packages
RUN apt-get update -qq && \
    apt-get install -y default-mysql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /kinkyu_bot
COPY Gemfile /kinkyu_bot/Gemfile
COPY Gemfile.lock /kinkyu_bot/Gemfile.lock

# Add this line to update Gemfile.lock with the current platform
RUN bundle lock --add-platform x86_64-linux

RUN bundle install
COPY . /kinkyu_bot

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Start the main process.
CMD ["rails", "server", "-b", "0.0.0.0"]
