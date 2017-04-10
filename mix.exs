defmodule Histogrammar.Mixfile do
  use Mix.Project

  def project do
    [app: :histogrammar,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     consolidate_protocols: true,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:quixir, "~> 0.9", only: :test},
     {:ex_doc,   "~> 0.14", only: :dev, runtime: false},
     {:dialyxir, "~> 0.5",  only: :dev, runtime: false},
     {:poison, "~> 3.0"},
     {:exprof, "~> 0.2.0"},
     {:benchee, "~> 0.6", only: :dev}]
  end
end
