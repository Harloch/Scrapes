# Python3, Quick Grab of Entire Article
import requests
from bs4 import BeautifulSoup

page = requests.get("http://bleacherreport.com/articles/2699535")
#print(page.status_code)

soup = BeautifulSoup(page.content, 'html.parser')
#print(soup.prettify)

article_start = soup.find(class_="organism contentStream slideshow")
#print(article_start)

parse_article = [pa.get_text() for pa in article_start.select(".htmlElement")]
#print(parse_article)
