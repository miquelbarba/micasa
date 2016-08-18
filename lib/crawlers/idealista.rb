require 'anemone'
require 'json'

url = 'https://www.idealista.com/venta-viviendas/barcelona-barcelona/'
opts = {
  storage: Anemone::Storage.SQLite3(),
  threads: 1,
  delay: 1,
  verbose: true,
  user_agent: "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:41.0) Gecko/20100101 Firefox/41.0"
}
Anemone.crawl(url, opts) do |anemone|

  anemone.on_pages_like /\/inmueble\// do |page|
    doc = page.doc
    floor = doc.xpath("//*[@id='litFloor']")&.first&.children&.first&.text&.strip
    rooms = doc.xpath("//*[@id='litRooms']")&.first&.children&.first&.text&.strip

    require 'open-uri'
    doc = Nokogiri::HTML(open("https://www.idealista.com/inmueble/32489175/"))
    doc.xpath('//*[@id="main-info"]/div[1]')
    price = doc.xpath('//*[@id="main-info"]/div[1]/span[1]/span').children.text
    sq_meters = doc.xpath('//*[@id="main-info"]/div[1]/span[2]/span').children.text
    rooms = doc.xpath('//*[@id="main-info"]/div[1]/span[3]/span').children.text
    floor = doc.xpath('//*[@id="main-info"]/div[1]/span[4]/span[1]').children.text
    neighbour = doc.xpath('//*[@id="addressPromo"]/ul/li[2]').children.text
    district = doc.xpath('//*[@id="addressPromo"]/ul/li[3]').children.text
    baths = doc.xpath('//*[@id="details"]/div[4]/ul/li[3]').children.text
    url = page.url
    external_id =  URI.parse(url).path.split('/').last
    last_visit: DateTime.now
    portal: 'idealista'
    price_sq_meter: price && sq_meters ? price.to_i / sq_meters.to_i : nil