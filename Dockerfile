FROM ruby:3.3.0

# Install dependencies required for app and tests
RUN apt-get update -q && apt-get install -y --no-install-recommends \
  build-essential \
  libxml++2.6-dev \
  libraptor2-0 \
  libxslt1-dev \
  locales \
  software-properties-common \
  cron \
  python3-pip \
  python3-extruct && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  pip3 install --no-cache-dir extruct

# Set locale environment variables
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:UTF-8" LC_ALL="C.UTF-8"

# Install specific bundler version
RUN gem install bundler:2.3.12

# Set working directory
WORKDIR /server

# Copy Gemfile and install dependencies (cached layer)
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code
COPY . .

# Expose port for app
EXPOSE 4567

# Entrypoint for app startup, allows override for tests
ENTRYPOINT ["sh", "/server/entrypoint.sh"]

# Default command for running tests
CMD ["bundle", "exec", "rspec"]