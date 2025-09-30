# use in the python terminal: 'py -m pip install [module]' to install packages.
# call 'help()' for documentation.
# CTRL / to comment blocks of code.
from bs4 import BeautifulSoup as bs
from pathlib import Path
import math
import requests as req
import csv
import re
import io
import pandas as pd

url = req.get('https://api.neso.energy/api/3/action/datastore_search?&resource_id=f93d1835-75bc-43e5-84ad-12472b180a98')

n = int(re.search(r'"total": (.*?)}', url.text).group(1))

print("Number of rows: " + str(n))

n = math.floor(n/100)*100

print("Last Offset Rounded Down: " + str(n)) # The last page we should append

### Offset Overide (leave as 0 to disable) ###
m = 0
### Offset Overide (leave as 0 to disable) ###

url_n = f'https://api.neso.energy/api/3/action/datastore_search?offset={m if m > 0 else n}&resource_id=f93d1835-75bc-43e5-84ad-12472b180a98'

html_n = req.get(url_n)

data_n = html_n.text

clean_data_n = re.sub('"', '', data_n)
clean_data_n = clean_data_n[:clean_data_n.rindex('}]')]
clean_data_n = clean_data_n[clean_data_n.index('{_id:'):]
clean_data_n = re.sub('{', '', clean_data_n)
clean_data_n = re.sub('}', '', clean_data_n)
clean_data_n = re.sub('_', '', clean_data_n)

with open('neso_energy_mix.csv', 'w') as neso_energy_mix:
    neso_energy_mix.write(clean_data_n)
