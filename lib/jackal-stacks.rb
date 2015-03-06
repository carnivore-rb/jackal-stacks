require 'sfn'
require 'jackal'

module Jackal
  module Stacks
    autoload :Builder, 'jackal-stacks/builder'
    autoload :StackCommon, 'jackal-stacks/stack_common'
    autoload :Wrecker, 'jackal-stacks/wrecker'
  end
end

require 'jackal-stacks/formatter'
require 'jackal-stacks/version'
