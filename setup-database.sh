#!/bin/sh
set -e

# Prepare Dialyzer if the project has Dialyxer set up
# if mix help dialyzer >/dev/null 2>&1
# then
#   echo "\nFound Dialyxer: Setting up PLT..."
#   mix do deps.compile, dialyzer --plt
# else
#   echo "\nNo Dialyxer config: Skipping setup..."
# fi

# Wait for Postgres to become available.
until psql -h $PG_HOST -U "$POSTGRES_USER" -c '\q' 2>/dev/null; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

echo "\nPostgres is available: continuing with database setup..."

mix ecto.create
# mix ecto.migrate

# echo "\nPostgres migrations finished..."
