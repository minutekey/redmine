module FieldUpdater
  module Db
    class SqlServerBase < ActiveRecord::Base
      self.abstract_class = true

      PAUSE_RETRIES = 5
      MAX_RETRIES = 50

      def self.establish_k2_connection
        k2_source = AuthSource.find_by(name: 'K2')

        raise 'K2 Auth Source not found in auth_sources table' if k2_source.nil?
        
        adapter, db_name = k2_source.base_dn.split(':')

        retry_count = 0
        begin
          establish_connection(
            adapter:    adapter,
            mode:       'dblib',
            dataserver: k2_source.host,
            database:   db_name,
            username:   k2_source.account,
            password:   k2_source.account_password, 
            reconnect:  true
          )
        rescue Timeout::Error, ActiveRecord::NoDatabaseError, TinyTds::Error => e
          retry_count += 1
          if retry_count <= MAX_RETRIES
            sleep PAUSE_RETRIES
            retry
          else
            raise "Failed to connect to K2 database after multiple attempts: #{e.message}"
          end
        end
      end
    end
  end
end