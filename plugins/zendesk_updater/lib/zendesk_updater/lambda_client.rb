require 'aws-sdk-lambda'

module ZendeskUpdater
  class LambdaClient
    def self.invoke_lambda(issue, journal = nil)
      return unless ENV['WORKSPACE']
      return unless issue.project.identifier == 'pokemon'

      # Add deduplication to prevent duplicate calls for the same event
      dedup_key = generate_dedup_key(issue, journal)
      cache_key = "zendesk_lambda_#{dedup_key}"
      
      # Check if we've already processed this exact combination recently
      if Rails.cache.read(cache_key)
        Rails.logger.info "Skipping duplicate Lambda call for #{dedup_key}"
        return
      end
      
      # Mark this combination as processed for the next 60 seconds
      Rails.cache.write(cache_key, true, expires_in: 60.seconds)

      function_name = "#{ENV['WORKSPACE']}-pokemon-redmine"
      payload = build_payload(issue, journal)
      return if payload.nil?

      begin
        Rails.logger.info "Invoking Lambda function #{function_name} for issue #{issue.id}, journal #{journal&.id}"
        Rails.logger.info "Lambda payload: #{payload.to_json}"
        
        client = Aws::Lambda::Client.new()
        response = client.invoke(
          function_name: function_name,
          payload: payload.to_json
        )
        
        Rails.logger.info "Lambda invocation successful, status: #{response.status_code}"
      rescue => e
        Rails.logger.error "ERROR in lambda invocation: #{e.message}"
        Rails.logger.error e.backtrace.first(10)
        
        # Clear the cache key so we can retry this call later
        Rails.cache.delete(cache_key)
        raise
      end
    end

    private
    
    def self.generate_dedup_key(issue, journal)
      # Create a unique key based on issue ID, journal ID, and issue's updated_at timestamp
      # This ensures we don't send duplicate calls for the exact same state
      journal_part = journal ? "j#{journal.id}" : "no_journal"
      timestamp_part = issue.updated_on.to_i
      "#{issue.id}_#{journal_part}_#{timestamp_part}"
    end


    def self.build_payload(issue, journal)
      return nil unless issue

      # Get all custom fields for the issue
      custom_fields = issue.available_custom_fields
      custom_field_values = issue.custom_field_values

      # For updates, track which custom fields changed
      changed_custom_fields = {}
      if journal
        journal.details.each do |detail|
          if detail.property == 'cf'
            custom_field = custom_fields.find { |cf| cf.id == detail.prop_key.to_i }
            if custom_field
              changed_custom_fields[custom_field.id] = {
                'name' => custom_field.name,
                'value' => detail.value&.to_s || '',
                'oldValue' => detail.old_value&.to_s || ''
              }
            end
          end
        end
      end

      # Build the base payload
      payload = {
        'issue' => {
          'id' => issue.id,
          'subject' => issue.subject,
          'description' => issue.description,
          'status' => issue.status.name,
          'category' => issue.category&.name,
          'priority' => issue.priority.name,
          'project' => issue.project.identifier,
          'author' => issue.author.login,
          'assignedTo' => issue.assigned_to&.login,
          'createdOn' => issue.created_on,
          'customFields' => []
        }
      }

      # Add custom fields
      if journal && journal.details.any? { |d| d.property == 'cf' }
        # For updates, only include changed custom fields
        changed_custom_fields.each do |_, cf_data|
          payload['issue']['customFields'] << cf_data
        end
      else
        # For creates or when no custom fields changed, include all custom fields
        custom_field_values.each do |cfv|
          custom_field = custom_fields.find { |cf| cf.id == cfv.custom_field_id }
          next unless custom_field

          payload['issue']['customFields'] << {
            'name' => custom_field.name,
            'value' => cfv.value.to_s
          }
        end
      end

      # Add journal information if present
      if journal
        payload['journal'] = {
          'user' => journal.user.login,
          'notes' => journal.notes,
          'createdOn' => journal.created_on
        }

        # Add changes
        changes = []
        journal.details.each do |detail|
          change = {
            'property' => detail.property,
            'propKey' => detail.prop_key,
            'oldValue' => detail.old_value,
            'value' => detail.value
          }

          # Add custom field name if it's a custom field change
          if detail.property == 'cf'
            custom_field = custom_fields.find { |cf| cf.id == detail.prop_key.to_i }
            change['customFieldName'] = custom_field.name if custom_field
          end

          changes << change
        end
        payload['journal']['changes'] = changes
      end

      payload
    end
  end
end
