require 'rack'

module Rack
  ##
  # Implements Memento as middleware
  #
  # @see https://mementoweb.org/guide/rfc/
  class Memento
    ORIGINAL_REL = 'original'.freeze
    TIMEGATE_REL = 'timegate'.freeze
    TIMEMAP_REL  = 'timemap'.freeze
    MEMENTO_REL  = 'memento'.freeze

    ##
    # @param app [#call]
    def initialize(app)
      @app = app
    end

    ##
    # @param env [Array]  a rack env array
    # @return [Array]  a rack env array
    def call(env)
      status, headers, response = @app.call(env)
      headers['Link'] = add_timegate_link(headers, response)
      [status, headers, response]
    end

    private

    ##
    # Adds timegate link to headers
    #
    # @return [String] the new `Link:` headers with the timegate added
    def add_timegate_link(headers, response)
      return headers unless response.respond_to?(:timegate)

      ([headers['Link']] << link_header(response.timegate, TIMEGATE_REL))
        .compact.join(',')
    end

    ##
    # @param target [String]
    # @param rel    [String]
    def link_header(target, rel)
      "<#{target}>;rel=#{rel}"
    end
  end
end
