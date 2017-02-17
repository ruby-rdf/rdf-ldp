require 'spec_helper'

require 'faraday'

require 'capybara_discoball'
require 'ldp_testsuite_wrapper'
require 'ldp_testsuite_wrapper/rspec'

require 'lamprey'

describe 'LDP Test Suite', integration: true do
  before(:all) do
    # use custom fork to work around https://github.com/w3c/ldp-testsuite/pull/227
    LdpTestsuiteWrapper.default_instance_options[:version] = '0.2.0-SNAPSHOT'

    LdpTestsuiteWrapper.default_instance_options[:url] = 
      'https://github.com/cbeer/ldp-testsuite/archive/master.zip'

    LdpTestsuiteWrapper.default_instance_options[:zip_root_directory] = 
      'ldp-testsuite-master'

    @server = Capybara::Discoball::Runner.new(RDF::Lamprey).boot

    @skipped_tests = [
      'testContainsRdfType',          # rdf:type is left to the client and/or implementer.
      'testTypeRdfSource',            # rdf:type is left to the client and/or implementer.
      'testRdfTypeLdpContainer',      # rdf:type is left to the client and/or implementer.
      'testPreferContainmentTriples', # Client hints are unimplemented.
      'testPreferMembershipTriples',  # Client hints are unimplemented.
      'testPutRequiresIfMatch',       # clients SHOULD use the HTTP If-Match header
      'testRestrictUriReUseSlug'      # https://github.com/w3c/ldp-testsuite/issues/225
    ]
  end

  describe 'Basic containers' do
    it_behaves_like 'ldp test suite' do
      let(:server_url) { @server }
      let(:test_suite_options) { { 'non-rdf' => true, basic: true } }
      let(:skipped_tests) { @skipped_tests }
    end
  end

  describe 'Direct containers' do
    it_behaves_like 'ldp test suite' do
      let(:server_url) { @server }
      let(:test_suite_options) { { 'non-rdf' => true, direct: true } }
      let(:skipped_tests) { @skipped_tests }
    end
  end

  describe 'Indirect containers' do
    it_behaves_like 'ldp test suite' do
      let(:server_url) { @server }
      let(:test_suite_options) { { 'non-rdf' => true, indirect: true } }
      let(:skipped_tests) { @skipped_tests }
    end
  end
end
