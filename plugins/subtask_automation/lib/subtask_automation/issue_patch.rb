# require_dependency 'issue'

# module SubtaskAutomation
#   module IssuePatch
#     extend ActiveSupport::Concern

#     included do
#       after_save :propagate_fields_to_children_after_save
#       before_save :set_parent_id_with_propagation

#       def propagate_fields_to_children_after_save
#         Rails.logger.info("[SubtaskAutomation] propagate_fields_to_children_after_save called for issue ##{self.id}")
#         if self.children?
#           Rails.logger.info("[SubtaskAutomation] Issue ##{self.id} has children, checking for changed fields...")
#           propagate = false
#           changed_fields = []
#           propagate ||= saved_change_to_assigned_to_id? && changed_fields << :assigned_to_id
#           propagate ||= saved_change_to_status_id? && changed_fields << :status_id

#           root_cause_cf = IssueCustomField.find_by(name: 'Root Cause')
#           if root_cause_cf && custom_field_value_changed?(root_cause_cf.id)
#             propagate = true
#             changed_fields << :root_cause_custom_field
#           end

#           if propagate
#             Rails.logger.info("[SubtaskAutomation] Propagating fields #{changed_fields.inspect} for issue ##{self.id}")
#             propagate_to_children_from_parent!(fields: changed_fields, user: User.current)
#           end
#         end
#       end

#       def propagate_to_children_from_parent!(fields: [:assigned_to_id, :status_id, :root_cause_custom_field], user: User.current)
#         unless self.children?
#           Rails.logger.info("[SubtaskAutomation] No children to propagate for parent ##{self.id}")
#           return
#         end
#         Rails.logger.info("[SubtaskAutomation] Propagating fields #{fields.inspect} from parent ##{self.id} to children...")
#         children = self.descendants.where(parent_id: self.id)
#         root_cause_cf = IssueCustomField.find_by(name: 'Root Cause')
#         root_cause_value = root_cause_cf && self.custom_field_value(root_cause_cf.id)
#         children.each do |child|
#           updates = {}
#           updates[:assigned_to_id] = self.assigned_to_id if fields.include?(:assigned_to_id)
#           updates[:status_id] = self.status_id if fields.include?(:status_id)
#           if fields.include?(:root_cause_custom_field) && root_cause_cf
#             updates["custom_field_values"] = { root_cause_cf.id.to_s => root_cause_value }
#           end
#           Rails.logger.info("[SubtaskAutomation] Updating child ##{child.id} with: #{updates.inspect}")
#           unless updates.empty?
#             child.init_journal(user, "Updated by parent ##{self.id}: propagated changes to Assignee, Status, and/or Root Cause.")
#             child.safe_attributes = updates
#             child.save(validate: false)
#           end
#         end
#         Rails.logger.info("[SubtaskAutomation] Propagation complete for parent ##{self.id}")
#       end

#       # Helper to check if a custom field value changed
#       def custom_field_value_changed?(cf_id)
#         return false unless previous_changes["custom_field_#{cf_id}"]
#         previous_changes["custom_field_#{cf_id}"][0] != previous_changes["custom_field_#{cf_id}"][1]
#       end

#       # When a subtask is linked to a parent, propagate fields
#       def set_parent_id_with_propagation
#         old_parent_id = self.parent_id_was
#         set_parent_id_without_propagation
#         if parent_id.present? && parent_id != old_parent_id
#           parent = Issue.find_by(id: parent_id)
#           if parent
#             parent.propagate_to_children_from_parent!(fields: [:assigned_to_id, :status_id, :root_cause_custom_field], user: User.current)
#           end
#         end
#       end

#       alias_method :set_parent_id_without_propagation, :set_parent_id
#       alias_method :set_parent_id, :set_parent_id_with_propagation
#     end
#   end
# end
