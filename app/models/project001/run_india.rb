class Project001::RunIndia < Project001::StoreBase
  self.table_name = 'runs_india'

  def self.last_id
    last = last_run
    last && last.status != 'finish' ? last.id : set_new_id
  end

  def self.status
    last_run.status
  end

  def self.status=(new_status)
    last_run.update status: new_status.to_s
    new_status.to_s
  end

  def self.finish
    last_run.update status: 'finish'
  end

  private

  def self.last_run
    self.last
  end

  def self.set_new_id
    self.create.id
  end
end