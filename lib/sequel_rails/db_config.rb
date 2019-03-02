require 'active_support/hash_with_indifferent_access.rb'
require 'uri'

module SequelRails
  class DbConfig < ActiveSupport::HashWithIndifferentAccess
    def initialize(raw, opts = {})
      merge! raw
      self[:port] = port.to_i if include? :port
      normalize_adapter if include? :adapter
      normalize_db opts[:root] if include? :database
      self[:max_connections] = pool if include? :pool
    end

    # allow easier access
    def method_missing(key, *a)
      return self[key] if a.empty? && include?(key)
      super
    end

    def respond_to_missing?(key, include_private = false)
      include?(key) || super
    end

    def url
      # the gsub transforms foo:/bar
      # (which jdbc doesn't like)
      # into foo:///bar
      self[:url] || make_url.to_s.gsub(%r{:/(?=\w)}, ':///')
    end

    private

    ADAPTER_MAPPING = {
      'sqlite3' => 'sqlite',
      'postgresql' => 'postgres'
    }.freeze

    def normalize_adapter
      self[:adapter] = ADAPTER_MAPPING[adapter.to_s] || adapter.to_s
      jdbcify_adapter if SequelRails.jruby?
    end

    def jdbcify_adapter
      return if adapter =~ /^jdbc:/
      self[:adapter] = 'postgresql' if adapter == 'postgres'
      self[:adapter] = 'jdbc:' + adapter
    end

    def normalize_db(root)
      return unless include? :adapter
      return unless root
      return unless adapter.include?('sqlite') && database != ':memory:'
      # sqlite expects path as the database name
      self[:database] = File.expand_path database.to_s, root
    end

    def make_url
      if adapter =~ /^(jdbc|do):/
        scheme, subadapter = adapter.split ':'
        URI::Generic.build(
          :scheme => scheme,
          :opaque => build_url(to_hash.merge('adapter' => subadapter)).to_s
        )
      else
        build_url to_hash
      end
    end

    def build_url(cfg)
      if (adapter = cfg['adapter']) =~ /sqlite/ &&
         (database = cfg['database']) =~ /^:/
        # magic sqlite databases
        return URI::Generic.build(:scheme => adapter, :opaque => database)
      end

      # these are handled separately
      params = cfg.reject { |k, _| non_params.include? k }

      if (v = params['search_path'])
        # make sure there's no whitespace
        v = v.split(',').map(&:strip) unless v.respond_to? :join
        params['search_path'] = v.join(',')
      end

      path = cfg['database'].to_s
      path = "/#{path}" if path =~ %r{^(?!/)}

      q = URI.encode_www_form(params)
      q = nil if q.empty?

      URI::Generic.build(
        :scheme => cfg['adapter'],
        :host => cfg['host'],
        :port => cfg['port'],
        :path => path,
        :query => q
      )
    end

    def non_params
      %w(adapter host port database servers)
    end
  end
end

unless URI.respond_to? :encode_www_form
  def URI.encode_www_form(enum)
    enum.map do |k, v|
      if v.nil?
        encode_www_form_component(k)
      elsif v.respond_to?(:to_ary)
        v.to_ary.map do |w|
          str = encode_www_form_component(k)
          unless w.nil?
            str << '='
            str << encode_www_form_component(w)
          end
        end.join('&')
      else
        str = encode_www_form_component(k)
        str << '='
        str << encode_www_form_component(v)
      end
    end.join('&')
  end
end
