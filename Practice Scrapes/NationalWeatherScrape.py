### Using Python 3.5
import requests
from bs4 import BeautifulSoup
import pandas as pd

page = requests.get("http://forecast.weather.gov/MapClick.php?lat=37.7772&lon=-122.4168#.WNiMtBiZPVo")

soup = BeautifulSoup(page.content, 'html.parser')

sevenDay = soup.find(id="seven-day-forecast")

forecastItems = sevenDay.find_all(class_="tombstone-container")
tonight = forecastItems[0]
#print(tonight.prettify())

period = tonight.find(class_="period-name").get_text()
short_desc = tonight.find(class_="short-desc").get_text()
temp = tonight.find(class_="temp temp-low").get_text()

#Use the "img" for descriptions like this
img = tonight.find("img")
img_desc = img['title']

#print(period)
#print(short_desc)
#print(temp)
#print(img_desc)

more_periods = [pt.get_text() for pt in sevenDay.select(".tombstone-container .period-name")]
more_short_desc = [sd.get_text() for sd in sevenDay.select(".tombestone-container .short-desc")]
more_temp_tags = [t.get_text() for t in sevenDay.select(".tombstone-container .temp")]
more_full_tags = [d["title"] for d in sevenDay.select(".tombstone-container img")]

# Not needed in Python 3, deprecated as all characters are unicode
#decoded_periods = more_periods.decode('ascii','ignore')

print(more_periods)
print(more_short_desc)
print(more_temp_tags)
print(img_desc)

# Data Structures
# weather = pd.DataFrame({
#    "period": period,
#    "short_desc": short_desc,
#    "temp": temp,
#    "desc":img_desc
#})
#print(weather)
