# frozen_string_literal: true

module ZendeskUpdater
  # Store request-scoped data using ActiveSupport::CurrentAttributes
  # This makes data available throughout the request lifecycle, including in model callbacks
  class RequestContext < ActiveSupport::CurrentAttributes
    attribute :zendesk_ignore

    def self.set_from_headers(headers)
      self.zendesk_ignore = headers['X-Zendesk-Ignore'].to_s.downcase == 'true'
    end
  end
end
