require 'generators/sequel'

module Sequel
  class IllegalMigrationNameError < StandardError
    def initialize(name)
      super("Illegal name for migration file: #{name} (only lower case letters, numbers, and '_' allowed)")
    end
  end

  module Generators
    class MigrationGenerator < Base #:nodoc:
      argument :attributes, :type => :array, :default => [], :banner => 'field:type field:type'

      def create_migration_file
        set_local_assigns!
        validate_file_name!
        migration_template 'migration.rb.erb', "db/migrate/#{file_name}.rb"
      end

      attr_reader :migration_action, :table_action, :column_action, :use_change

      protected

      def set_local_assigns!
        if file_name =~ /^(add|drop|remove)_.*_(?:to|from)_(.*)/
          column_action = Regexp.last_match[1]
          set_alter!(
            Regexp.last_match[2].pluralize,
            column_action,
            column_action == 'add'
          )
        elsif file_name =~ /^(create|drop)_(.*)$/
          table_action = Regexp.last_match[1]
          set_other!(
            Regexp.last_match[2].pluralize,
            table_action,
            table_action == 'create'
          )
        else
          table_name = if file_name =~ /^(alter)_(.*)/
                         Regexp.last_match[2].pluralize
                       else
                         file_name.pluralize
                       end
          set_alter! table_name, 'add', false
        end
      end

      def set_other!(table_name, table_action, use_change)
        @table_name = table_name
        @table_action = table_action
        @column_action = 'add'
        @use_change = use_change
      end

      def set_alter!(table_name, column_action, use_change)
        @table_action = 'alter'
        @table_name = table_name
        @column_action = column_action == 'add' ? 'add' : 'drop'
        @use_change = use_change
      end

      def validate_file_name!
        raise IllegalMigrationNameError.new(file_name) unless file_name =~ /^[_a-z0-9]+$/
      end
    end
  end
end
