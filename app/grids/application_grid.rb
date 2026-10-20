class ApplicationGrid < Datagrid::Base
  self.default_column_options = {
    # Uncomment to disable the default order
    # order: false,
    # Uncomment to make all columns HTML by default
    # html: true,
  }
  # ActiveRecord batching replaces any ORDER BY with one on the primary key,
  # which would make #rows ignore the requested order.
  self.batch_size = nil

  # Enable forbidden attributes protection
  # self.forbidden_attributes_protection = true

  # Makes a date column
  # @param name [Symbol] Column name
  # @param args [Array] Other column helper arguments
  # @example
  #   date_column(:created_at)
  #   date_column(:owner_registered_at) do |model|
  #     model.owner.registered_at
  #   end
  def self.date_column(name, *args, **options, &block)
    column(name, *args, **options) do |model|
      format(block ? block.call(model) : model.public_send(name)) do |date|
        date&.strftime("%m/%d/%Y") || "&mdash;".html_safe
      end
    end
  end

  # Makes a boolean YES/NO column
  # @param name [Symbol] Column name
  # @param args [Array] Other column helper arguments
  # @example
  #   boolean_column(:approved)
  #   boolean_column(:has_tasks, preload: :tasks) do |model|
  #     model.tasks.unfinished.any?
  #   end
  def self.boolean_column(name, *args, **options, &block)
    column(name, *args, **options) do |model|
      value = block ? block.call(model) : model.public_send(name)
      value ? "Yes" : "No"
    end
  end

  # Uncomment to shorten URL query string for all grids.
  # May cause collisions if multiple grids are used on the same page.
  # def param_name
  #   'grid'
  # end
end
