import requests
from bs4 import BeautifulSoup

page = requests.get("http://dataquestio.github.io/web-scraping-pages/ids_and_classes.html")

#Gives us the URL response code
#print(page.status_code)

# Allows the HTML Response to be cleaner
soup = BeautifulSoup(page.content, 'html.parser')
#print(soup)
#print(soup.prettify)

#print(list(soup.children))
#[type(item) for item in list(soup.children)]

#print(soup.find_all('p', class_='outer-text'))
#print(soup.find_all(id="first"))
print(soup.select("div p"))
