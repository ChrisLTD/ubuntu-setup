For Ubuntu 14.04

# A. Setup Digital Ocean Droplet

# B. SSH into Droplet and setup non-root user

*Shamelessly stolen from [ThoughtBot](https://robots.thoughtbot.com/remote-development-machine)*

1. First, you will need to connect to your droplet via SSH. For now, just open up your terminal app and type: `ssh root@<IP-ADDRESS-OF-DROPLET>` (substituting the IP-ADDRESS that you noted before).
*Note: you will need to respond with ‘yes’ to allow your droplet’s IP address to be added to the list of known hosts on your machine.*

2. Before doing any kind of configuration on the droplet, let’s first create a user that you can use other than root. Type in `adduser USER_NAME` (substituting USER_NAME with the username of your choice).
*Note: you will also need to provide a new password for this user, and any details that you wish to add.*

3. Now that we have created a new user, let’s make sure that we lock down sshd from allowing that user to connect with a password and continue to use the same SSH key to connect. First we will copy the key from the root user to the newly created user. Type: `mkdir /home/USER_NAME/.ssh && cat ~/.ssh/authorized_keys >> /home/USER_NAME/.ssh/authorized_keys` (remember to substitute USER_NAME with the username that you chose earlier).

4. Next, we need to chown that directory that we just created so that the USER_NAME can write to it later. Execute this command: `chown -R USER_NAME:USER_NAME /home/USER_NAME/.ssh`

5. Since we now have the SSH key authorized for the new user, let’s lock down sshd from allowing any user to authenticate with a password. Open `/etc/ssh/sshd_config` with your editor of choice and change `#PasswordAuthentication yes` to `PasswordAuthentication no`.

6. Note: once you have saved this change, execute `restart ssh` to reload the configuration.

7. Now we can add this new user to the `/etc/sudoers` file. This will allow this user to execute the sudo command. Replicate the line `root ALL=(ALL:ALL) ALL`, replacing root with your new username, and save the file. (If you’re in vim, you’ll need to save with :w! since the file is readonly.)

8. Log out of your SSH session and log in again, but this time use your new username: `ssh USER_NAME@<IP-ADDRESS-OF-DROPLET>`

# C. Run this command:

`bash <(wget -qO- https://github.com/ChrisLTD/ubuntu-setup/raw/master/ubuntu-setup.sh)
2>&1 | tee ~/init.log`

# D. Enjoy