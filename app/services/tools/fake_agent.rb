# frozen_string_literal: true

class Tools::FakeAgent
  def any
    FakeAgentInternal.instance.get
  end

  private

  class FakeAgentInternal
    include Singleton

    def get
      @agents ||= YAML.load_file('user-agents.yml')['user_agents']
      @agents.sample
    end
  end
end
