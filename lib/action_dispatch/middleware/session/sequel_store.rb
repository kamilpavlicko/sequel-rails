require 'sequel'
require 'action_dispatch/middleware/session/abstract_store'

# Implements Sequel model based session store.

module ActionDispatch
  module Session
    class SequelStore < AbstractStore
      SESSION_RECORD_KEY = 'rack.session.record'.freeze
      ENV_SESSION_OPTIONS_KEY = 'rack.session.options'.freeze

      cattr_accessor :session_class
      def self.session_class
        @@session_class ||= begin
          res = Class.new(Sequel::Model(:sessions))
          res.plugin :timestamps, :update_on_create => true
          res.plugin :serialization, :marshal, :data
          res
        end
      end

      private

      def find_session(req, sid)
        get_session(req.env, sid)
      end

      def get_session(env, sid)
        with_silenced_logger do
          session = load_from_store(sid)
          env[SESSION_RECORD_KEY] = session
          [session.session_id, session.data]
        end
      end

      def write_session(req, sid, session_data, options)
        with_silenced_logger do
          set_session(req.env, sid, session_data, options)
        end
      end

      def set_session(env, sid, session_data, options)
        session      = get_session_model(env, sid)
        session.data = session_data
        session.save(:raise_on_failure => false) && session.session_id
      end

      def delete_session(req, sid, options)
        with_silenced_logger do
          destroy_session(req.env, sid, options)
        end
      end

      def destroy_session(env, sid, options)
        session = get_session_model(env, sid)
        session.destroy unless session.new?
        env[SESSION_RECORD_KEY] = nil
        generate_sid unless options[:drop]
      end

      def get_session_model(env, sid)
        with_silenced_logger do
          if env[ENV_SESSION_OPTIONS_KEY][:id].nil?
            env[SESSION_RECORD_KEY] = load_from_store(sid)
          else
            env[SESSION_RECORD_KEY] ||= load_from_store(sid)
          end
        end
      end

      def load_from_store(sid)
        klass = self.class.session_class
        klass.where(:session_id => sid).first ||
          klass.new(:session_id => generate_sid, :data => {})
      end

      def with_silenced_logger
        Rails.application.config.sequel.logger.silence { yield }
      end
    end
  end
end
