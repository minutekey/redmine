module ZendeskUpdater
  module JournalCallbacks
    extend ActiveSupport::Concern

    included do
      after_commit :trigger_lambda_on_journal_update, on: [:create]
    end

    private

    def trigger_lambda_on_journal_update
      if journalized_type == "Issue"
        begin
          # Only process pokemon project issues
          return unless journalized.project.identifier == 'pokemon'
          return unless ENV['WORKSPACE']
          
          Rails.logger.info "Scheduling Zendesk update for issue #{journalized.id} journal #{id}"
          
          # Use background job with a small delay to ensure field copying callbacks complete first
          # This prevents race conditions with parent/child field copying
          ZendeskUpdateJob.set(wait: 2.seconds).perform_later(journalized.id, self.id)
        rescue => e
          Rails.logger.error "ERROR in journal callback: #{e.message}"
          Rails.logger.error e.backtrace.first(5)
        end
      end
    end
  end
end
