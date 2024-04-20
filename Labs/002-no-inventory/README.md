![](../../resources/ansible_logo.png)

<a href="https://stackoverflow.com/users/1755598"><img src="https://stackexchange.com/users/flair/1951642.png" width="208" height="58" alt="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites" title="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites"></a>

<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/002-no-inventory.yaml"><img src="https://img.shields.io/github/actions/workflow/status/nirgeier/AnsibleLabs/002-no-inventory.yaml?branch=main&style=flat" style="height: 20px;"></a> ![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier) [![Linkedin Badge](https://img.shields.io/badge/-nirgeier-blue?style=flat&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/nirgeier/)](https://www.linkedin.com/in/nirgeier/) [![Gmail Badge](https://img.shields.io/badge/-nirgeier@gmail.com-fcc624?style=plastic&logo=Gmail&logoColor=red&link=mailto:nirgeier@gmail.com)](mailto:nirgeier@gmail.com) [![Outlook Badge](https://img.shields.io/badge/-nirg@codewizard.co.il-fcc624?style=plastic&logo=microsoftoutlook&logoColor=blue&link=mailto:nirg@codewizard.co.il)](mailto:nirg@codewizard.co.il)

---

# Lab 002 - No inventory example

- [Lab 002 - No inventory example](#lab-002---no-inventory-example)
    - [01. "Clear" the inventory](#01-clear-the-inventory)
    - [01.01. Create the `inventory` file](#0101-create-the-inventory-file)
    - [01.02. No inventory invocation](#0102-no-inventory-invocation)

### 01. "Clear" the inventory

### 01.01. Create the `inventory` file

- The inventory configuration we will use for the labs:
    ```ini
    ### $RUNTIME_FOLDER/labs-scripts/inventory
    ###
    ### List of servers which we want ansible to connect to
    ### The names are defined in the docker-compose
    ###

    [servers]
    # No server will be defined 
    ```

### 01.02. No inventory invocation

- Once all is ready lets check is the controller can connect to the servers with the using `ping`
    
    ```sh
    # Ping the servers and check that they are "alive"
    docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping"

    ## Output
    ## -------------------------------------------------------------------------------
    [WARNING]: provided hosts list is empty, only localhost is available. Note that
    the implicit localhost does not match 'all'
    ```

---

<p style="text-align: center;">
    <a href="/Labs/001-verify-ansible/">
    :arrow_backward: 001-verify-ansible
    </a>
    &emsp;
    <a href="/Labs">
    Back to labs list
    </a>    
    &emsp;
    <a href="/Labs/003-modules">
    003-modules :arrow_forward:
    </a>
</p>