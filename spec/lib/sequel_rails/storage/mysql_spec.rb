require 'spec_helper'

describe SequelRails::Storage::Mysql, :mysql do
  let(:username)      { 'username' }
  let(:host)          { 'host' }
  let(:port)          { 1234 }
  let(:password)      { 'password' }
  let(:charset)       { 'charset' }
  let(:collation)     { 'collation' }
  let(:database)      { 'database' }
  let(:config) do
    {
      'adapter' => 'postgres',
      'username' => username,
      'password' => password,
      'host' => host,
      'port' => port,
      'database' => database,
      'charset' => charset,
      'collation' => collation,
    }
  end
  subject { described_class.new config }

  describe '#_create' do
    context 'with all possible options' do
      it 'uses the mysql command' do
        expect(subject).to receive(:`).with(
          "mysql --user\\=#{username} --password\\=#{password} --host\\=#{host} --port\\=#{port} --execute\\=CREATE\\ DATABASE\\ IF\\ NOT\\ EXISTS\\ \\`#{database}\\`\\ DEFAULT\\ CHARACTER\\ SET\\ #{charset}\\ DEFAULT\\ COLLATE\\ #{collation}"
        )
        subject._create
      end
    end
  end

  describe '#_drop' do
    it 'uses the mysql command' do
      expect(subject).to receive(:`).with(
        "mysql --user\\=#{username} --password\\=#{password} --host\\=#{host} --port\\=#{port} --execute\\=DROP\\ DATABASE\\ IF\\ EXISTS\\ \\`#{database}\\`"
      )
      subject._drop
    end
  end

  describe '#_dump' do
    let(:dump_file_name) { 'dump.sql' }
    it 'uses the mysqldump command' do
      expect(subject).to receive(:`).with(
        "mysqldump --user\\=#{username} --password\\=#{password} --host\\=#{host} --port\\=#{port} --no-data --skip-dump-date --result-file\\=#{dump_file_name} #{database}"
      )
      subject._dump dump_file_name
    end
  end

  describe '#_load' do
    let(:dump_file_name) { 'dump.sql' }
    it 'uses the mysql command' do
      expect(subject).to receive(:`).with(
        'mysql --user\\=username --password\\=password --host\\=host --port\\=1234 --database\\=database --execute\\=SET\\ FOREIGN_KEY_CHECKS\\ \\=\\ 0\\;\\ SOURCE\\ dump.sql\\;\\ SET\\ FOREIGN_KEY_CHECKS\\ \\=\\ 1'
      )
      subject._load dump_file_name
    end
  end
end
