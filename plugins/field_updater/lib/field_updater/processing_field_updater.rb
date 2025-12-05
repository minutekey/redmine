module FieldUpdater
  class ProcessingFieldUpdater

    def self.update_custom_fields(issue, updatable_field)
      changes_made = false
      custom_field_value = nil
      old_value = nil
      issue.custom_field_values.each do |cfv|
        next unless cfv.custom_field.name == updatable_field
    
        old_value = cfv.value
        new_value = compute_new_value(issue, updatable_field)
        if new_value.nil? || new_value == old_value
          Rails.logger.info "No update computed for field #{updatable_field} on issue #{issue.id}"
          break
        end
        Rails.logger.info "Updating field #{updatable_field} on issue #{issue.id} to '#{new_value}'"
        cfv.value = new_value
        custom_field_value = cfv
        changes_made = true
        break  
      end

      if changes_made && custom_field_value
        journal = issue.init_journal(User.find_by(login: "k2"))
        journal.details.build(
          property: 'cf',                         
          prop_key: custom_field_value.custom_field.id,
          old_value: old_value,
          value: custom_field_value.value
        )
        issue.save!
        Rails.logger.info "Issue #{issue.id} saved with updated custom fields."
      else
        Rails.logger.info "No changes made to issue #{issue.id}."
      end
    end

    private
    
    def self.compute_new_value(issue, updatable_field)
      case updatable_field
      when 'Manager'
        new_value = set_manager_field(issue)
      else
        return nil
      end
    end

    def self.set_manager_field(issue)
      serial_number = issue.custom_field_values.find { |cfv| cfv.custom_field.name == 'Kiosk #' }&.value
      return nil if serial_number.blank?

      manager_last_then_first_name = nil
      
      FieldUpdater::Db::SqlServerBase.with_reconnect do
        manager_last_then_first_name = 
        FieldUpdater::Db::Models::KioskData
          .joins("JOIN Site s ON Kiosk.siteId = s.siteId
                  JOIN Territory t ON t.territoryId = s.territoryId
                  JOIN Users u ON t.marketManagerId = u.userId
                  JOIN Person p ON p.personId = u.personId")
          .where("Kiosk.serialNumber = ?", serial_number)
          .select("CONCAT(p.lastName, ', ', p.firstName) as last_then_first_name")
          .first
      end
      manager_last_then_first_name&.last_then_first_name
    end
  end
end