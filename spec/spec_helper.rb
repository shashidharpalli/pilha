path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)

require 'rubygems'
require 'fakeweb'
require 'stack_exchange'
require 'spec'
require 'pp'

include StackExchange
FIXTURES_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))
ROOT_URL = [StackOverflow::Client::URL.chomp('/'), StackOverflow::Client::API_VERSION].join '/'
FakeWeb.allow_net_connect = false

def register(options)
  url = api_method_url(options[:url])
  FakeWeb.register_uri(:get, url, :body => read_fixture(options[:body] + '.json'))
end

def read_fixture(fixture)
  File.read(File.join(FIXTURES_PATH, fixture))
end

def api_method_url(method)
  ROOT_URL + '/' + method
end

['stats', 'badges' ].each do |method|
  register :url => method + '/', :body => method
end

register(:url => 'badges/9/', :body => 'badges_by_id')
register(:url => 'badges/9/?pagesize=50', :body => 'badges_by_id_page2')