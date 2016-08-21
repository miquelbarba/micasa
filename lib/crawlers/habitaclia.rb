require 'anemone'
require 'json'

module Crawlers
  class Habitaclia
    PLANTA = 'de planta: '

    def children_text(doc, xpath)
      doc.xpath(xpath)&.children&.text&.strip&.presence
    end

    def call
      url = 'http://www.habitaclia.com/viviendas-barcelona.htm'
      opts = {
        storage: Anemone::Storage.SQLite3(),
        threads: 1,
        delay: 1,
        verbose: true,
        user_agent: "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:41.0) Gecko/20100101 Firefox/41.0"
      }
      Anemone.crawl(url, opts) do |anemone|
        anemone.on_every_page { STDOUT.flush }

        anemone.on_pages_like /habitaclia\.com\/comprar-/ do |page|
          begin
            doc = page.doc
            price = children_text(doc, '//*[@id="inificha"]/div/ul/li[5]')&.remove('.')&.split(' ')&.first
            sq_meters = children_text(doc, '//*[@id="inificha"]/div/ul/li[1]/span')
            rooms = children_text(doc, '//*[@id="inificha"]/div/ul/li[2]/span')
            doc_text = doc.to_s
            if (planta = doc_text.index(PLANTA))
              floor = doc_text[planta + PLANTA.size, 2].to_i
            else
              floor = nil
            end

            neighbour = children_text(doc, '//*[@id="idVerMapaZona"]')
            district = nil
            baths = children_text(doc, '//*[@id="inificha"]/div/ul/li[3]/span')

            url = page.url
            external_id =  url.path.split('-').last.split('.').first
            last_visit = DateTime.now
            portal = 'habitaclia'
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
              doc_text = doc.to_s
              conservation = 'sin-estado'
              title = children_text(doc, '//*[@id="inificha"]/div/h1')
              image_url = if (attrs = doc.xpath('//*[@id="fotoficha"]')&.children&.first&.attributes)
                            attrs['url']&.value
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
            puts $!.message
            puts $!.backtrace
          end
        end

        anemone.focus_crawl do |page|
          page.links.map do |link|
            if link.to_s =~ /habitaclia\.com\/viviendas-barcelona/ ||
               link.to_s =~ /habitaclia\.com\/comprar-/
              link.query = nil
              link
            end
          end.compact.uniq
        end

        #anemone.skip_links_like /fotocasa\.es\/ca\//
      end
    end
  end
end
