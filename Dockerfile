FROM "elixir:1.10.1-alpine"

ARG MIX_ENV=dev
ENV MIX_ENV=$MIX_ENV

WORKDIR /code/

RUN echo "y" | mix local.hex --if-missing && echo "y" | mix local.rebar --if-missing

ADD ["mix.lock", "mix.exs", "/code/"]

RUN mix deps.get && MIX_ENV=test mix deps.compile && \
  MIX_ENV=$MIX_ENV mix deps.compile

ADD ["config", "lib", "priv", "/code/"]

RUN MIX_ENV=$MIX_ENV mix compile

ADD ["test", "/code/"]

RUN MIX_ENV=test mix compile && MIX_ENV=$MIX_ENV mix compile

ADD . /code/

RUN MIX_ENV=test mix compile && MIX_ENV=$MIX_ENV mix compile

CMD ["/bin/sh"]

# mix ecto.create
# mix ecto.migrate
