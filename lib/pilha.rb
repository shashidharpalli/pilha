path = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)

require 'zlib'
require 'json'
require 'open-uri'
require 'forwardable'

require 'pilha/stack_overflow/statistics'
require 'pilha/stack_overflow/badge'
require 'pilha/stack_overflow/user'
require 'pilha/stack_overflow/answer'

module StackExchange

  module StackOverflow
    class Client
      URL = 'http://api.stackoverflow.com/'
      API_VERSION = '0.8'

      attr_reader :url
      attr_reader :api_version
      attr_reader :api_key

      class << self 
        def config &block
          options = OpenStruct.new
          yield options if block_given?

          client = Client.new(options)
          include_client(client, Badge, Statistics, User, Answer)
        end

        def include_client(client, *classes)
          classes.each do |klass|
            klass.instance_variable_set(:@client, client)
          end
        end
      end

      def initialize(options = OpenStruct.new)
        @url = normalize(options.url || URL )
        @api_version = options.api_version || API_VERSION
        @api_key = options.api_key 
      end

      def api_method_path(pattern, options = {})
        pattern << '/' unless pattern.end_with? '/'
        parts = pattern.split('/').select { |part| part =~ /^:/ }

        parts.each do |part|
          key = part.sub(':', '').intern
          pattern.sub!(part, options[key].to_s)
        end

        pattern
      end

      def api_method_url(method, options = {})
        options.merge! :api_key => api_key if api_key
        root_path + api_method_path(method, options) + query_string(options)
      end

      def get(url)
        stream = open(url) { |stream| Zlib::GzipReader.new(stream).read }
        JSON.parse stream
      end

      def root_path
        url + api_version
      end

      private
        def key?
          !!@api_key 
        end

        def query_string(options)
          params = options[:query]
          if params
            '?' + params.inject([]) do |arr, (key, value)|
              arr << "#{key}=#{value}"
            end.join('&')
          else
            ''
          end
        end

        def normalize(url)
          url.end_with?('/') ? url : url + '/'
        end
    end
  end
end