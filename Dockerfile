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

# コピーする順序を変更し、必要なファイルのみをコピー
COPY package.json yarn.lock ./
RUN yarn install

COPY Gemfile Gemfile.lock ./
RUN bundle lock --add-platform x86_64-linux
RUN bundle install

# アプリケーションコードをコピー（bin ディレクトリを除外）
COPY app config db lib public vendor config.ru Rakefile ./
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Start the main process.
CMD ["rails", "server", "-b", "0.0.0.0"]
