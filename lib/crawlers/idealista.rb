require 'anemone'
require 'json'

def children_text(doc, xpath)
  doc.xpath(xpath)&.children&.text&.strip&.presence
end

url = 'https://www.idealista.com/venta-viviendas/barcelona-barcelona/'
opts = {
  storage: Anemone::Storage.SQLite3(),
  threads: 1,
  delay: 1,
  verbose: true,
  user_agent: "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:41.0) Gecko/20100101 Firefox/41.0"
}
Anemone.crawl(url, opts) do |anemone|
  anemone.on_every_page { STDOUT.flush }

  anemone.on_pages_like /\/inmueble\// do |page|
    begin
      doc = page.doc

      price = children_text(doc, '//*[@id="main-info"]/div[1]/span[1]/span')&.remove('.')
      sq_meters = children_text(doc, '//*[@id="main-info"]/div[1]/span[2]/span')
      rooms = children_text(doc, '//*[@id="main-info"]/div[1]/span[3]/span')
      floor = children_text(doc, '//*[@id="main-info"]/div[1]/span[4]/span[1]')
      neighbour = children_text(doc, '//*[@id="addressPromo"]/ul/li[2]')
      district = children_text(doc, '//*[@id="addressPromo"]/ul/li[3]')
      baths = children_text(doc, '//*[@id="details"]/div[4]/ul/li[3]')

      url = page.url.to_s
      external_id =  URI.parse(url).path.split('/').last
      last_visit = DateTime.now
      portal = 'idealista'
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
        conservation = if doc_text.index('para reformar')
                         'a-reformar'
                       elsif doc_text.index('buen estado')
                         'bien'
                       elsif doc_text.index('Edificio de nueva planta')
                         'reformado'
                       else
                         'sin-estado'
                       end

        title = children_text(doc, '//*[@id="main-info"]/h1/span')
        image_url = if (attrs = doc.xpath('//*[@id="main-multimedia"]/div[2]/img')&.first&.attributes)
                      attrs['data-service']&.value
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
                           baths: baths ? baths.remove('wc').strip : nil,
                           sq_meters: sq_meters,
                           conservation: conservation,
                           floor: floor ? floor.remove('º').remove('ª') : nil,
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
      if link.to_s =~ /com\/venta-viviendas\/barcelona-barcelona\/pagina/ ||
         link.to_s =~ /com\/inmueble\//
        link.query = nil
        link
      end
    end.compact.uniq
  end

  anemone.skip_links_like /idealista\.com\/fr\//,
                          /idealista\.com\/de\//,
                          /idealista\.com\/it\//,
                          /idealista\.com\/pt\//,
                          /idealista\.com\/ca\//,
                          /idealista\.com\/en\//
end
