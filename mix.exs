defmodule PaperTrail.Mixfile do
  use Mix.Project

  def project do
    [app: :paper_trail,
     version: "0.0.8",
     elixir: "~> 1.3",
     description: description,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    []
  end

  defp deps do
    [
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 2.0.2"},
      {:poison, "2.1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
     """
     Track and record all the changes in your database. Revert back to anytime in history.
     """
  end

  defp package do
    [
      name: :paper_trail,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Izel Nakri"],
      licenses: ["MIT License"],
      links: %{
        "GitHub" => "https://github.com/izelnakri/paper_trail",
        "Docs" => "https://hexdocs.pm/paper_trail/PaperTrail.html"
      }
    ]
  end
end
