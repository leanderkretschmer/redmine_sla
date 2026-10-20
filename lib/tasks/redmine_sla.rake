namespace :redmine_sla do
  desc 'Offene SLA-Fristen aus der Ticket-Historie neu aufbauen (optional: PROJECT=identifier)'
  task rebuild: :environment do
    if ENV['PROJECT'].present?
      project = Project.find_by(identifier: ENV['PROJECT']) || Project.find_by(id: ENV['PROJECT'])
      abort "Projekt #{ENV['PROJECT']} nicht gefunden" unless project
      count = RedmineSla::DeadlineTracker.rebuild_project(project)
      puts "#{project.identifier}: #{count} offene Fristen"
    else
      RedmineSla::SlaSetting.includes(:project).find_each do |setting|
        next unless setting.project
        count = RedmineSla::DeadlineTracker.rebuild_project(setting.project)
        puts "#{setting.project.identifier}: #{count} offene Fristen"
      end
    end
  end
end
