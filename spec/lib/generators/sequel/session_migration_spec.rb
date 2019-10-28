require 'spec_helper'
require 'generator_spec/test_case'
require 'generators/sequel/session_migration/session_migration_generator'

describe Sequel::Generators::SessionMigrationGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path('../../../../internal/tmp', __FILE__)

  before { prepare_destination }

  it 'refuses to generate migration with invalid filename' do
    expect do
      run_generator ['add:sessions']
    end.to raise_error(Sequel::IllegalMigrationNameError)
  end

  it 'creates a new migration for sessions table' do
    run_generator
    expect(destination_root).to have_structure {
      directory 'db' do
        directory 'migrate' do
          migration 'add_sessions_table' do
            contains <<-CONTENT.strip_heredoc
            Sequel.migration do
              change do
                create_table :sessions do
                  primary_key :id
                  String :session_id, :null => false, :unique => true, :index => true
                  String :data, :text => true, :null => false
                  DateTime :updated_at, :null => true, :index => true
                end
              end
            end
            CONTENT
          end
        end
      end
    }
  end
end
