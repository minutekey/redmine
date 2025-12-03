# frozen_string_literal: true

module ZendeskUpdater
  module RequestContextConcern
    extend ActiveSupport::Concern

    included do
      before_action :set_zendesk_request_context
    end

    private

    def set_zendesk_request_context
      ZendeskUpdater::RequestContext.set_from_headers(request.headers)
    end
  end
end
