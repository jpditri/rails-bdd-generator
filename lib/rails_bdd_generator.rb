require_relative 'rails_bdd_generator/version'
require_relative 'rails_bdd_generator/generator'

module RailsBddGenerator
  class Error < StandardError; end

  def self.generate(specification, output_path: nil)
    Generator.new(specification, output_path: output_path).generate!
  end
end