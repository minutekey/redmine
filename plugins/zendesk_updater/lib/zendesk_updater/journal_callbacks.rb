module ZendeskUpdater
  module JournalCallbacks
    extend ActiveSupport::Concern

    included do
      after_commit :trigger_lambda_on_journal_update, on: [:create]
    end

    private

    def trigger_lambda_on_journal_update
      puts "=== ZENDESK JOURNAL CALLBACK TRIGGERED ==="
      puts "Journal ID: #{self.id}"
      puts "Journalized Type: #{self.journalized_type}"
      puts "Timestamp: #{Time.current}"
      
      STDOUT.flush
      
      if journalized_type == "Issue"
        puts "Processing Issue journal update"
        begin
          result = LambdaClient.invoke_lambda(journalized, self)
          puts "Lambda invocation result: #{result}"
        rescue => e
          puts "ERROR in lambda invocation: #{e.message}"
          puts e.backtrace.first(5)
        end
      else
        puts "Skipping non-Issue journal (type: #{journalized_type})"
      end
      
      puts "=== END ZENDESK JOURNAL CALLBACK ==="
      STDOUT.flush
    end
  end
end
