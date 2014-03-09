require 'http/version'
require 'openssl'
require 'socket'

module HTTP
  class Options
    # How to format the response [:object, :body, :parse_body]
    attr_reader :response

    # HTTP headers to include in the request
    attr_reader :headers

    # Query string params to add to the url
    attr_reader :params

    # Form data to embed in the request
    attr_reader :form

    # Explicit request body of the request
    attr_reader :body

    # HTTP proxy to route request
    attr_reader :proxy

    # Socket classes
    attr_reader :socket_class, :ssl_socket_class

    # SSL context
    attr_reader :ssl_context

    # Follow redirects
    attr_reader :follow

    @default_socket_class     = TCPSocket
    @default_ssl_socket_class = OpenSSL::SSL::SSLSocket

    class << self
      attr_accessor :default_socket_class, :default_ssl_socket_class

      def new(options = {})
        return options if options.is_a?(self)
        super
      end
    end

    def initialize(options = {})
      @response  = options[:response]  || :auto
      @proxy     = options[:proxy]     || {}
      @body      = options[:body]
      @params    = options[:params]
      @form      = options[:form]
      @follow    = options[:follow]

      @socket_class     = options[:socket_class]     || self.class.default_socket_class
      @ssl_socket_class = options[:ssl_socket_class] || self.class.default_ssl_socket_class
      @ssl_context      = options[:ssl_context]

      @headers = HTTP::Headers.from_hash(options[:headers] || {})
      @headers['User-Agent'] ||= "RubyHTTPGem/#{HTTP::VERSION}"
    end

    %w{ headers proxy params form body follow }.each do |name|
      class_eval <<-RUBY, __FILE__, __LINE__
      def with_#{name}(value)
        merge :#{name} => value
      end
      RUBY
    end

    def [](option)
      send(option) rescue nil
    end

    def merge(other)
      h1, h2 = to_hash, other.to_hash

      merged = h1.merge(h2) do |k, v1, v2|
        (:headers == k) ?  v1.merge(v2) : v2
      end

      self.class.new(merged)
    end

    def to_hash
      # FIXME: hardcoding these fields blows! We should have a declarative
      # way of specifying all the options fields, and ensure they *all*
      # get serialized here, rather than manually having to add them each time
      {
        :response         => response,
        :headers          => headers,
        :proxy            => proxy,
        :params           => params,
        :form             => form,
        :body             => body,
        :follow           => follow,
        :socket_class     => socket_class,
        :ssl_socket_class => ssl_socket_class,
        :ssl_context      => ssl_context
     }
    end

  private

    def argument_error!(message)
      fail(Error, message, caller[1..-1])
    end
  end
end
