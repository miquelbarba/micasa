require 'anemone'
require 'json'

module Crawlers
  class Fotocasa
    def call
      url = 'http://www.fotocasa.es/comprar/pisos/barcelona-capital/listado'
      opts = {
        storage: Anemone::Storage.SQLite3(),
        threads: 1,
        delay: 1,
        verbose: true,
        user_agent: "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:41.0) Gecko/20100101 Firefox/41.0"
      }
      Anemone.crawl(url, opts) do |anemone|
        anemone.on_every_page { STDOUT.flush }

        anemone.on_pages_like /vivienda\/barcelona-capital/ do |page|
          begin
            doc = page.doc
            floor = doc.xpath("//*[@id='litFloor']")&.first&.children&.first&.text&.strip
            baths = doc.xpath("//*[@id='litBaths']")&.first&.children&.first&.text&.strip
            text = doc.xpath("//script[@type='text/javascript']")
                       .select {|node| node && node.text.index("Ads:")}.first.text
            json = text.strip[53..-3]
            data = JSON.parse(json)

            external_id = data['oasDetailid']
            price = data['oasPrice'].presence
            if (external_id && (flat = Flat.find_by_external_id(external_id)))
              flat.last_visit = DateTime.now
              if (price && flat.price && flat.price.to_s != price.to_s)
                puts "NEW price #{price} - #{flat.price}"
                Price.create(price: flat.price, flat: flat)
                flat.price = price
              end
              flat.save

              puts "UPDATE #{external_id}"
            else
              title = doc.xpath("//*[@class='property-title']")&.first&.children&.first&.text&.strip
              keys = %w(Neighbourhood oasPrice oasGeoPostalCode oasSqmetres Conservation)
              puts keys.map { |key| "#{key}: #{data[key]}" }.join(' ')

              postal_code = data['oasGeoPostalCode'].presence
              sq_meters = data['oasSqmetres'].presence
              flat = Flat.create(title: title.presence,
                                 neighbourhood: data['Neighbourhood'].presence,
                                 district: data['District'].presence,
                                 price: price,
                                 postal_code: postal_code.size == 4 ? "0#{postal_code}" : postal_code,
                                 rooms: data['oasNumRooms'].presence,
                                 baths: baths.presence,
                                 sq_meters: sq_meters,
                                 conservation: data['Conservation'].presence,
                                 floor: floor.presence,
                                 lat: data['Lat'].presence,
                                 lng: data['Lng'].presence,
                                 url: page.url,
                                 external_id: external_id,
                                 last_visit: DateTime.now,
                                 json: json,
                                 image_url: data['urlp'],
                                 portal: 'fotocasa',
                                 price_sq_meter: price && sq_meters ? price.to_i / sq_meters.to_i : nil)

              if (values = data['PropertyFeature'])
                features = values.split('|').map(&:presence).compact.uniq
                features.each { |name| Tag.create(name: name, flat: flat) }
              end
            end
          rescue
            puts $!.message
            puts $!.backtrace
          end
        end

        anemone.focus_crawl do |page|
          page.links.map do |link|
            if link.to_s =~ /vivienda\/barcelona-capital/
              link.query = nil
              link
            elsif link.to_s =~ /es\/comprar\/pisos\/barcelona-capital/ &&
                  !(link.to_s =~ /comprar\/pisos\/barcelona-capital\/.*\/.*\/listado/) &&
                  !(link.to_s =~ /comprar\/pisos\/barcelona-capital\/.*\/listado/)
              link
            end
          end.compact.uniq
        end

        anemone.skip_links_like /fotocasa\.es\/ca\//,
                                /comprar\/pisos\/barcelona-capital\/.*\/.*\/listado/
      end
    end
  end
end
