require 'spec_helper'
require 'rack/test'

require 'lamprey'

describe 'Lamprey with Memento' do
  include ::Rack::Test::Methods
  let(:app) { RDF::Lamprey }

  before { configure_memento! }

  ##
  # Configures memento to run within Lamprey
  def configure_memento!
  end
end
