#!/usr/bin/env python3
import sys
import yaml
import os

def update_config(config_path, local_ip, domain="mon.essensys.fr"):
    print(f"Updating AdGuard Home config at {config_path}")
    
    if not os.path.exists(config_path):
        print(f"Error: Config file not found at {config_path}")
        sys.exit(1)

    try:
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f) or {}
    except Exception as e:
        print(f"Error parsing YAML: {e}")
        sys.exit(1)

    changed = False

    # 1. Remove invalid 'os: linux' if present (string type)
    if 'os' in config and isinstance(config['os'], str) and config['os'] == 'linux':
        print("Removing invalid 'os: linux' entry")
        del config['os']
        changed = True

    # 2. Add DNS rewrite
    if 'rewrites' not in config or config['rewrites'] is None:
        config['rewrites'] = []

    # Check if domain exists
    rewrite_exists = False
    for rule in config['rewrites']:
        if isinstance(rule, dict) and rule.get('domain') == domain:
            print(f"Domain {domain} already exists. Updating IP to {local_ip}")
            if rule.get('answer') != local_ip:
                rule['answer'] = local_ip
                changed = True
            rewrite_exists = True
            break
    
    if not rewrite_exists:
        print(f"Adding rewrite rule for {domain} -> {local_ip}")
        config['rewrites'].append({
            'domain': domain,
            'answer': local_ip
        })
        changed = True

    if changed:
        print("Saving updated configuration...")
        try:
            with open(config_path, 'w') as f:
                yaml.dump(config, f, default_flow_style=False, sort_keys=False)
            print("Configuration saved.")
        except Exception as e:
            print(f"Error saving config: {e}")
            sys.exit(1)
    else:
        print("No changes needed.")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: update_dns.py <config_path> <local_ip>")
        sys.exit(1)
    
    update_config(sys.argv[1], sys.argv[2])
