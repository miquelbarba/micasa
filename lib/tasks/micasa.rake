require 'crawlers/fotocasa'
require 'crawlers/habitaclia'
require 'crawlers/idealista'

namespace :micasa do
  task fotocasa: :environment do
    delete_db
    Crawlers::Fotocasa.new.call
  end

  task idealista: :environment do
    delete_db
    Crawlers::Idealista.new.call
  end

  task habitaclia: :environment do
    delete_db
    Crawlers::Habitaclia.new.call
  end

  def delete_db
    FileUtils.rm_f(File.join(Rails.root, 'anemone.db'))
  end
end