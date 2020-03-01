FROM "elixir:1.10.1-alpine"

WORKDIR /code/

RUN apk add postgresql
RUN mix local.hex --force && mix local.rebar --force

COPY ["mix.lock", "mix.exs", "/code/"]

RUN mix deps.get

ADD . /code/

RUN mix compile

ENTRYPOINT "/bin/sh"

# mix ecto.create
# mix ecto.migrate
