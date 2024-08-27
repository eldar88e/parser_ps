class Projects::Project001::FillAdditionJob < ApplicationJob
  queue_as :default

  def perform(**args)
    country   = args[:country]
    run_id    = args[:run_id]
    additions = Project001::Addition.touched(run_id, country, args[:limit], args[:offset])
    return unless additions.present?

    additions.each do |addition|
      element = addition.b_iblock_element
      Projects::Project001::SaveSearchDataService.call(element)
      Projects::Project001::SaveFasetService.call(element)
    end

    nil
  end
end
