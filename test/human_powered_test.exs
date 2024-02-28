defmodule HumanPoweredTest do
  use ExUnit.Case
  doctest HumanPowered

  test "greets the world" do
    assert HumanPowered.hello() == :world
  end
end
