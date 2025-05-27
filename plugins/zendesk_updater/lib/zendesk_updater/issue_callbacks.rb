module ZendeskUpdater
  module IssueCallbacks
    extend ActiveSupport::Concern

    included do
      after_commit :trigger_lambda_on_issue_update, on: [:create]
    end

    private

    def trigger_lambda_on_issue_update
      puts "=== ZENDESK ISSUE CALLBACK TRIGGERED ==="
      puts "Issue ID: #{self.id}"
      puts "Issue Subject: #{self.subject}"
      puts "Timestamp: #{Time.current}"
      
      STDOUT.flush
      
      begin
        result = LambdaClient.invoke_lambda(self)
        puts "Lambda invocation result: #{result}"
      rescue => e
        puts "ERROR in lambda invocation: #{e.message}"
        puts e.backtrace.first(5)
      end
      
      STDOUT.flush
      puts "=== END ZENDESK ISSUE CALLBACK ==="
    end
  end
end
