module FieldUpdater
  module Db
    class SqlServerConnectionManager
      MAX_RETRIES = 3
      RETRY_DELAY = 5.seconds
      CHECK_INTERVAL = 10.minutes

      def self.start_monitor
        Thread.new do
          Thread.current.name = 'sqlserver-connection-monitor' if Thread.current.respond_to?(:name=)
          Rails.logger.info 'SQL Server connection monitor started.'

          loop do
            begin
              unless connection_active?
                Rails.logger.warn 'SQL Server connection inactive — attempting reconnect...'
                reconnect!
                Rails.logger.info 'SQL Server connection re-established.'
              end
            rescue => e
              Rails.logger.error "SQL Server reconnection failed: #{e.message}"
            ensure
              sleep CHECK_INTERVAL
            end
          end
        end
      end

      def self.connection_active?
        # Runs a simple query to confirm connectivity
        SqlServerBase.connection_pool.with_connection do |conn|
          conn.select_value('SELECT 1')
          true
        end
      rescue StandardError
        false
      end

      def self.reconnect!
        attempts = 0
        begin
          SqlServerBase.establish_k2_connection
        rescue => e
          attempts += 1
          if attempts < MAX_RETRIES
            Rails.logger.warn "Reconnection attempt #{attempts} failed: #{e.message} — retrying in #{RETRY_DELAY}s"
            sleep RETRY_DELAY
            retry
          else
            Rails.logger.fatal 'SQL Server reconnection failed after multiple attempts.'
            raise
          end
        end
      end
    end
  end
end