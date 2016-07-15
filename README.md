# PaperTrail

```mix papertrail.install```

PaperTrail.create/1, PaperTrail.update/1, PaperTrail.destroy/1

every operation has to go through the changeset function

PaperTrail.get_version\2, PaperTrail.get_version\1 PaperTrail.get_versions\2, PaperTrail.get_versions\1

I will write some tests for this library.

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add paper_trail to your list of dependencies in `mix.exs`:

        def deps do
          [{:paper_trail, "~> 0.0.1"}]
        end

  2. Ensure paper_trail is started before your application:

        def application do
          [applications: [:paper_trail]]
        end
