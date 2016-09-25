defmodule Ku.Mixfile do
  use Mix.Project

  def project do
    [app: :ku,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :gen_stage]]
  end

  defp deps do
    [
      {:gen_stage, "~> 0.4"},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:excheck, "~> 0.5", only: :test},
      {:triq, github: "triqng/triq", only: :test},
    ]
  end
end
