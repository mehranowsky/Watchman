#main switches
#update all data every 2 weeks
#Hunt targets everyday
from pathlib import Path
import subprocess
import os
import argparse

PROJECT_ROOT = Path(__file__).resolve().parent

def run_script(name):
    script = PROJECT_ROOT / name
    # ensure script is executable and call it directly (no shell)
    subprocess.run([str(script)], check=True, cwd=str(PROJECT_ROOT))
    
def main():
    
    # Argparse configs
    parser = argparse.ArgumentParser(description='An automated hunting tool')
    parser.add_argument('--update', action='store_true', help='Update all assets from hackerone and recon')
    parser.add_argument('-s', '--scan', action='store_true', help='Scan all assets via nuclei')
    
    args = parser.parse_args()

    if args.update:
        run_script("plumber.sh")
    if args.scan:
        run_script("vicious.sh")

if __name__ == "__main__":
    main()