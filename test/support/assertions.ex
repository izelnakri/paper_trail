defmodule PaperTrailTest.Assertions do
  def assert_map_keys(map, keys) do
    for key <- keys do
      if not Map.has_key?(map, key) do
        ExUnit.Assertions.flunk("Map is missing key: #{key}")
      end
    end
  end
end
