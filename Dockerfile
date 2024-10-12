FROM public.ecr.aws/lambda/ruby:3.2

# システムの依存関係をインストール
RUN yum install -y gcc make

# 作業ディレクトリを設定
WORKDIR /var/task

# Gemfileとソースコードをコピー
COPY Gemfile Gemfile.lock ./
COPY lambda_function.rb ./

# Bundlerをインストールし、依存関係をインストール
RUN gem install bundler
RUN bundle install

# Lambda関数のハンドラを設定
CMD [ "lambda_function.lambda_handler" ]