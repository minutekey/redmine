class FieldUpdaterJob < ApplicationJob
  queue_as :default
  
  # Retry up to 5 times with exponential backoff
  retry_on StandardError, attempts: 5, wait: ->(executions) { (2**executions.to_i).seconds } 

  def perform(issue_id, _field_name)
    begin 
      issue = Issue.find_by(id: issue_id)
      unless issue
        Rails.logger.warn "FieldUpdaterJob: Issue #{issue_id} not found, skipping"
        return
      end
      
      Rails.logger.info "FieldUpdaterJob executing for issue #{issue_id}"
      
      FieldUpdater::ProcessingFieldUpdater.update_custom_fields(issue, _field_name)
      
      Rails.logger.info "FieldUpdaterJob completed successfully for issue #{issue_id}"
    rescue => e
      Rails.logger.error "FieldUpdaterJob failed for issue #{issue_id}: #{e.message}"
      Rails.logger.error e.backtrace.first(10)
      
      # Log retry information
      if executions < 5
        Rails.logger.info "FieldUpdaterJob will retry (attempt #{executions}/5) for issue #{issue_id}"
      else
        Rails.logger.error "FieldUpdaterJob exhausted all retries for issue #{issue_id}"
      end
      
      raise # This will trigger the retry_on configuration
    end
  end
end
