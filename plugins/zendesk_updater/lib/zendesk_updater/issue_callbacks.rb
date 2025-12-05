module ZendeskUpdater
  module IssueCallbacks
    extend ActiveSupport::Concern

    included do
      after_commit :trigger_lambda_on_issue_creation, on: [:create]
    end

    private

    def trigger_lambda_on_issue_creation
      # Only process pokemon project issues
      return unless project.identifier == 'pokemon'
      return unless ENV['WORKSPACE']

      # Skip Updates from Zendesk for specific parent issue
      if defined?(ZendeskUpdater::RequestContext)
        ignore_issue_id = ZendeskUpdater::RequestContext.zendesk_ignore_issue_id
        if ignore_issue_id && ignore_issue_id == self.id
          Rails.logger.info "[#{self.id}] Issue callback skipped - matches X-Zendesk-Ignore issue ID #{ignore_issue_id}"
          return
        end
      end
      
      begin
        Rails.logger.info "Issue creation callback for issue #{id}"
        
        # Use background job with small delay to ensure field copying is complete
        ZendeskUpdateJob.set(wait: 3.seconds).perform_later(id, nil)
      rescue => e
        Rails.logger.error "ERROR in issue creation callback: #{e.message}"
        Rails.logger.error e.backtrace.first(5)
      end
    end
  end
end
