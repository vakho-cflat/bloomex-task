# bloomex-tasks
## iptables task
iptables rules are located at `iptables_task` directory.
make sure to restore `iptables_v4.conf` in iptables, place `01-iptables_logs.conf` in `/etc/rsyslog.d/` directory and restart rsyslog so logging can work as intended.
  
<br>

## ansible task
 \
This ansible project includes 2 roles, nginx (1.18) and php7.4-fpm. \
Each role has variables as customization options. 
These variables are defined in "roles/defauts/main.yml" with their default values.  
This repo contains sample playbooks for both roles, where variables can be added or removed. 
Also, including sample host file, where ansible host address can be easily replaced and running command:  
`ansible-playbook -i ansible-hosts.ini nginx_playbook.yml` \
would result in nginx installation with https on and php-fpm installed.
 

 \
**nginx** \
nginx role has following variables:

`www_dir` - web directory \
`domain` - domain of the website/service \
`server_name` - server name \
`php7_4_socket_unix` - nginx forwads fpm request to this socket \
`enable_https` - selfsigned certificate generation. this seting controls https as well \
`ssl_location` - location where generated `.key` and `.crt` should be saved and referenced by nginx 
 
 
 \
nginx role `nginx.conf` variables. self-exlanatory: 

`nginx_vhost_config` \
`nginx_worker_processes` \
`nginx_user` \
`worker_connections` 

\
installation of php7.4-fpm with nginx role

`install_php7_4` - **this variable controls if php7.4-fpm role will be installed along with nginx. recommended way of installation.** 


\
**php7.4-fpm** \
role php7.4-fpm accepts following variables: \
 \
`php_fpm_error_log` - defines error log location in `php-fpm.conf` \
`php7_4_socket` - defines where php7.4-fpm socket runs \
`max_worker_children` - number of maximum worker processes \
`php7_4_error_log_wwwconf` - defines error log location AND state in `www.conf` file \
`php7_4_memory_limit_wwwconf` - defines memory limit in `www.conf` file \
`webroot` - defines webroot directory, where `index.php` file should be placed  
  
<br>
  
## backup script task
Added backup script in `backup` directory.  
Description coming soon

This script performs file transfer from remote server.  
Script accept following arguments:  
`-t` or `--type` - type of backup, either `full` or `inc`  
`-u` or `--user` - username, which will be used for remote connection   
`-s` or `--source` - source directory path  
`-d` or `--destination` - local destination directory path  
`-i` or `--ip` - remote server ip address  
`-D` or `--debug` - flag to enable debug mode  
`-h` or `--help` - flag to display help  


**The Script**
- The script is using rsync to copy data in encrypted (`-e ssh`) and compressed (`-z`) manner.  
- Allows changing required parameters, as described above.  
- Creates logrotate configuration file `bloomex_backup` (if it doesn't already exist) within `/etc/logrotate.d/` to rotate logs in `fullOld` and `incOld` directories. Configuration paramateres can be added or removed from script, according to requirments.  
- Creates 2 directories for full and incremental backup types: `full` and `inc`, where most recent files are located. Previous versions of these files are moved to 2 additional directories: `fullOld` and `incOld`, where these files are rotated by logrotate.  

I have included additional compression and archiving functionality for the files in the **Old* directories. This addition serves to demonstrate my capability to perform both tasks within the script, especially since the task description regarding compression was somewhat unclear to me.  
  

