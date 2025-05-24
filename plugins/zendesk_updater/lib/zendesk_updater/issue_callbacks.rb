module ZendeskUpdater
  module IssueCallbacks
    extend ActiveSupport::Concern

    included do
      after_commit :trigger_lambda_on_issue_update, on: [:create]
    end

    private

    def trigger_lambda_on_issue_update
      LambdaClient.invoke_lambda(self)
    end
  end
end
