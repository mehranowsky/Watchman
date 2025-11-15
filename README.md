# SpaceCowboy 🚀  
**Automated Mass Hunter for HackerOne Programs**

SpaceCowboy is a fully automated **asset discovery + scanning framework** built for bug bounty hunters.  
It fetches all HackerOne program assets, enumerates subdomains, crawls endpoints, and scans everything with **Nuclei** — all hands-free.

---

## ✨ Features
- 🔄 Fetches all HackerOne program URLs & wildcards  
- 🌐 Subdomain enumeration  
- 🕷️ URL crawling & extraction  
- 🧪 Nuclei scanning  
- 🔧 Modular design (e.g., standalone **watchman.py**)  
- ⏱️ Cron-based automation support  
- 📘 Easy to deploy on any Linux server  

---

## 📥 Installation

```bash
git clone https://github.com/yourusername/SpaceCowboy.git
cd SpaceCowboy
python3 spike.py --update
