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

Jackal.service(
  :stacks,
  :description => 'Manage stacks',
  :configuration => {
    :orchestration__bucket_name => {
      :description => 'Name of remote bucket used for infrastructure storage'
    },
    :orchestration__api__provider => {
      :description => 'Remote orchestration provider',
      :type => :string
    },
    :orchestration__api__credentials => {
      :description => 'Credentials for orchestration API access',
      :type => :hash
    },
    :default_template_path => {
      :description => 'Relative path from repository root to default template'
    },
    :parameter_overrides => {
      :description => 'Stack parameter value overrides',
      :type => :hash
    },
    :init__chef__validator => {
      :description => 'Auto generate Chef validator PEM',
      :type => :boolean
    },
    :init__chef__encrypted_secret => {
      :description => 'Auto generate Chef encrypted data bag secret',
      :type => :boolean
    },
    :init__stable => {
      :description => 'Auto create stable repository asset',
      :type => :boolean
    }
  }
)
