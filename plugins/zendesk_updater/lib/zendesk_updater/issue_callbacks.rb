module ZendeskUpdater
  module IssueCallbacks
    extend ActiveSupport::Concern

    included do
      after_commit :trigger_lambda_on_issue_update, on: [:create]
    end

    private

    def trigger_lambda_on_issue_update
      Rails.logger.info "ZendeskUpdater: Attempting to invoke lambda for issue #{id}"
      
      begin
        LambdaClient.invoke_lambda(self)
        Rails.logger.info "ZendeskUpdater: Lambda invocation completed for issue #{id}"
      rescue => e
        Rails.logger.error "ZendeskUpdater: Lambda invocation failed for issue #{id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end
end
