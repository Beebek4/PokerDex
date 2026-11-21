# Build and run on the same Elixir/OTP release line so Rustler's NIF and the
# BEAM runtime use compatible system libraries.
ARG ELIXIR_VERSION=1.20.5
ARG OTP_VERSION=29

FROM elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION} AS builder

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs -o /tmp/rustup-init.sh \
    && sh /tmp/rustup-init.sh -y --profile minimal --default-toolchain 1.100.0 \
    && rm /tmp/rustup-init.sh

ENV PATH="/root/.cargo/bin:${PATH}"
ENV MIX_ENV="prod"

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only "$MIX_ENV"
RUN mkdir config
COPY config/config.exs config/prod.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY native native
COPY assets assets

RUN mix assets.deploy
RUN mix compile

COPY config/runtime.exs config/
COPY rel rel
RUN chmod +x rel/overlays/bin/server rel/overlays/bin/migrate rel/overlays/bin/render-start
RUN mix release

FROM elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION}-slim AS app

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates libstdc++6 openssl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN chown nobody /app

ENV MIX_ENV="prod"
ENV PORT="10000"

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/zoonk ./

USER nobody
EXPOSE 10000
CMD ["/app/bin/render-start"]
