# Multi-stage Dockerfile for DXNN Analyzer Web Interface

# Stage 1: Build Erlang Analyzer
FROM erlang:26-alpine AS erlang-builder

WORKDIR /app

# Install rebar3
RUN apk add --no-cache git && \
    wget https://s3.amazonaws.com/rebar3/rebar3 && \
    chmod +x rebar3 && \
    mv rebar3 /usr/local/bin/

# Copy analyzer source
COPY dxnn_analyzer /app/dxnn_analyzer

# Compile Erlang analyzer
WORKDIR /app/dxnn_analyzer
RUN rebar3 compile

# Stage 2: Build Elixir Web Interface
FROM elixir:1.16-alpine AS elixir-builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    nodejs \
    npm

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy Elixir project files
COPY dxnn_analyzer_web/mix.exs dxnn_analyzer_web/mix.lock ./
RUN mix deps.get --only prod

# Copy application source
COPY dxnn_analyzer_web/lib ./lib
COPY dxnn_analyzer_web/config ./config
COPY dxnn_analyzer_web/assets ./assets

# Copy compiled Erlang analyzer from previous stage
COPY --from=erlang-builder /app/dxnn_analyzer/_build/default/lib /app/erlang_libs

# Install Node dependencies and build assets
WORKDIR /app/assets
RUN npm install && npm run deploy

# Compile Elixir application
WORKDIR /app
ENV MIX_ENV=prod
RUN mix compile

# Stage 3: Runtime
FROM elixir:1.16-alpine AS runtime

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    libstdc++

# Create non-root user
RUN addgroup -g 1000 dxnn && \
    adduser -D -u 1000 -G dxnn dxnn

# Copy compiled application
COPY --from=elixir-builder --chown=dxnn:dxnn /app/_build/prod /app/_build/prod
COPY --from=elixir-builder --chown=dxnn:dxnn /app/deps /app/deps
COPY --from=elixir-builder --chown=dxnn:dxnn /app/priv /app/priv
COPY --from=elixir-builder --chown=dxnn:dxnn /app/erlang_libs /app/erlang_libs

# Copy configuration
COPY --chown=dxnn:dxnn dxnn_analyzer_web/config ./config
COPY --chown=dxnn:dxnn dxnn_analyzer_web/lib ./lib
COPY --chown=dxnn:dxnn dxnn_analyzer_web/mix.exs ./

# Create directory for Mnesia data
RUN mkdir -p /app/data && chown -R dxnn:dxnn /app/data

USER dxnn

# Set environment
ENV MIX_ENV=prod
ENV PORT=4000
ENV ERLANG_LIBS=/app/erlang_libs

EXPOSE 4000

CMD ["mix", "phx.server"]
