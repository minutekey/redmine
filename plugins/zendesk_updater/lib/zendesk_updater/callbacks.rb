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

  module JournalCallbacks
    extend ActiveSupport::Concern

    included do
      after_commit :trigger_lambda_on_journal_update, on: [:create]
    end

    private

    def trigger_lambda_on_journal_update
      if journalized_type == "Issue"
        LambdaClient.invoke_lambda(journalized, self)
      end
    end
  end
end
