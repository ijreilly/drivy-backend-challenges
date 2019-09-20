require 'minitest/autorun'
require 'json'

class TestDrivy < Minitest::Test
  (1..5).each do |level|
    define_method("test_output_level#{level}") do
      check_level(level)
    end
  end

  def check_level(level)
    Dir.chdir "level#{level}" do
      expected = JSON.load File.read "data/expected_output.json"
      result   = JSON.load File.read "data/output.json"
      assert_equal expected, result
    end
  end
end