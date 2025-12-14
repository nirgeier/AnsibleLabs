<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-011.yaml" target="_blank">
  <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-011.yaml/badge.svg" alt="Build Status">
</a>

---


# Lab 011 - `Jinja2` Templating

- During our day to day job, we come across dozens of **configuration files**, set in many different formats.
- What happens if we need to configure different environments, each with its own values? Should we duplicate the same file for each one?
- This is where `Jinja2` templates come to the rescue! `Jinja2` helps us template our configuration files to be used with different values and reduce duplications.
- `Jinja2` is a powerful templating engine integrated into Ansible, used commonly in python projects.
- Templates allow dynamic configuration file generation, based on variables and facts.
- `Jinja2` can be used with conditionals and loops and can even perform filters and functions on our values!

## 01. Creating Jinja2 templates

- Create a `Jinja2` template file by appending a `.j2` suffix to our base config filename. For example, `nginx.conf.j2`:

  ```jinja2
  # Example

  events {}
  http {
    server {
      listen {{ web_port }};
      server_name {{ domain_name }};

      location / {
        proxy_pass http://{{ backend_ip }}:{{ backend_port }};
      }
    }
  }
  ```

---

## 02. Using templates in playbooks

- Integrate `Jinja2` templates using the `ansible.builtin.template` module:

  ```yaml
  ---
  - hosts: web_servers
    vars:
      web_port: 80
      domain_name: example.com
      backend_ip: 192.168.10.10
      backend_port: 8080
    tasks:
      - name: Deploy Nginx Configuration
        ansible.builtin.template:
          src: config.j2
          dest: /etc/nginx/conf.d/site.conf
        notify: Restart Nginx

    handlers:
      - name: Restart Nginx
        ansible.builtin.service:
          name: nginx
          state: restarted
  ```

---

## 03. Using conditional statements

- `jinja2` supports conditional logic to dynamically alter configurations:

  ```jinja2
  {% if ansible_distribution == 'Ubuntu' %}
  User ubuntu;
  {% elif ansible_distribution == 'CentOS' %}
  User centos;
  {% else %}
  User default;
  {% endif %}
  ```

---

## 04. Looping with `Jinja2`

- `Jinja2` makes it easy to iterate over lists or dictionaries:

  ```jinja2
  # hosts file
  {% for host in groups['web_servers'] %}
  {{ hostvars[host]['ansible_default_ipv4']['address'] }} {{ host }}
  {% endfor %}
  ```

---

## 05. Filters and functions

- `Jinja2` includes built-in filters to transform data:

  ```jinja2
  # Convert text to uppercase
  ServerName {{ domain_name | upper }}

  # Default filter for fallback values
  Listen {{ custom_port | default(8080) }}
  ```

---

## 06. **Summary**

🔹 `Jinja2` enables dynamic template generation with **variables and facts**.  
🔹 Templates help manage **complex configurations** in a more simple and efficient manner.  
🔹 Use **conditional statements and loops** for highly dynamic setups.  
🔹 Built-in filters enhance the **manipulation of data** directly within templates.

---
<img src="../assets/images/practice.png" alt="Practice" width="800"/>
<br/>


## 07. Hands-on


- Create a `Jinja2` template for generating a dynamic `/etc/motd` (**"Message of the Day"**) file, containing a personal message (ensure first that it is enabled).
- The relevant code can be found in lab 009.
- **Bonus:** Use facts to display useful information about OS distribution, IP address and current hostname dynamically when logging in.
