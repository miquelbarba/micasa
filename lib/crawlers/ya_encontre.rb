require 'anemone'
require 'json'

module Crawlers
  class YaEncontre

    def children_text(doc, xpath)
      doc.xpath(xpath)&.children&.text&.strip&.presence
    end

    def call
      url = 'http://www.yaencontre.com/venta/viviendas/barcelona'
      opts = {
        storage: Anemone::Storage.SQLite3(),
        threads: 1,
        delay: 5,
        verbose: true,
        user_agent: "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:41.0) Gecko/20100101 Firefox/41.0"
      }
      Anemone.crawl(url, opts) do |anemone|
        anemone.on_every_page { STDOUT.flush }

        anemone.on_pages_like /venta\/piso\/inmueble/ do |page|
          begin
            doc = page.doc

            #require 'open-uri'
            #doc = Nokogiri::HTML(open('http://www.yaencontre.com/venta/piso/inmueble-20103-V-23'))

            price = children_text(doc, '//*[@id="main-content"]/div[3]/div[3]/div[1]/p/span')&.remove('.')&.split(' ')&.first
            data = children_text(doc, '//*[@id="main-content"]/div[3]/div[2]/p[1]')
            if data.nil?
              data = children_text(doc, '//*[@id="main-content"]/div[1]/div[1]/div/p')
            end

            conservation = 'sin-estado'
            floor = sq_meters = rooms = baths = nil
            data.split('|').map(&:strip).each do |item|
              if item.index('m2')
                sq_meters = item.remove('m2').strip
              elsif item.index('hab')
                rooms = item.remove('hab').strip
              elsif item.index('baños')
                baths = item.remove('baños').strip
              end
            end

            doc.xpath('//*[@id="main-content"]/div[3]/div[2]/ul')&.children&.map(&:text)&.map(&:strip)&.compact&.each do |item|
              if item.index('alturas')
                floor = item.split(' ').last
              elsif item.index('Estado')
                conservation = item.split(':')&.last&.strip
              end
            end

            neighbour = children_text(doc, '//*[@id="header"]/div[1]/div/div/div/ol/li[7]/span/span[1]')
            district = nil

            url = page.url
            external_id = url.path.split('/')&.last&.remove('inmueble-')
            last_visit = DateTime.now
            portal = 'ya_encontré'
            price_sq_meter = price && sq_meters ? price.to_i / sq_meters.to_i : nil

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
              title = children_text(doc, '//*[@id="main-content"]/div[1]/div[1]/h1')
              image_url = if (attrs = doc.xpath('//*[@id="main-content"]/div[3]/div[1]/div[1]/span[1]')&.first.attributes)
                            attrs['data-href']&.value
                          else
                            nil
                          end

              puts "title: #{title} price: #{price} neighbour: #{neighbour}"
              flat = Flat.create(title: title.presence,
                                 neighbourhood: neighbour,
                                 district: district,
                                 price: price,
                                 postal_code: nil,
                                 rooms: rooms,
                                 baths: baths,
                                 sq_meters: sq_meters,
                                 conservation: conservation,
                                 floor: floor,
                                 lat: nil,
                                 lng: nil,
                                 url: page.url,
                                 external_id: external_id,
                                 last_visit: last_visit,
                                 json: nil,
                                 image_url: image_url,
                                 portal: portal,
                                 price_sq_meter: price_sq_meter)
            end
          rescue
            puts page.url.to_s
            puts $!.message
            puts page.code
            anemone.pages.delete(page.url.to_s)
            #puts $!.backtrace
          end
        end

        anemone.focus_crawl do |page|
          page.links.map do |link|
            if link.to_s =~ /venta\/viviendas\/barcelona\/pag-/ ||
                link.to_s =~ /venta\/piso\/inmueble/
              link.query = nil
              link
            end
          end.compact.uniq
        end
      end
    end
  end
end
