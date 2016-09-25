defmodule SubscriberTest do
  use ExUnit.Case
  use ExCheck
  alias Ki.Subscriber

  @chars [?_, ?-, ?.] ++ Enum.to_list(?0..?9) ++ Enum.to_list(?a..?z) ++ Enum.to_list(?A..?Z)

  describe "Pattern compilation" do
    property "plain pattern" do
      compiled = Subscriber.compile_pattern("abc")
      pattern = ~r{^abc$}
      assert Regex.match?(compiled, "abc") == Regex.match?(pattern, "abc")
      assert Regex.match?(compiled, "bc") == Regex.match?(pattern, "bc")
      for_all s in list(oneof(@chars)) do
        str = List.to_string(s)
        Regex.match?(compiled, str) == Regex.match?(pattern, str)
      end
    end

    property "alternatives pattern" do
      compiled = Subscriber.compile_pattern("ab{c,d,e,fg}")
      pattern = ~r{^ab(c|d|e|fg)$}
      assert Regex.match?(compiled, "abfg") == Regex.match?(pattern, "abfg")
      assert Regex.match?(compiled, "bdsc") == Regex.match?(pattern, "bdsc")
      for_all s in list(oneof(@chars)) do
        str = List.to_string(s)
        Regex.match?(compiled, str) == Regex.match?(pattern, str)
      end
    end

    property "one-character catchall" do
      compiled = Subscriber.compile_pattern("ab?d")
      pattern = ~r{^ab[A-Za-z_\.\d]d$}
      assert Regex.match?(compiled, "abxd") == Regex.match?(pattern, "abxd")
      assert Regex.match?(compiled, "ab.d") == Regex.match?(pattern, "ab.d")
      assert Regex.match?(compiled, "bdsc.wrong_pattern") == Regex.match?(pattern, "bdsc.wrong_pattern")
      for_all s in list(oneof(@chars)) do
        str = List.to_string(s)
        Regex.match?(compiled, str) == Regex.match?(pattern, str)
      end
    end

    property "catchall" do
      compiled = Subscriber.compile_pattern("ab*d")
      pattern = ~r{^ab[A-Za-z_\.\d]*d$}
      assert Regex.match?(compiled, "abfff_da.gd") == Regex.match?(pattern, "abfff_da.gd")
      assert Regex.match?(compiled, "bdscddd") == Regex.match?(pattern, "bdscddd")
      for_all s in list(oneof(@chars)) do
        str = List.to_string(s)
        Regex.match?(compiled, str) == Regex.match?(pattern, str)
      end
    end
  end
end
