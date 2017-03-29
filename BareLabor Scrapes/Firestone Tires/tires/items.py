# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import scrapy


class TiresItem(scrapy.Item):
    # define the fields for your item here like:
    # name = scrapy.Field()
    make = scrapy.Field()
    style = scrapy.Field()
    year = scrapy.Field()
    model = scrapy.Field()
    tires_url = scrapy.Field()
    url_to_check = scrapy.Field()

