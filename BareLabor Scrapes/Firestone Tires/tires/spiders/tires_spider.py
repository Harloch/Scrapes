import scrapy

from tires.items import TiresItem
from scrapy.exceptions import CloseSpider

class TiresSpider(scrapy.Spider):

	name = 'tires'
	allowed_domains = ['www.firestonecompleteautocare.com']
	start_urls = ['http://www.firestonecompleteautocare.com/tires/vehicle/']
	headers = {'User-Agent':'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'}

	def parse(self, response):
		"""Getting all MAKE Urls """
		
		for sel in response.xpath('//div[@class="vehresultlist"]/ul/li'):
			req = sel.xpath('a/@href').extract()[0].strip()
			
			makename = sel.xpath('a/text()').extract()[0].strip()
			req = response.urljoin(req)
			meta = {'makename':makename}
			
			yield scrapy.Request(req, callback = self.parse_model, meta = meta, headers = self.headers)

	def parse_model(self, response):
		"""Get model/models"""
		if response.xpath('//div[@class="vehresultlist"]/ul'):
			for sel in response.xpath('//div[@class="vehresultlist"]/ul/li'):
				req = sel.xpath('a/@href').extract()[0].strip()
				model = sel.xpath('a/text()').extract()[0].strip()
				req = response.urljoin(req)
				meta = {'makename': response.meta['makename'], 'model': model}
				yield scrapy.Request(req, callback = self.parse_year, meta = meta, headers = self.headers)
		elif response.xpath('//div[@class="vehresultlistinline"]'):
			req = response.xpath('//div[@class="vehresultlistinline"]/a/@href').extract()[0].strip()
			model = response.xpath('//div[@class="vehresultlistinline"]/a/text()').extract()[0].strip()
			req = response.urljoin(req)
			meta = {'makename': response.meta['makename'], 'model': model}
			yield scrapy.Request(req, callback = self.parse_year, meta = meta, headers = self.headers)
		else:
			print 'No variants for model where found!!!!'

	def parse_year(self, response):
		
		"""Get the year"""
		if response.xpath('//div[@class="vehresultlist"]/ul'):
			for sel in response.xpath('//div[@class="vehresultlist"]/ul/li'):
				req = sel.xpath('a/@href').extract()[0].strip()
				year = sel.xpath('a/text()').extract()[0].strip()
				req = response.urljoin(req)
				meta = {'makename': response.meta['makename'], 'model': response.meta['model'], 'year': year}
				
				yield scrapy.Request(req, callback = self.parse_style, meta = meta, headers = self.headers)
		elif response.xpath('//div[@class="vehresultlistinline"]'):
			for sel in response.xpath('//div[@class="vehresultlistinline"]'):
				req = sel.xpath('a/@href').extract()[0].strip()
				year = sel.xpath('a/text()').extract()[0].strip()
				req = response.urljoin(req)
				meta = {'makename': response.meta['makename'], 'model': response.meta['model'], 'year': year}
				yield scrapy.Request(req, callback = self.parse_urls, meta = meta, headers = self.headers)

	def parse_style(self, response):
		"""Get available styles for this vehicle"""

		if response.xpath('//div[@class="vehresultlistinline"]'):
			for sel in response.xpath('//div[@class="vehresultlistinline"]/a'):
				req = sel.xpath('@href').extract()[0].strip()
				style = sel.xpath('text()').extract()[0].strip()
				req = (response.urljoin(req)+'?zip=75001')
				meta = {'makename': response.meta['makename'], 'model': response.meta['model'], 'year': response.meta['year'], 'style': style}
				
				yield scrapy.Request(req, callback = self.parse_urls, meta = meta, headers = self.headers)
		elif response.xpath('//div[@class="vehresultlist"]/ul'):
			for sel in response.xpath('//div[@class="vehresultlist"]/ul/li'):
				req = sel.xpath('a/@href').extract()[0].strip()
				style = sel.xpath('a/text()').extract()[0].strip()
				req = (response.urljoin(req)+'?zip=75001')
				meta = {'makename': response.meta['makename'], 'model': response.meta['model'], 'year': response.meta['year'], 'style': style}
				yield scrapy.Request(req, callback = self.parse_urls, meta = meta, headers = self.headers)
	def parse_urls(self, response):
		"""Get all URLS from last page"""

		item = TiresItem()
		#We have CHoosing option ( Front\Rear\SET(!) )
		if response.xpath('//a[@id="B"]'):
			req = response.xpath('//a[@id="B"]/@href').extract()[0]
			req = response.urljoin(req)
			yield scrapy.Request(req, callback = self.parse_urls, meta = response.meta, headers = self.headers)
		
		if response.xpath('//h2[@class="tire-title"]'):
			for sel in response.xpath('//h2[@class="tire-title"]/a/@href'):
				item['model'] = response.meta['model']
				item['make'] = response.meta['makename']
				item['year'] = response.meta['year']
				item['style'] = response.meta['style']
				item['tires_url'] = response.urljoin(sel.extract()).replace('%0A','')
				yield item
		if "Result Not Found" in response.xpath('//h1/text()').extract()[0]:
			#We have Choosing option (Standart(!) or Optional?)
			
			if response.xpath('//a[@id="standard-tires"]/@href'):
				req = response.xpath('//a[@id="standard-tires"]/@href').extract()[0]
				req = response.urljoin(req)
				yield scrapy.Request(req, callback = self.parse_urls, meta = response.meta, headers = self.headers)
			else:
				item['model'] = response.meta['model']
				item['make'] = response.meta['makename']
				item['year'] = response.meta['year']
				item['style'] = response.meta['style']
				item['tires_url'] = 'No URL has been found'
				item['url_to_check'] = response.url.replace('%0A','')
				yield item