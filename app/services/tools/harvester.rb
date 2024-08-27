# frozen_string_literal: true

class Tools::Harvester
  def initialize(**_)
    @harvester = HarvesterInternal.instance
  end

  def storehouse
    @harvester.storehouse
  end

  def peon
    @harvester.peon
  end

  private

  class HarvesterInternal
    include Singleton

    def settings
      @settings_
    end

    # @return [String] path Hamster storehouse directory
    def storehouse
      @_storehouse_
    end

    # @return [Peon] an instance of Peon
    def peon
      @_peon_
    end

    private

    def initialize(*_)
      project_name  = 'project001/'
      @_storehouse_ = Rails.root.join('my_parsing/', project_name).to_s
      @_peon_       = Tools::PeonService.new(storehouse)
      #@settings_    = Hamster.settings
      #Hamster.close_connection(Setting)
    end
  end
end
