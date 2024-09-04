# frozen_string_literal: true

class Tools::Proxy
  def self.any
    ProxyInternal.instance.get
  end

  private

  class ProxyInternal
    include Singleton

    def get
      @proxies ||= YAML.load_file('proxies.yml')
      @proxies.sample
    end
  end
end
