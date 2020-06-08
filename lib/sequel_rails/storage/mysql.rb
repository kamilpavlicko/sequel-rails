module SequelRails
  module Storage
    class Mysql < Abstract
      def _create
        execute "CREATE DATABASE IF NOT EXISTS `#{database}` DEFAULT CHARACTER SET #{charset} DEFAULT COLLATE #{collation}"
      end

      def _drop
        execute "DROP DATABASE IF EXISTS `#{database}`"
      end

      def _dump(filename)
        commands = ['mysqldump']
        add_connection_settings commands
        add_flag commands, '--no-data'
        add_flag commands, '--skip-dump-date'
        add_option commands, '--result-file', filename
        commands << database
        safe_exec commands
      end

      def _load(filename)
        commands = ['mysql']
        add_connection_settings commands
        add_option commands, '--database', database
        add_option commands, '--execute', %(SET FOREIGN_KEY_CHECKS = 0; SOURCE #{filename}; SET FOREIGN_KEY_CHECKS = 1)
        safe_exec commands
      end

      def collation
        @collation ||= super || 'utf8_unicode_ci'
      end

      private

      def add_connection_settings(commands)
        add_option commands, '--user', username
        add_option commands, '--password', password
        add_option commands, '--host', host
        add_option commands, '--port', port.to_s
      end

      def execute(statement)
        commands = ['mysql']
        add_connection_settings commands
        add_option commands, '--execute', statement
        safe_exec commands
      end
    end
  end
end
