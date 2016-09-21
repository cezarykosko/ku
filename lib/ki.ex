defmodule Ki do
  def start do
    :application.ensure_all_started(:ki)
  end
end
