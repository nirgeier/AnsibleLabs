![](../../resources/ansible_logo.png)

<a href="https://stackoverflow.com/users/1755598"><img src="https://stackexchange.com/users/flair/1951642.png" width="208" height="58" alt="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites" title="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites"></a>

<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/004-playbooks.yaml"><img src="https://img.shields.io/github/actions/workflow/status/nirgeier/AnsibleLabs/004-playbooks.yaml?branch=main&style=flat" style="height: 20px;"></a> ![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier) [![Linkedin Badge](https://img.shields.io/badge/-nirgeier-blue?style=flat&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/nirgeier/)](https://www.linkedin.com/in/nirgeier/) [![Gmail Badge](https://img.shields.io/badge/-nirgeier@gmail.com-fcc624?style=plastic&logo=Gmail&logoColor=red&link=mailto:nirgeier@gmail.com)](mailto:nirgeier@gmail.com) [![Outlook Badge](https://img.shields.io/badge/-nirg@codewizard.co.il-fcc624?style=plastic&logo=microsoftoutlook&logoColor=blue&link=mailto:nirg@codewizard.co.il)](mailto:nirg@codewizard.co.il)

---
- [Lab 011 - `Jinja2` Templating](#lab-011---jinja2-templating)
  - [01. Creating Jinja2 Templates](#01-creating-jinja2-templates)
  - [02. Using Templates in Playbooks](#02-using-templates-in-playbooks)
  - [03. Using Conditional Statements](#03-using-conditional-statements)
  - [04. Looping with `Jinja2`](#04-looping-with-jinja2)
  - [05. Filters and Functions](#05-filters-and-functions)
  - [**Summary**](#summary)

---

# Lab 011 - `Jinja2` Templating

- In our day to day job we come across dozens of **configuration files** in many different formats.
- What happens if we need to configure different environments, each with his own values? Should we duplicate the same file for each?
- Here comes `Jinja2` templates for the rescue! It helps us template our configuration files to be used with different values and reduce duplication.
- `Jinja2` is a powerful templating engine integrated into Ansible, used commonly in python projects.
- Templates allow dynamic configuration file generation based on variables and facts.
- `Jinja2` can be used with conditionals and loops and can even perform filters and functions on our values!

## 01. Creating Jinja2 Templates

- Create a Jinja2 template file by appending `.j2` to our base config file, for example, `nginx.conf.j2`:

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

## 02. Using Templates in Playbooks

- Integrate Jinja2 templates using the `ansible.builtin.template` module:

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

## 03. Using Conditional Statements

- Jinja2 supports conditional logic to dynamically alter configurations:

  ```jinja2
  {% if ansible_distribution == 'Ubuntu' %}
  User ubuntu;
  {% elif ansible_distribution == 'CentOS' %}
  User centos;
  {% else %}
  User default;
  {% endif %}
  ```

## 04. Looping with `Jinja2`

- Iterate over lists or dictionaries easily:

  ```jinja2
  # hosts file
  {% for host in groups['web_servers'] %}
  {{ hostvars[host]['ansible_default_ipv4']['address'] }} {{ host }}
  {% endfor %}
  ```

## 05. Filters and Functions

- `Jinja2` includes built-in filters to transform data:

  ```jinja2
  # Convert text to uppercase
  ServerName {{ domain_name | upper }}

  # Default filter for fallback values
  Listen {{ custom_port | default(8080) }}
  ```

---

## **Summary**

🔹 **Jinja2** enables dynamic template generation with **variables and facts**.  
🔹 Templates help manage **complex configurations** simply and efficiently.  
🔹 Use **conditional statements and loops** for highly dynamic setups.  
🔹 Built-in filters enhance the **manipulation of data** directly within templates.

---

<img src="../../resources/practice.png" width="250px">
<br/>

- Create a Jinja2 template for generating a dynamic `/etc/motd` (Message of the Day) file with a personal message (ensure is enabled first).
- The code can be found in lab 009
- **Bonus:** Use facts to display useful information about OS distribution, IP address, and current hostname dynamically when logging in.

---

<!--- Labs Navigation Start -->  
<p style="text-align: center;">  
    <a href="/Labs/010-loops-and-conditionals">:arrow_backward: /Labs/010-loops-and-conditionals</a>
    &emsp;<a href="/Labs">Back to labs list</a>
    &emsp;<a href="/Labs/011-jinja-templating">/Labs/011-jinja-templating :arrow_forward:</a>
</p>
<!--- Labs Navigation End -->
