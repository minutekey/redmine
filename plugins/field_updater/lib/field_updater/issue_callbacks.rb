module FieldUpdater
  module IssueCallbacks
    extend ActiveSupport::Concern

    included do
      after_commit :process_field_updater, on: [:create]
    end

    private

    def process_field_updater
      begin
        updatable_fields = ['Manager'] # Add more field names as needed
        updatable_fields.each do |field_name|
          FieldUpdaterJob.set(wait: 3.seconds).perform_later(self.id, field_name)
        end
      rescue => e
        Rails.logger.error "ERROR in FieldUpdater issue callback: #{e.message}"
        Rails.logger.error e.backtrace.first(5)
      end
    end
  end
end