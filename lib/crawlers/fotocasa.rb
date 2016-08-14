require 'anemone'
require 'json'

#http://www.fotocasa.es/vivienda/barcelona-capital/villarroel-139324937?opi=1&tti=1&pagination=1&rowgrid=5&tta=8&tp=0
url = 'http://www.fotocasa.es/comprar/pisos/barcelona-capital/listado?crp=1&llm=724,9,8,232,376,8019,0,0,0&bsm=1&opi=1&ftg=false&pgg=false&odg=false&fav=false&grad=false&fss=true&mode=3&cu=es-es&nhtti=1&craap=1&fss=true'
url = 'http://www.fotocasa.es/comprar/pisos/barcelona-capital/listado'
opts = {
    storage: Anemone::Storage.SQLite3(),
    threads: 1,
    delay: 1,
    verbose: true,
    user_agent: "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:41.0) Gecko/20100101 Firefox/41.0"
}
Anemone.crawl(url, opts) do |anemone|
  #anemone.on_every_page { |page| puts page.url }

  anemone.on_pages_like /vivienda\/barcelona-capital/ do |page|
    doc = page.doc
    floor = doc.xpath("//*[@id='litFloor']")&.first&.children&.first&.text&.strip
    rooms = doc.xpath("//*[@id='litRooms']")&.first&.children&.first&.text&.strip
    baths = doc.xpath("//*[@id='litBaths']")&.first&.children&.first&.text&.strip
    surface = doc.xpath("//*[@id='litSurface']")&.first&.children&.first&.text&.strip
    price = doc.xpath("//*[@id='priceContainer']")&.first&.children&.first&.text&.strip
    neighbour = doc.xpath("//*[@class='detail-section-content']")&.first&.children&.first&.text&.strip

    text = doc.xpath("//script[@type='text/javascript']").select {|node| node && node.text.index("Ads:")}.first.text
    json = text.strip[53..-3]
    data = JSON.parse(json)

    external_id = data['oasDetailid']
    price = data['oasPrice'].presence
    if (external_id && (flat = Flat.find_by_external_id(external_id)))
      flat.last_visit = DateTime.now
      flat.save

      if (price && flat.price != price)
        Price.create(price: price, flat: flat)
      end
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
  end

  anemone.focus_crawl do |page|
    page.links.map do |link|
      if link.to_s =~ /vivienda\/barcelona-capital/
        link.query = nil
        link
      elsif link.to_s =~ /es\/comprar\/pisos\/barcelona-capital/ &&
            !(link.to_s =~ /comprar\/pisos\/barcelona-capital\/.*\/.*\/listado/)
        link
      end
    end.compact.uniq
  end

  anemone.skip_links_like /fotocasa\.es\/ca\//,
                          /comprar\/pisos\/barcelona-capital\/.*\/.*\/listado/
end

# http://www.fotocasa.es/comprar/pisos/barcelona-capital/el-raval/calefaccion/listado-por-foto?crp=1&llm=724,9,8,232,376,8019,0,1152,349&bsm=1&f=pricem2&o=desc&opi=1&ftg=true&pgg=false&odg=false&fav=false&grad=false&fss=false&esm=3&mode=1&cu=es-es&pbti=2&pbsi=1&nhtti=1&craap=1&fs=false&fav=false Queue: 35544

# {"Country"=>"espana", "oasGeoCountry"=>"724", "Region"=>"barcelona", "oasGeoRegion"=>"8",
# "oasGeoRegionStr"=>"Barcelona", "Zone1"=>"bar-barcelones", "oasGeoZone1"=>"232",
# "Zone2"=>"bar-barcelona", "oasGeoZone2"=>"376", "City"=>"bar-barcelona-capital",
# "oasGeoCity"=>"8019", "oasGeoCityStr"=>"Barcelona Capital", "District"=>"barc-eixample",
# "oasGeoDistrict"=>"1151", "Neighbourhood"=>"bcn-sant-antoni", "oasGeoNeighbourhood"=>"277",
# "NeighbourhoodPremium"=>"bcn-sant-antoni", "TransactionType"=>"Venta", "oasTransaction"=>"1",
# "PropertyType"=>"Vivienda", "oasProperty"=>"2", "PropertySubtype"=>"1", "oasPropertySub"=>",1,",
# "oasPropertySubStr"=>",piso,", "CustomerType"=>"Profesional", "oasCustomer"=>"1",
# "oasFeatures"=>",1,2,3,10,13,21,32,77,84,131,",
# "PropertyFeature"=>"aire-acondicionado|||armarios|||calefaccion|||terraza|||ascensor|||electrodomesticos|||balcon|||alarma|||puerta-blindada|||",
# "PriceRange"=>"150001-250000", "oasPrice"=>"190000",
# "Lat"=>"41.37939768986196", "Lng"=>"2.1596878889349096", "oasGeoPostalCode"=>"08015",
# "oasDetailid"=>"96216561", "oasNumRooms"=>"2", "oasCompanyid"=>"900610156041",
# "urlp"=>"http://images.inmofactory.com/inmofactory/documents/1/92433/9432591/91903891.jpg/640x480/w_0/",
# "oasSqmetres"=>"63", "oasEnergeticCert"=>"6", "oasAntiquity"=>"0",
# "oasState"=>",2,", "oasStateStr"=>",muy-bien,", "Conservation"=>"muy-bien",
# ""=>"2", "oasCategory"=>"1"}

require 'json'
res = Flat.all.map do |f|
  JSON.parse(f.json)&.keys if f.json
end.compact.flatten.uniq