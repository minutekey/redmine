module FieldUpdater
  module Db
    module Models
      class KioskData < SqlServerBase
        self.table_name = 'Kiosk'
        self.primary_key = 'kioskId'
      end
    end
  end
end
