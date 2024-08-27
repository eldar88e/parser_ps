module Parser
  class ParserBaseService
    def initialize(**params)
      @html   = Nokogiri::HTML(params[:html])
      @parsed = 0
    end
  end
end
