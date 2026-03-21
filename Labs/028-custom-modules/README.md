---
# Custom Modules

* In this lab we write custom Ansible modules in Python to extend Ansible's capabilities for tasks that built-in modules don't cover.
* Custom modules follow the same conventions as built-in modules and integrate seamlessly.

## What will we learn?

- Anatomy of an Ansible module
- Using the `AnsibleModule` helper class
- Writing idempotent modules with proper error handling
- Testing modules with `pytest`

---

## Prerequisites

- Complete [Lab 009](../009-roles/README.md#usage) in order to have working Ansible roles.

---

## 01. When to Write a Custom Module

- No existing module covers your use case
- Third-party API integration not covered by collections
- Organization-specific business logic
- Wrapping a proprietary CLI tool

Before writing a module, check:

- Ansible built-in modules
- Ansible Galaxy collections
- `command`/`shell` + `changed_when`/`register` (often sufficient!)

---

## 02. Module File Locations

```txt
# In a playbook directory
library/
└── my_module.py

# In a role
roles/
└── myrole/
    └── library/
        └── my_module.py

# System-wide
/usr/share/ansible/plugins/modules/

# ansible.cfg
[defaults]
library = ./library
```

---

## 03. Anatomy of an Ansible Module

```python
#!/usr/bin/python3
# -*- coding: utf-8 -*-

# Required: Module documentation
DOCUMENTATION = r'''
---
module: my_module
short_description: A custom module example
description:
  - This module demonstrates how to write a custom Ansible module.
  - It creates a file with specific content.
version_added: "1.0.0"
author:
  - Your Name (@yourhandle)
options:
  path:
    description:
      - Path to the file to create or manage.
    required: true
    type: str
  content:
    description:
      - Content to write to the file.
    required: false
    type: str
    default: ""
  state:
    description:
      - Whether the file should be present or absent.
    required: false
    type: str
    choices: [present, absent]
    default: present
'''

EXAMPLES = r'''
- name: Create a file with content
  my_module:
    path: /tmp/myfile.txt
    content: "Hello, Ansible!"
    state: present

- name: Remove a file
  my_module:
    path: /tmp/myfile.txt
    state: absent
'''

RETURN = r'''
path:
  description: Path of the managed file
  type: str
  returned: always
changed:
  description: Whether the file was changed
  type: bool
  returned: always
'''

# Standard imports
import os
from ansible.module_utils.basic import AnsibleModule


def run_module():
    # Define the module's argument spec
    module_args = dict(
        path=dict(type='str', required=True),
        content=dict(type='str', required=False, default=''),
        state=dict(type='str', required=False, default='present',
                   choices=['present', 'absent'])
    )

    # Initialize the result
    result = dict(
        changed=False,
        path='',
        message=''
    )

    # Create the AnsibleModule object
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True    # Support --check mode
    )

    # Extract parameters
    path = module.params['path']
    content = module.params['content']
    state = module.params['state']

    result['path'] = path

    # Handle absent state
    if state == 'absent':
        if os.path.exists(path):
            if not module.check_mode:   # Don't actually delete in check mode
                os.remove(path)
            result['changed'] = True
            result['message'] = f"File {path} removed"
        else:
            result['message'] = f"File {path} does not exist (nothing to do)"
        module.exit_json(**result)

    # Handle present state
    file_exists = os.path.exists(path)
    current_content = ''

    if file_exists:
        with open(path, 'r') as f:
            current_content = f.read()

    # Only write if content changed
    if not file_exists or current_content != content:
        if not module.check_mode:
            try:
                with open(path, 'w') as f:
                    f.write(content)
            except IOError as e:
                module.fail_json(msg=f"Failed to write file: {str(e)}", **result)
        result['changed'] = True
        result['message'] = f"File {path} written"
    else:
        result['message'] = f"File {path} is up to date"

    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()
```

---

## 04. Using `AnsibleModule` Features

```python
# Fail with a message
module.fail_json(msg="Something went wrong", **result)

# Exit successfully
module.exit_json(**result)

# Run a command (handles errors and output)
rc, stdout, stderr = module.run_command('some_command --arg value')

# Get temporary file path
tmp_file = module.tmpdir

# Skip real changes in check mode
if module.check_mode:
    result['changed'] = True
    module.exit_json(**result)

# Diff support
if module.diff:
    result['diff'] = {
        'before': current_content,
        'after': new_content
    }
```

---

## 05. More Realistic Module: Service Health Check

```python
#!/usr/bin/python3

DOCUMENTATION = r'''
module: service_health
short_description: Check if a service HTTP endpoint is healthy
'''

EXAMPLES = r'''
- name: Check nginx health
  service_health:
    url: http://localhost:80/health
    expected_status: 200
    timeout: 10
'''

RETURN = r'''
status_code:
  description: HTTP status code
  type: int
  returned: always
healthy:
  description: Whether the service is healthy
  type: bool
  returned: always
'''

import urllib.request
import urllib.error
from ansible.module_utils.basic import AnsibleModule


def run_module():
    module_args = dict(
        url=dict(type='str', required=True),
        expected_status=dict(type='int', default=200),
        timeout=dict(type='int', default=10),
    )

    result = dict(changed=False, status_code=None, healthy=False)

    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    url = module.params['url']
    expected = module.params['expected_status']
    timeout = module.params['timeout']

    try:
        response = urllib.request.urlopen(url, timeout=timeout)
        result['status_code'] = response.status
        result['healthy'] = (response.status == expected)
    except urllib.error.HTTPError as e:
        result['status_code'] = e.code
        result['healthy'] = (e.code == expected)
    except Exception as e:
        module.fail_json(msg=f"Could not connect to {url}: {str(e)}", **result)

    if not result['healthy']:
        module.fail_json(
            msg=f"Service unhealthy: got {result['status_code']}, expected {expected}",
            **result
        )

    module.exit_json(**result)


def main():
    run_module()

if __name__ == '__main__':
    main()
```

---

## 06. Testing Your Module

```python
# tests/test_my_module.py
import pytest
import json
import sys
sys.path.insert(0, '../library')

from unittest.mock import patch, MagicMock
import my_module

def test_module_creates_file(tmp_path):
    """Test that the module creates a file"""
    test_file = str(tmp_path / "test.txt")

    set_module_args({
        'path': test_file,
        'content': 'test content',
        'state': 'present'
    })

    with pytest.raises(SystemExit) as e:
        my_module.main()

    result = json.loads(e.value.args[0])  # simplified
    assert result['changed'] == True

def set_module_args(args):
    """Helper to set module arguments"""
    from ansible.module_utils import basic
    basic._ANSIBLE_ARGS = json.dumps({'ANSIBLE_MODULE_ARGS': args}).encode()
```

```sh
# Run tests
pytest tests/test_my_module.py -v
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 07. Hands-on

1. Create the `library/` directory inside the controller container.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && mkdir -p library"
   ```

2. Write a custom module `write_ini.py` that writes key=value pairs to an INI configuration file.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cat > /labs-scripts/library/write_ini.py << 'EOF'
   #!/usr/bin/python3
   \"\"\"Custom module: Write an INI-style configuration file.\"\"\"

   DOCUMENTATION = r'''
   module: write_ini
   short_description: Write key=value pairs to a config file
   '''
   EXAMPLES = r'''
   - write_ini:
       path: /etc/myapp/config.ini
       section: server
       options:
         port: \"8080\"
         host: localhost
   '''
   RETURN = r'''
   path:
     description: Path written
     type: str
     returned: always
   '''

   import os
   import configparser
   from ansible.module_utils.basic import AnsibleModule


   def run_module():
       module_args = dict(
           path=dict(type='str', required=True),
           section=dict(type='str', required=True),
           options=dict(type='dict', required=True),
       )
       result = dict(changed=False, path='')
       module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

       path = module.params['path']
       section = module.params['section']
       options = module.params['options']
       result['path'] = path

       config = configparser.ConfigParser()
       if os.path.exists(path):
           config.read(path)

       if not config.has_section(section):
           config.add_section(section)

       changed = False
       for key, value in options.items():
           if not config.has_option(section, key) or config.get(section, key) != str(value):
               config.set(section, key, str(value))
               changed = True

       if changed:
           if not module.check_mode:
               os.makedirs(os.path.dirname(path), exist_ok=True)
               with open(path, 'w') as f:
                   config.write(f)
           result['changed'] = True

       module.exit_json(**result)


   def main():
       run_module()

   if __name__ == '__main__':
       main()
   EOF"
   ```

3. Create a playbook `lab028-custom.yml` that uses the `write_ini` module and run it.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cat > /labs-scripts/lab028-custom.yml << 'EOF'
   ---
   - name: Custom Module Test
     hosts: all
     gather_facts: false

     tasks:
       - name: Write config using custom module
         write_ini:
           path: /tmp/custom-config.ini
           section: server
           options:
             port: \"8080\"
             host: localhost
             debug: \"false\"

       - name: Show the config
         ansible.builtin.command:
           cmd: cat /tmp/custom-config.ini
         register: config_out
         changed_when: false

       - name: Print config
         ansible.builtin.debug:
           var: config_out.stdout_lines
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab028-custom.yml"
   ```

4. Run the playbook a second time and confirm that `changed=false` (idempotency check).

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab028-custom.yml"

   ### Output
   # The write_ini task should report "changed=false" on the second run
   # because the config file already contains the correct values
   ```

---

## 08. Summary

- Ansible modules are **Python scripts** using `AnsibleModule` from `ansible.module_utils.basic`
- Always support **check mode** by checking `module.check_mode` before making changes
- Use `module.exit_json()` for success and `module.fail_json()` for errors
- Modules must be **idempotent** - compare current state to desired state before changing
- Place modules in `library/` next to your playbook or in `roles/<role>/library/`
