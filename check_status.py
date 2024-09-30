import requests
from datetime import datetime

url = 'http://127.0.0.1:8888/status'
status_file = '/opt/webapp/status_app.txt'
log_file = '/opt/webapp/error_app.log'

try:
    response = requests.get(url)
    if response.text == "OK":
        with open(status_file, 'a') as f:
            f.write(f'SUCCESS: {datetime.now()}\n')
    else:
        with open(status_file, 'a') as f:
            f.write(f'ERROR: {datetime.now()}\n')
        with open(log_file, 'a') as f:
            f.write(f'Error: Received unexpected response "{response.text}" at {datetime.now()}\n')

except requests.exceptions.RequestException as e:
    with open(status_file, 'a') as f:
        f.write(f'ERROR: {datetime.now()}\n')
    with open(log_file, 'a') as f:
        f.write(f'Error: Application is unreachable. Exception: {e} at {datetime.now()}\n')