#main switches
#update all data every 2 weeks
#Hunt targets everyday
import os
import argparse

# Make bash scripts executable
os.system(f"chmod +x notification.sh plumber.sh vicious.sh")

def main():
    # Argparse configs
    parser = argparse.ArgumentParser(description='An automated hunting tool')
    parser.add_argument('--update', action='store_true', help='Update all assets from hackerone and recon')
    parser.add_argument('-s', '--scan', action='store_true', help='Scan all assets via nuclei')
    
    args = parser.parse_args()



if __name__ == "__main__":
    main()