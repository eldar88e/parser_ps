class Scraper::ScraperBaseService < Tools::Harvester
  def initialize(**params)
    super(**params)
    @count = 0
  end

  SSL_OPTS = { verify: true }

  def connect_to(*arguments, &block)
    return if arguments.nil? || arguments.empty?

    url = arguments.first.is_a?(String) ? arguments.shift : arguments.first[:url]
    return if url.nil?

    arguments    = arguments.first.dup
    condition    = arguments.is_a?(Hash)
    headers      = (condition ? arguments[:headers].dup : nil) || {}
    req_body     = condition ? arguments[:req_body].dup : nil
    cookies      = condition ? arguments[:cookies].dup : nil
    iteration    = (condition ? arguments[:iteration].dup : nil) || 0
    open_timeout = (condition ? arguments[:open_timeout].dup : nil) || 5
    method       = (condition ? arguments[:method].dup : nil) || :get
    timeout      = (condition ? arguments[:timeout].dup : nil) || 60
    ssl_verify   = (condition ? arguments[:ssl_verify].dup : true)
    filename     = (condition ? arguments[:filename].dup : nil)
    matched_url  = url ? url.match(%r{^(https?://[-a-z0-9._]+)(/.+)?}i) : nil
    url_domain   = matched_url ? matched_url[1] : ''
    url_path     = matched_url ? matched_url[2] : '/'
    proxy        = condition ? arguments[:proxy].dup : fetch_proxy

    begin
      if iteration == 5
        Rails.logger.error "Loop depth more than 5."
        exit 0
      end

      proxy   = fetch_proxy if iteration > 0
      headers = headers.merge(user_agent: Tools::FakeAgent.new.any) unless headers.include?(:user_agent)
      headers.merge!(cookies) if cookies

      faraday_params = {
        url:     url_domain,
        ssl:     { verify: ssl_verify },
        proxy:   proxy,
        request: {
          open_timeout: open_timeout,
          timeout:      timeout
        }
      }

      connection     =
        Faraday.new(faraday_params) do |c|
          c.headers = headers
          c.adapter :net_http
          c.response :logger if Rails.env.development?
        end

      case method
      when :get
        connection.get(url_path)
      when :post
        connection.post(url_path, req_body)
      when :get_file
        file = open(filename, "wb")
        begin
          connection.get(url_path) do |req|
            req.options.on_data = Proc.new do |chunk, _|
              file.write chunk
            end
          end
        ensure
          file.close
        end
      else
        nil
      end
    rescue => e
      Rails.logger.error e.message
      TelegramService.call e.message
      iteration += 0
      retry
    end
  end

  private

  def fetch_proxy
    Tools::Proxy.any
  end
end
