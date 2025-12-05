require 'redmine'

Redmine::Plugin.register :field_updater do
  name 'Field Updater'
  author 'Hillman'
  description 'Updates Redmine tickets when the data should come from an external source'
  version '1.0.0'
  url 'https://github.com/yourusername/field_updater'
  author_url 'https://github.com/yourusername'

  requires_redmine version_or_higher: '4.0.0'
end

require_relative 'lib/field_updater/processing_field_updater'
require_relative 'lib/field_updater/db/sql_server_base'
require_relative 'lib/field_updater/db/sql_server_connection_manager'

Rails.application.config.after_initialize do
  begin
    Rails.logger.info 'K2 SQL Server establishing connection...'
    FieldUpdater::Db::SqlServerBase.establish_k2_connection
    Rails.logger.info 'K2 SQL Server connection established successfully.'
    FieldUpdater::Db::SqlServerConnectionManager.start_monitor
  rescue => e
    Rails.logger.error "Failed to connect to K2 SQL Server: #{e.message}"
  end
end

# Issue callbacks handle creation only
unless Issue.included_modules.include?(FieldUpdater::IssueCallbacks)
  Issue.include(FieldUpdater::IssueCallbacks)
end