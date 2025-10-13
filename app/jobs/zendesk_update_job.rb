class ZendeskUpdateJob < ApplicationJob
  queue_as :default

  def perform(issue_id, journal_id = nil)
    issue = Issue.find_by(id: issue_id)
    unless issue
      Rails.logger.warn "Issue #{issue_id} not found, skipping Zendesk update"
      return
    end
    journal = journal_id ? Journal.find_by(id: journal_id) : nil
    if journal_id && journal.nil?
      Rails.logger.warn "ZendeskUpdateJob: journal not found for journal_id #{journal_id}"
    end
    
    Rails.logger.info "ZendeskUpdateJob executing for issue #{issue_id}, journal #{journal_id}"
    
    ZendeskUpdater::LambdaClient.invoke_lambda(issue, journal)
  rescue => e
    Rails.logger.error "ZendeskUpdateJob failed for issue #{issue_id}, journal #{journal_id}: #{e.message}"
    Rails.logger.error e.backtrace.first(10)
    raise # This will retry the job if retry is configured
  end
end
