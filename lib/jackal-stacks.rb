require 'sfn'
require 'jackal'

module Jackal
  module Stacks
    autoload :Builder, 'jackal-stacks/builder'
    autoload :Wrecker, 'jackal-stacks/wrecker'
  end
end

require 'jackal-stacks/version'
