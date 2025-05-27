require 'redmine'

Redmine::Plugin.register :zendesk_updater do
  name 'Zendesk Updater'
  author 'Hillman'
  description 'Updates Zendesk tickets when Redmine issues are created or updated'
  version '1.0.0'
  url 'https://github.com/yourusername/zendesk_updater'
  author_url 'https://github.com/yourusername'

  requires_redmine version_or_higher: '4.0.0'
end

puts "=== LOADING ZENDESK UPDATER MODULES ==="
STDOUT.flush

require_relative 'lib/zendesk_updater/issue_callbacks'
require_relative 'lib/zendesk_updater/journal_callbacks'
require_relative 'lib/zendesk_updater/lambda_client'

puts "=== MODULES LOADED, CHECKING MODEL CLASSES ==="
puts "Issue class exists: #{defined?(Issue)}"
puts "Journal class exists: #{defined?(Journal)}"
STDOUT.flush

Rails.application.config.to_prepare do
  puts "=== TO_PREPARE BLOCK EXECUTING ==="
  
  if defined?(Issue)
    unless Issue.included_modules.include?(ZendeskUpdater::IssueCallbacks)
      puts "Including IssueCallbacks in Issue model"
      Issue.include(ZendeskUpdater::IssueCallbacks)
    else
      puts "IssueCallbacks already included in Issue model"
    end
    
    # Check if callbacks are registered
    issue_callbacks = Issue._commit_callbacks.select { |cb| cb.filter.to_s.include?('lambda') }
    puts "Issue commit callbacks with 'lambda': #{issue_callbacks.size}"
  else
    puts "Issue class not yet defined"
  end
  
  if defined?(Journal)
    unless Journal.included_modules.include?(ZendeskUpdater::JournalCallbacks)
      puts "Including JournalCallbacks in Journal model"
      Journal.include(ZendeskUpdater::JournalCallbacks)
    else
      puts "JournalCallbacks already included in Journal model"
    end
    
    # Check if callbacks are registered
    journal_callbacks = Journal._commit_callbacks.select { |cb| cb.filter.to_s.include?('lambda') }
    puts "Journal commit callbacks with 'lambda': #{journal_callbacks.size}"
  else
    puts "Journal class not yet defined"
  end
  
  STDOUT.flush
  puts "=== TO_PREPARE BLOCK COMPLETE ==="
end

puts "=== ZENDESK UPDATER PLUGIN LOADED ==="
STDOUT.flush
