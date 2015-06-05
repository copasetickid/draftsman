class Draftsman::Draft < ActiveRecord::Base
  # Mass assignment (for <= ActiveRecord 3.x)
  if Draftsman.active_record_protected_attributes?
    attr_accessible :item_type, :item_id, :item, :event, :whodunnit, :object, :object_changes, :previous_draft
  end

  # Associations
  belongs_to :item, :polymorphic => true

  # Validations
  validates_presence_of :event

  def self.with_item_keys(item_type, item_id)
    scoped :conditions => { :item_type => item_type, :item_id => item_id }
  end

  def self.creates
    where :event => 'create'
  end

  def self.destroys
    where :event => 'destroy'
  end

  # Returns whether the `object` column is using the `json` type supported by PostgreSQL.
  def self.object_col_is_json?
    @object_col_is_json ||= columns_hash['object'].type == :json
  end

  # Returns whether the `object_changes` column is using the `json` type supported by PostgreSQL.
  def self.object_changes_col_is_json?
    @object_changes_col_is_json ||= columns_hash['object_changes'].type == :json
  end

  # Returns whether the `previous_draft` column is using the `json` type supported by PostgreSQL.
  def self.previous_draft_col_is_json?
    @previous_draft_col_is_json ||= columns_hash['previous_draft'].type == :json
  end

  def self.updates
    where :event => 'update'
  end

  # Returns what changed in this draft. Similar to `ActiveModel::Dirty#changes`.
  # Returns `nil` if your `drafts` table does not have an `object_changes` text column.
  def changeset
    return nil unless self.class.column_names.include? 'object_changes'

    _changes = self.class.object_changes_col_is_json? ? self.object_changes : Draftsman.serializer.load(self.object_changes)

    @changeset ||= HashWithIndifferentAccess.new(_changes).tap do |changes|
      item_type.constantize.unserialize_draft_attribute_changes(changes)
    end
  rescue
    {}
  end

  # Returns whether or not this is a `create` event.
  def create?
    self.event == 'create'
  end

  # Returns whether or not this is a `destroy` event.
  def destroy?
    self.event == 'destroy'
  end

  # Returns related draft dependencies that would be along for the ride for a `publish!` action.
  def draft_publication_dependencies
    dependencies = []

    my_item = self.item.draft? ? self.item.draft.reify : self.item

    case self.event
    when 'create', 'update'
      associations = my_item.class.reflect_on_all_associations(:belongs_to)

      associations.each do |association|
        association_class =
          if association.options.key?(:polymorphic)
            my_item.send(association.foreign_key.sub('_id', '_type')).constantize
          else
            association.klass
          end

        if association_class.draftable? && association.name != association_class.draft_association_name.to_sym
          dependency = my_item.send(association.name)
          dependencies << dependency.draft if dependency.present? && dependency.draft? && dependency.draft.create?
        end
      end
    when 'destroy'
      associations = my_item.class.reflect_on_all_associations(:has_one) + my_item.class.reflect_on_all_associations(:has_many)

      associations.each do |association|
        if association.klass.draftable?
          # Reconcile different association types into an array, even if `has_one` produces a single-item
          associated_dependencies =
            case association.macro
            when :has_one
              my_item.send(association.name).present? ? [my_item.send(association.name)] : []
            when :has_many
              my_item.send(association.name)
            end

          associated_dependencies.each do |dependency|
            dependencies << dependency.draft if dependency.draft?
          end
        end
      end
    end

    dependencies
  end

  # Returns related draft dependencies that would be along for the ride for a `revert!` action.
  def draft_reversion_dependencies
    dependencies = []

    case self.event
    when 'create'
      associations = self.item.class.reflect_on_all_associations(:has_one) + self.item.class.reflect_on_all_associations(:has_many)

      associations.each do |association|
        if association.klass.draftable?
          # Reconcile different association types into an array, even if `has_one` produces a single-item
          associated_dependencies =
            case association.macro
            when :has_one
              self.item.send(association.name).present? ? [self.item.send(association.name)] : []
            when :has_many
              self.item.send(association.name)
            end

          associated_dependencies.each do |dependency|
            dependencies << dependency.draft if dependency.draft?
          end
        end
      end
    when 'destroy'
      associations = self.item.class.reflect_on_all_associations(:belongs_to)

      associations.each do |association|
        association_class =
          if association.options.key?(:polymorphic)
            self.item.send(association.foreign_key.sub('_id', '_type')).constantize
          else
            association.klass
          end

        if association_class.draftable? && association_class.trashable? && association.name != association_class.draft_association_name.to_sym
          dependency = self.item.send(association.name)
          dependencies << dependency.draft if dependency.present? && dependency.draft? && dependency.draft.destroy?
        end
      end
    end

    dependencies
  end

  # Publishes this draft's associated `item`, publishes its `item`'s dependencies, and destroys itself.
  # -  For `create` drafts, adds a value for the `published_at` timestamp on the item and destroys the draft.
  # -  For `update` drafts, applies the drafted changes to the item and destroys the draft.
  # -  For `destroy` drafts, destroys the item and the draft.
  def publish!
    ActiveRecord::Base.transaction do
      case self.event
      when 'create', 'update'
        # Parents must be published too
        self.draft_publication_dependencies.each { |dependency| dependency.publish! }

        # Update drafts need to copy over data to main record
        self.item.attributes = self.reify.attributes if self.update?

        # Write `published_at` attribute
        self.item.send "#{self.item.class.published_at_attribute_name}=", Time.now

        # Clear out draft
        self.item.send "#{self.item.class.draft_association_name}_id=", nil

        # Determine which columns should be updated
        only   = self.item.class.draftsman_options[:only]
        ignore = self.item.class.draftsman_options[:ignore]
        skip   = self.item.class.draftsman_options[:skip]
        attributes_to_change = only.any? ? only : self.item.attribute_names
        attributes_to_change = attributes_to_change - ignore + ['published_at', "#{self.item.class.draft_association_name}_id"] - skip

        # Save without validations or callbacks
        self.item.attributes.slice(*attributes_to_change).each do |key, value|
          self.item.send("#{key}=", value)
        end
        self.item.save(:validate => false)
        
        self.item.reload

        # Destroy draft
        self.destroy
      when 'destroy'
        self.item.destroy
      end
    end
  end

  # Returns instance of item converted to its drafted state.
  #
  # Example usage:
  #
  #     `@category = @category.reify if @category.draft?`
  def reify
    without_identity_map do
      if !self.previous_draft.nil?
        reify_previous_draft.reify
      elsif !self.object.nil?
        # This appears to be necessary if for some reason the draft's model hasn't been loaded (such as when done in the console).
        # require self.item_type.underscore

        model = item.reload

        attrs = self.class.object_col_is_json? ? self.object : Draftsman.serializer.load(object)
        model.class.unserialize_attributes_for_draftsman attrs

        attrs.each do |key, value|
          # Skip counter_cache columns
          if model.respond_to?("#{key}=") && !key.end_with?('_count')
            model.send "#{key}=", value
          elsif !key.end_with?('_count')
            logger.warn "Attribute #{key} does not exist on #{item_type} (Draft ID: #{id})."
          end
        end

        model.send "#{model.class.draft_association_name}=", self
        model
      end
    end
  end

  # Reverts this draft.
  # -  For create drafts, destroys the draft and the item.
  # -  For update drafts, destroys the draft only.
  # -  For destroy drafts, destroys the draft and undoes the `trashed_at` timestamp on the item. If a previous draft was
  #    drafted for destroy, restores the draft.
  def revert!
    ActiveRecord::Base.transaction do
      case self.event
      when 'create'
        self.item.destroy
        self.destroy
      when 'update'
        self.item.class.where(:id => self.item).update_all("#{self.item.class.draft_association_name}_id".to_sym => nil)
        self.destroy
      when 'destroy'
        # Parents must be restored too
        self.draft_reversion_dependencies.each { |dependency| dependency.revert! }

        # Restore previous draft if one was stashed away
        if self.previous_draft.present?
          prev_draft = reify_previous_draft
          prev_draft.save!

          self.item.class.where(:id => self.item).update_all "#{self.item.class.draft_association_name}_id".to_sym => prev_draft.id,
                                                             self.item.class.trashed_at_attribute_name => nil
        else
          self.item.class.where(:id => self.item).update_all "#{self.item.class.draft_association_name}_id".to_sym => nil,
                                                             self.item.class.trashed_at_attribute_name => nil
        end
        
        self.destroy
      end
    end
  end

  # Returns whether or not this is an `update` event.
  def update?
    self.event == 'update'
  end

private

  # Restores previous draft and returns it.
  def reify_previous_draft
    draft = self.class.new

    without_identity_map do
      attrs = self.class.object_col_is_json? ? self.previous_draft : Draftsman.serializer.load(self.previous_draft)

      attrs.each do |key, value|
        if key.to_sym != :id && draft.respond_to?("#{key}=")
          draft.send "#{key}=", value
        elsif key.to_sym != :id
          logger.warn "Attribute #{key} does not exist on #{item_type} (Draft ID: #{self.id})."
        end
      end
    end

    draft
  end

  def without_identity_map(&block)
    if defined?(ActiveRecord::IdentityMap) && ActiveRecord::IdentityMap.respond_to?(:without)
      ActiveRecord::IdentityMap.without &block
    else
      block.call
    end
  end
end
