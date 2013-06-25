defmodule Kozel.Mixfile do
  use Mix.Project

  def project do
    project_options = []
    [ app: :elkozel,
      version: "0.0.1",
      deps: deps,
      elixirc_options: project_options ++ options(Mix.env) ]
  end

  def application do
    [ registered: [ :kozel_sup,
                    :kozel_table_sup,
                    :kozel_bot_sup ],
      mod: {Kozel, []},
      applications: [ :exlager,
                      :ranch,
                      :cowboy,
                      :gproc ] ++ env_applications(Mix.env) ]
  end

  def env_applications(:dev), do: [:exreloader]
  def env_applications(_), do: []

  defp deps do
    [ {:genx, "0.1", git: "https://github.com/yrashk/genx.git"},
      {:exlager, git: "https://github.com/khia/exlager.git"},
          {:goldrush, git: "https://github.com/DeadZen/goldrush.git", tag: "879c69874a"},
      {:exreloader, git: "https://github.com/couchemar/exreloader.git"},
      {:cowboy, git: "https://github.com/extend/cowboy.git", tag: "0.8.6"},
          {:ranch, git: "https://github.com/extend/ranch.git", tag: "0.8.4"},
      {:mimetypes, git: "https://github.com/spawngrid/mimetypes.git"},
      {:jsonx, git: "https://github.com/iskra/jsonx.git"},
      {:gproc, git: "https://github.com/uwiger/gproc.git"},
      {:base16, git: "https://github.com/goj/base16.git"} ]
 end

  defp options(env) when env in [:dev, :test] do
    [ exlager_level: :debug ]
  end
  defp options(_), do: []
end
