- Create user named demo<index> for each machine
- Verify that the user was created
- Create an ansible inventory with the username in the configuration
  ```sh
  <hostname>    ansible_host=<hostname> ansible_ssh_user=<user>
  ```