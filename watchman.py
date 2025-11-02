import requests as req
import re
import argparse

def get_hackerone_data(param):
    uri = 'https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/refs/heads/main/data/hackerone_data.json'
    res = req.get(uri)
    res.raise_for_status()
    data = res.json()
      
    for item in data:
        for targets in item['targets']['in_scope']:
            if targets.get('asset_type') in ['URL', 'WILDCARD']:
                asset = targets['asset_identifier']
                domain = re.sub(r'^https?://', '', asset)
                if param == 'urls' and '*' not in domain:
                    print(domain)
                if param == 'wildcards' and '*' in domain:
                    print(domain)
                    

def main():
    parser = argparse.ArgumentParser(description='HackerOne target data fetcher')
    parser.add_argument('-u', '--urls', action='store_true', help='Fetch urls from HackerOne programs')
    parser.add_argument('-w', '--wildcards', action='store_true', help='Fetch wildcards from HackerOne programs')
    
    args = parser.parse_args()
    
    if args.urls:
        get_hackerone_data('urls')  
    if args.wildcards:
        get_hackerone_data('wildcards')  

if __name__ == "__main__":
    main()