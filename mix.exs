defmodule PaperTrail.Mixfile do
  use Mix.Project

  @source_url "https://github.com/izelnakri/paper_trail"
  @version "1.0.0"

  def project do
    [
      app: :paper_trail,
      version: @version,
      elixir: "~> 1.11",
      description: description(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      applications: [:logger, :ecto, :ecto_sql, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:ecto, ">= 3.9.2"},
      {:ecto_sql, ">= 3.9.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, ">= 1.4.0", only: [:dev, :test]},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]}
    ]
  end

  defp description do
    """
    Track and record all the changes in your database. Revert back to anytime
    in history.
    """
  end

  defp package do
    [
      name: :paper_trail,
      files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
      maintainers: ["Izel Nakri"],
      licenses: ["MIT License"],
      links: %{
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
