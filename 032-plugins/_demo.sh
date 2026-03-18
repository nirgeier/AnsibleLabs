#!/bin/bash

ROOT_FOLDER=$(git rev-parse --show-toplevel)
source $ROOT_FOLDER/_utils/common.sh
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 032 - Custom Plugins (Filter & Lookup)${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

# -------------------------------------------------------
# 1. Create filter_plugins/ with custom filter plugin
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 1] Creating filter_plugins/ directory and custom filter plugin${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "mkdir -p /labs-scripts/filter_plugins && cat > /labs-scripts/filter_plugins/custom_filters.py << 'EOF'
# Custom Ansible filter plugin
# Filters are Python functions registered under FilterModule

class FilterModule(object):
    \"\"\"Custom filters for Lab 032\"\"\"

    def filters(self):
        return {
            'mask_string': self.mask_string,
            'to_upper_snake': self.to_upper_snake,
        }

    def mask_string(self, value, visible=4, mask_char='*'):
        \"\"\"Mask all but the last N characters of a string.
        Usage: {{ my_secret | mask_string(4) }}
        \"\"\"
        value = str(value)
        if len(value) <= visible:
            return mask_char * len(value)
        return mask_char * (len(value) - visible) + value[-visible:]

    def to_upper_snake(self, value):
        \"\"\"Convert a string to UPPER_SNAKE_CASE.
        Usage: {{ 'hello world' | to_upper_snake }}  =>  HELLO_WORLD
        \"\"\"
        import re
        value = str(value).strip()
        value = re.sub(r'[\s\-]+', '_', value)
        return value.upper()
EOF
echo '=== filter_plugins/custom_filters.py ==='
cat /labs-scripts/filter_plugins/custom_filters.py"

# -------------------------------------------------------
# 2. Create playbook that uses the custom filters
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 2] Creating lab032-filters.yml playbook${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab032-filters.yml << 'EOF'
---
- name: Lab 032 - Custom Filter Plugins
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    api_key: \"sk-abc123def456ghi789\"
    db_password: \"SuperSecret2024!\"
    service_names:
      - \"my web service\"
      - \"database-primary\"
      - \"cache layer\"

  tasks:
    - name: Demonstrate mask_string filter
      ansible.builtin.debug:
        msg:
          - \"API key (raw):      {{ api_key }}\"
          - \"API key (masked):   {{ api_key | mask_string(4) }}\"
          - \"DB pass (masked):   {{ db_password | mask_string(3) }}\"

    - name: Demonstrate to_upper_snake filter
      ansible.builtin.debug:
        msg: \"{{ item }} => {{ item | to_upper_snake }}\"
      loop: \"{{ service_names }}\"

    - name: Chain filters together
      ansible.builtin.debug:
        msg: \"Env var name: {{ 'my web service api key' | to_upper_snake }}\"
EOF"

# -------------------------------------------------------
# 3. Run the filter playbook
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 3] Running the custom filter playbook${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab032-filters.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab032-filters.yml"

# -------------------------------------------------------
# 4. Create lookup_plugins/ with a simple file reader lookup
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 4] Creating lookup_plugins/ with a custom file-reader lookup${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "mkdir -p /labs-scripts/lookup_plugins && cat > /labs-scripts/lookup_plugins/ini_section.py << 'EOF'
# Custom Ansible lookup plugin: ini_section
# Returns all key=value pairs from a given [section] of an INI file
# Usage: lookup('ini_section', section='app', file='/path/to/file.ini')

from ansible.plugins.lookup import LookupBase
from ansible.errors import AnsibleError

try:
    import configparser
except ImportError:
    import ConfigParser as configparser

class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        section = kwargs.get('section', 'DEFAULT')
        filepath = kwargs.get('file', None)

        if not filepath:
            raise AnsibleError('ini_section lookup requires file= parameter')

        config = configparser.ConfigParser()
        config.read(filepath)

        if not config.has_section(section):
            return [{}]

        result = dict(config.items(section))
        return [result]
EOF
echo '=== lookup_plugins/ini_section.py created ==='

# Create a sample INI file for the lookup to read
cat > /labs-scripts/app-config.ini << 'EOF'
[database]
host=db-primary.internal
port=5432
name=myapp_db
pool_size=10

[cache]
host=redis.internal
port=6379
ttl=3600
EOF
echo '=== app-config.ini created ==='
cat /labs-scripts/app-config.ini"

# -------------------------------------------------------
# 5. Create and run a playbook using the custom lookup
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 5] Creating and running a playbook that uses the custom lookup${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab032-lookup.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab032-lookup.yml << 'EOF'
---
- name: Lab 032 - Custom Lookup Plugin
  hosts: localhost
  connection: local
  gather_facts: false

  tasks:
    - name: Read database config section via custom lookup
      ansible.builtin.set_fact:
        db_config: \"{{ lookup('ini_section', section='database', file='/labs-scripts/app-config.ini') }}\"

    - name: Show database configuration
      ansible.builtin.debug:
        msg:
          - \"DB Host:      {{ db_config.host }}\"
          - \"DB Port:      {{ db_config.port }}\"
          - \"DB Name:      {{ db_config.name }}\"
          - \"DB Pool Size: {{ db_config.pool_size }}\"

    - name: Read cache config section
      ansible.builtin.set_fact:
        cache_config: \"{{ lookup('ini_section', section='cache', file='/labs-scripts/app-config.ini') }}\"

    - name: Show cache configuration
      ansible.builtin.debug:
        msg:
          - \"Cache Host: {{ cache_config.host }}\"
          - \"Cache Port: {{ cache_config.port }}\"
          - \"Cache TTL:  {{ cache_config.ttl }} seconds\"
EOF
ansible-playbook /labs-scripts/lab032-lookup.yml"

# -------------------------------------------------------
# 6. List available custom filters via ansible-doc
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 6] Listing available filter plugins${COLOR_OFF}"
echo -e "${GREEN}$ ansible-doc -t filter -l | grep custom || true${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-doc -t filter -l | grep custom || true"
echo -e "${Red}Note: Custom plugins in filter_plugins/ are project-local and may not appear in ansible-doc -l${COLOR_OFF}"
echo -e "${CYAN}Built-in filter listing (sample):${COLOR_OFF}"
docker exec ansible-controller sh -c "ansible-doc -t filter -l | head -20 || true"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 032 complete!${COLOR_OFF}"
echo -e "  ${GREEN}filter_plugins/${COLOR_OFF}  → Python FilterModule class, auto-loaded from playbook dir"
echo -e "  ${GREEN}lookup_plugins/${COLOR_OFF}  → Python LookupBase class, called with lookup() in templates"
echo -e "  ${GREEN}mask_string${COLOR_OFF}      → hides sensitive values in debug output"
echo -e "  ${GREEN}to_upper_snake${COLOR_OFF}   → converts names to ENV_VAR style"
echo -e "  ${GREEN}ini_section${COLOR_OFF}      → reads INI config sections as a dict"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
