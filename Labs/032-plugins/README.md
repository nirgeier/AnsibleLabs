---
# Ansible Plugins

* In this lab we explore Ansible **plugins** - Python components that extend Ansible's core behavior without writing a full module.
* Plugins hook into different parts of Ansible: lookups, filters, callbacks, connections, and more.
* Custom filter and lookup plugins are the most commonly written plugin types.

## What will we learn?

- Types of Ansible plugins
- Writing and using **lookup** plugins
- Writing and using **filter** plugins
- Using **callback** plugins to customize output

---

## Prerequisites

- Complete [Lab 028](../028-custom-modules/README.md#usage) in order to have a working knowledge of custom Ansible modules.

---

## 01. Plugin Types

| Plugin Type    | Purpose                                           | Example                        |
| -------------- | ------------------------------------------------- | ------------------------------ |
| **callback**   | Customize output, integrate with external systems | `yaml`, `json`, `splunk`       |
| **connection** | How Ansible connects to hosts                     | `ssh`, `docker`, `winrm`       |
| **filter**     | Custom Jinja2 filters for data transformation     | `to_json`, `selectattr`        |
| **lookup**     | Retrieve data from external sources               | `file`, `env`, `password`      |
| **inventory**  | Dynamic inventory generation                      | `aws_ec2`, `docker_containers` |
| **action**     | Intercept and modify task execution               | `template`, `copy`             |
| **vars**       | Load variables from external sources              | `host_group_vars`              |
| **strategy**   | Change how plays are executed                     | `linear`, `free`, `debug`      |

---

## 02. Built-in Lookup Plugins

```yaml
tasks:
  # Read a local file
  - name: Read file content
    ansible.builtin.debug:
      msg: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"

  # Read an environment variable
  - name: Read env var
    ansible.builtin.debug:
      msg: "HOME is: {{ lookup('env', 'HOME') }}"

  # Read a CSV file
  - name: Read CSV
    ansible.builtin.debug:
      msg: "{{ lookup('csvfile', 'alice file=users.csv col=1 delimiter=,') }}"

  # Generate a password (and save to a file for reuse)
  - name: Generate password
    ansible.builtin.user:
      name: myuser
      password: "{{ lookup('password', '/tmp/myuser_pass length=16') | password_hash('sha512') }}"

  # DNS lookup
  - name: Get IP for hostname
    ansible.builtin.debug:
      msg: "{{ lookup('dig', 'example.com') }}"

  # URL fetch
  - name: Get content from URL
    ansible.builtin.debug:
      msg: "{{ lookup('url', 'https://api.example.com/version') }}"

  # Loop over multiple lookups
  - name: Show all env vars
    ansible.builtin.debug:
      msg: "{{ lookup('env', item) }}"
    loop:
      - HOME
      - USER
      - PATH

  # Pipe output from a command
  - name: Get git commit
    ansible.builtin.debug:
      msg: "{{ lookup('pipe', 'git rev-parse HEAD') }}"
```

---

## 03. Built-in Filter Plugins

```yaml
vars:
  servers:
    - { name: web1, role: web, active: true, port: 80 }
    - { name: web2, role: web, active: false, port: 80 }
    - { name: db1, role: db, active: true, port: 5432 }

tasks:
  # selectattr: filter list by attribute
  - name: Get active servers
    ansible.builtin.debug:
      msg: "{{ servers | selectattr('active', 'eq', true) | list }}"

  # rejectattr: exclude items
  - name: Get inactive servers
    ansible.builtin.debug:
      msg: "{{ servers | rejectattr('active') | list }}"

  # map: extract attribute
  - name: Get all server names
    ansible.builtin.debug:
      msg: "{{ servers | map(attribute='name') | list }}"

  # groupby: group by attribute
  - name: Group by role
    ansible.builtin.debug:
      msg: "{{ servers | groupby('role') }}"

  # combine: merge two dicts
  - name: Merge configs
    vars:
      defaults: { debug: false, port: 80, timeout: 30 }
      overrides: { debug: true, port: 8080 }
    ansible.builtin.debug:
      msg: "{{ defaults | combine(overrides) }}"

  # dict2items / items2dict
  - name: Convert dict to list
    vars:
      mydict: { key1: val1, key2: val2 }
    ansible.builtin.debug:
      msg: "{{ mydict | dict2items }}"
```

---

## 04. Writing a Custom Filter Plugin

```python
# filter_plugins/my_filters.py

def to_ini_string(data, section="default"):
    """Convert a dictionary to an INI-style string."""
    lines = [f"[{section}]"]
    for key, value in data.items():
        lines.append(f"{key} = {value}")
    return "\n".join(lines)


def mask_password(password, visible=4):
    """Mask a password, showing only the last N characters."""
    if len(password) <= visible:
        return "*" * len(password)
    return "*" * (len(password) - visible) + password[-visible:]


def version_compare(version1, operator, version2):
    """Compare two version strings."""
    from packaging import version
    v1 = version.parse(str(version1))
    v2 = version.parse(str(version2))
    ops = {
        '==': v1 == v2,
        '!=': v1 != v2,
        '<':  v1 < v2,
        '<=': v1 <= v2,
        '>':  v1 > v2,
        '>=': v1 >= v2,
    }
    return ops.get(operator, False)


class FilterModule(object):
    """Custom Ansible filter plugins."""

    def filters(self):
        return {
            'to_ini_string': to_ini_string,
            'mask_password': mask_password,
            'version_compare': version_compare,
        }
```

```yaml
# Using custom filters
tasks:
  - name: Use custom to_ini_string filter
    vars:
      my_config:
        host: localhost
        port: 5432
        database: mydb
    ansible.builtin.debug:
      msg: "{{ my_config | to_ini_string('database') }}"

  - name: Mask a password for logging
    ansible.builtin.debug:
      msg: "Password: {{ db_password | mask_password }}"
```

---

## 05. Callback Plugins

Callback plugins customize Ansible's output format and can trigger external actions:

```ini
# ansible.cfg - enable callback plugins
[defaults]
stdout_callback = yaml          # Output format: yaml, json, minimal, dense
callback_enabled = timer, profile_tasks, mail

# Available built-in callbacks:
# yaml          - YAML-formatted output (more readable)
# json          - JSON output (good for parsing)
# minimal       - Minimal output (host: status)
# dense         - Dense, compact output
# timer         - Add timing info to play recap
# profile_tasks - Show task timing after each task
```

---

## 06. Writing a Custom Callback Plugin

```python
# callback_plugins/deployment_logger.py

from ansible.plugins.callback import CallbackBase
import datetime
import json

class CallbackModule(CallbackBase):
    """Log deployments to a JSON file."""

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'notification'
    CALLBACK_NAME = 'deployment_logger'
    CALLBACK_NEEDS_ENABLED = True

    def __init__(self):
        super(CallbackModule, self).__init__()
        self.log_file = '/var/log/ansible-deployments.json'
        self.events = []

    def v2_playbook_on_start(self, playbook):
        self.events.append({
            'event': 'playbook_start',
            'playbook': playbook._file_name,
            'timestamp': datetime.datetime.utcnow().isoformat()
        })

    def v2_runner_on_ok(self, result, **kwargs):
        self.events.append({
            'event': 'task_ok',
            'host': result._host.name,
            'task': result.task_name,
            'changed': result.is_changed(),
            'timestamp': datetime.datetime.utcnow().isoformat()
        })

    def v2_playbook_on_stats(self, stats):
        with open(self.log_file, 'a') as f:
            for event in self.events:
                f.write(json.dumps(event) + '\n')
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 07. Hands-on

1. Create a custom filter plugin with three filters: `mask_string`, `to_env_format`, and `extract_hostnames`:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && mkdir -p filter_plugins && cat > filter_plugins/custom_filters.py << 'EOF'
   def mask_string(value, show_last=4, mask_char='*'):
       value = str(value)
       if len(value) <= show_last:
           return mask_char * len(value)
       return mask_char * (len(value) - show_last) + value[-show_last:]


   def to_env_format(data, prefix=''):
       lines = []
       for key, value in data.items():
           env_key = (prefix.upper() + key.upper()).replace('-', '_')
           lines.append(f'{env_key}={value}')
       return '\n'.join(lines)


   def extract_hostnames(host_list, separator=','):
       return separator.join(host_list)


   class FilterModule(object):
       def filters(self):
           return {
               'mask_string': mask_string,
               'to_env_format': to_env_format,
               'extract_hostnames': extract_hostnames,
           }
   EOF"
   ```

2. Write a playbook that uses all three custom filters and run it against localhost:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab032-plugins.yml << 'EOF'
   ---
   - name: Custom Plugins Practice
     hosts: localhost
     gather_facts: false

     vars:
       secret_key: \"AbCdEf123456!@#\"
       app_config:
         host: localhost
         port: \"5432\"
         database: mydb
         pool_size: \"10\"
       servers:
         - web1.example.com
         - web2.example.com
         - db1.example.com

     tasks:
       - name: Mask the secret key
         ansible.builtin.debug:
           msg: \"Secret key: {{ secret_key | mask_string }}\"

       - name: Convert config to env format
         ansible.builtin.debug:
           msg: \"{{ app_config | to_env_format('APP_') }}\"

       - name: Extract hostnames
         ansible.builtin.debug:
           msg: \"Servers: {{ servers | extract_hostnames }}\"

       - name: Built-in filter examples
         ansible.builtin.debug:
           msg:
             - \"Uppercase: {{ 'hello' | upper }}\"
             - \"Sorted: {{ [3,1,2] | sort }}\"
             - \"Default: {{ undefined_var | default('fallback') }}\"
   EOF
   ansible-playbook lab032-plugins.yml"
   ```

3. Create a callback plugin that saves a JSON execution report to `/tmp/ansible-report.json` after each playbook run:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && mkdir -p callback_plugins && cat > callback_plugins/json_report.py << 'EOF'
   from __future__ import absolute_import, division, print_function
   __metaclass__ = type

   import json
   import datetime
   from ansible.plugins.callback import CallbackBase

   DOCUMENTATION = '''
     name: json_report
     short_description: Save JSON execution report
   '''


   class CallbackModule(CallbackBase):
       CALLBACK_VERSION = 2.0
       CALLBACK_TYPE = 'notification'
       CALLBACK_NAME = 'json_report'
       CALLBACK_NEEDS_ENABLED = True

       def __init__(self):
           super().__init__()
           self.report = {
               'start_time': datetime.datetime.now().isoformat(),
               'plays': [],
               'summary': {}
           }

       def v2_playbook_on_stats(self, stats):
           for host in stats.processed.keys():
               s = stats.summarize(host)
               self.report['summary'][host] = s
           self.report['end_time'] = datetime.datetime.now().isoformat()
           with open('/tmp/ansible-report.json', 'w') as f:
               json.dump(self.report, f, indent=2)
           self._display.display('JSON report saved to /tmp/ansible-report.json')
   EOF"

   # Enable the callback in ansible.cfg
   docker exec ansible-controller sh -c "cd /labs-scripts && grep -q 'callbacks_enabled' ansible.cfg 2>/dev/null || echo '[defaults]
   callbacks_enabled = json_report' >> ansible.cfg"

   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --check 2>/dev/null || ansible -m ping all"
   docker exec ansible-controller sh -c "cat /tmp/ansible-report.json 2>/dev/null | python3 -m json.tool | head -30"
   ```

4. Create a lookup plugin that reads key=value pairs from a custom config file and makes them available as variables:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && mkdir -p lookup_plugins && cat > lookup_plugins/kv_config.py << 'EOF'
   from __future__ import absolute_import, division, print_function
   __metaclass__ = type

   from ansible.plugins.lookup import LookupBase
   from ansible.errors import AnsibleError

   DOCUMENTATION = '''
     name: kv_config
     short_description: Read key=value config files
   '''


   class LookupModule(LookupBase):
       def run(self, terms, variables=None, **kwargs):
           results = []
           for term in terms:
               try:
                   config = {}
                   with open(term, 'r') as f:
                       for line in f:
                           line = line.strip()
                           if line and not line.startswith('#') and '=' in line:
                               key, value = line.split('=', 1)
                               config[key.strip()] = value.strip()
                   results.append(config)
               except IOError as e:
                   raise AnsibleError(f'Cannot read config file {term}: {e}')
           return results
   EOF"

   # Create a test config file and playbook
   docker exec ansible-controller sh -c "cat > /tmp/app.cfg << 'EOF'
   # Application configuration
   app_name=myapp
   app_port=8080
   db_host=localhost
   db_name=appdb
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab032-lookup.yml << 'EOF'
   ---
   - name: Custom Lookup Plugin Test
     hosts: localhost
     gather_facts: false

     tasks:
       - name: Load config using custom lookup
         ansible.builtin.set_fact:
           app_config: \"{{ lookup('kv_config', '/tmp/app.cfg') }}\"

       - name: Show loaded config
         ansible.builtin.debug:
           msg:
             - \"App: {{ app_config.app_name }}\"
             - \"Port: {{ app_config.app_port }}\"
             - \"DB: {{ app_config.db_host }}/{{ app_config.db_name }}\"
   EOF
   ansible-playbook lab032-lookup.yml"
   ```

5. Write a vars plugin that automatically loads encrypted variable files if they exist alongside unencrypted ones:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab032-vars-plugin-demo.yml << 'EOF'
   ---
   # Demonstration of built-in host_group_vars plugin behavior
   # The host_group_vars plugin is enabled by default and loads group_vars/ and host_vars/
   - name: Vars Plugin Demo
     hosts: localhost
     gather_facts: false

     tasks:
       - name: Show which vars plugins are active
         ansible.builtin.command:
           cmd: ansible-doc -t vars -l
         register: vars_plugins
         changed_when: false

       - name: Display available vars plugins
         ansible.builtin.debug:
           var: vars_plugins.stdout_lines

       - name: Create a demo vars file loaded by host_group_vars
         ansible.builtin.copy:
           content: |
             # Loaded automatically by the host_group_vars plugin
             demo_plugin_var: \"loaded by vars plugin\"
             plugin_timestamp: \"{{ ansible_date_time.iso8601 | default('n/a') }}\"
           dest: /labs-scripts/group_vars/all/plugin_demo.yml
           mode: \"0644\"
         delegate_to: localhost
   EOF
   ansible-playbook lab032-vars-plugin-demo.yml"
   ```

---

## 08. Summary

- Ansible has **10+ plugin types**; filter and lookup plugins are most commonly customized
- **Lookup plugins** retrieve data from external sources: `file`, `env`, `url`, `password`, `pipe`, `dig`
- **Filter plugins** transform data in Jinja2: `selectattr`, `map`, `groupby`, `combine`
- Custom filter plugins go in the `filter_plugins/` directory next to your playbook
- **Callback plugins** change output format - use `stdout_callback = yaml` for better readability
- The `profile_tasks` callback shows per-task timing, which is great for performance optimization
