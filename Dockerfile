FROM ruby:3.2.2

# Instala dependências do sistema necessárias para compilar as gems (incluindo pg e bigdecimal)
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    postgresql-client

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia os arquivos de dependências
COPY Gemfile Gemfile.lock ./

# Instala as gems
RUN bundle install

# Copia o resto do código da aplicação
COPY . .

# Limpa o PID do servidor caso o container tenha caído de forma abrupta
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails server -b '0.0.0.0'"]