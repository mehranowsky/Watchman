import requests as req
import re
import argparse

def get_hackerone_data():
    uri = 'https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/refs/heads/main/data/hackerone_data.json'
    res = req.get(uri)
    res.raise_for_status()
    data = res.json()
    
    urls = []
    wildcards = []
      
    for item in data:
        for targets in item['targets']['in_scope']:
            if targets.get('asset_type') in ['URL', 'WILDCARD']:
                asset = targets['asset_identifier']
                domain = re.sub(r'^https?://', '', asset)
                
                if '*' not in domain:
                    urls.append(domain)
                if '*' in domain:
                    wildcards.append(domain)
    
    # Return both lists
    return urls, wildcards

def main():
    parser = argparse.ArgumentParser(description='HackerOne target data fetcher')
    parser.add_argument('-a', '--all', action='store_true', help='Fetch all assets and save to files')
    parser.add_argument('-u', '--urls', action='store_true', help='Fetch urls from HackerOne programs')
    parser.add_argument('-w', '--wildcards', action='store_true', help='Fetch wildcards from HackerOne programs')
    
    args = parser.parse_args()
    
    urls, wildcards = get_hackerone_data()
    
    if args.all:
        # Write to files
        with open('URLs.txt', 'w') as f:
            for url in urls:
                f.write(url + '\n')
        with open('Wildcards.txt', 'w') as f:
            for wildcard in wildcards:
                f.write(wildcard + '\n')
        print(f"Saved {len(urls)} URLs to h1_URLs.txt")
        print(f"Saved {len(wildcards)} wildcards to h1_Wildcards.txt")
        
    elif args.urls:
        # Print URLs
        for url in urls:
            print(url)
            
    elif args.wildcards:
        # Print wildcards
        for wildcard in wildcards:
            print(wildcard)
            
    else:
        print("Use -a, -u, or -w flags to fetch data")

if __name__ == "__main__":
    main()