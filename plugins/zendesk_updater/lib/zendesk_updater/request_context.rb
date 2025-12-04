# frozen_string_literal: true

module ZendeskUpdater
  # Store request-scoped data using ActiveSupport::CurrentAttributes
  # This makes data available throughout the request lifecycle, including in model callbacks
  class RequestContext < ActiveSupport::CurrentAttributes
    attribute :zendesk_ignore_issue_id

    def self.set_from_headers(headers)
      ignore_header = headers['X-Zendesk-Ignore'].to_s.strip
      self.zendesk_ignore_issue_id = ignore_header.present? ? ignore_header.to_i : nil
    end
  end
end
