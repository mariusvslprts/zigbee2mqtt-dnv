# Zigbee2MQTT + Dynamic Node.js version management

This project helps you to integrate [Node Version Manager (NVM)](https://github.com/nvm-sh) into Zigbee2MQTT for a dynamic Node.js version management on debian based systems.

## About

This project allows you to integrate the Node Version Manager (NVM) project into your existing Zigbee2MQTT installation without loosing the avability to update Zigbee2MQTT in the future. 

You will not longer need to take care about having the right Node.js installed on your system in order to run Zigbee2MQTT propperly. 


## Requirements 

- Zigbee2MQTT (^2.6.x)

## Installation

1. **Node Version Manager (NVM) installation**

    For detailed instructions on how to install Node Version Manager (NVM) check the project repository:
    https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating

    Once you installed NVM make shure to add the [default-packges](./src/nvm/default-packages) file to your NVM install directory. 

    This ensures [pnpm](https://pnpm.io/), a fast and disk space efficient package manager alternative to npm which is used by Zigbee2MQTT, gets installed everytime NVM installs 
    a new Node.js version  *(See: https://github.com/nvm-sh/nvm?tab=readme-ov-file#default-global-packages-from-file-while-installing)*

2. **Git repository modification**

    You will need to add some custom excludes to your local Git repository in order to keep Zigbee2MQTT updateable.

    - Open `.git/info/exclude` inside of your Zigbee2MQTT installation directory in a editor or IDE of your choice. 

    - Add the following lines at the bottom
        ```
        bin/main.sh
        bin/update.sh
        ```
3. **Custom shell scripts integration**
 
    Create a `bin/` directory inside of your Zigbee2MQTT directory. 
    
    Copy the files from the repository `src/zigbee2mqtt/bin/` directory into your folder. 

    Ensure file ownership & permissions by running the following commands:

    ```bash 
    sudo chown -R $USER bin/
    sudo chgrp -R $USER bin/
    sudo chmod 775 bin/*.sh
    ```

4. **Systemd service update**

    There are some small modifications required in order to use NVM while running Zigbee2MQTT as a service. 

    - Stop the Zigbee2MQTT service 
        ```bash
        sudo systemctl stop zigbee2mqtt.service
        ```
    - Replace the contents of your current service file with the one inside `/src/zigbee2mqtt/zigbee2mqtt.service`
    - Reload the systemctl daemon 
        ```bash 
        sudo systemctl daemon-reload
        ````
    - Start the Zigbee2MQTT serice 
        ```bash 
        sudo systemctl start zigbee2mqtt.service
        ````

## Usage

### Run Zigbee2MQTT 

Execute the custom `main.sh` script in order to run Zigbee2MQTT: 

```bash
cd /opt/zigbee2mqtt
./bin/main.sh
```

### Update Zigbee2MQTT 

Execute the custom `update.sh` script in order to update Zigbee2MQTT to the latest Version:

```bash
cd /opt/zigbee2mqtt
./bin/update.sh
``` 
This script ensures NVM is loaded, and uses the propper Node.js version while updating Zigbee2MQTT

## Roadmap 

- Replacing nvm with phpm
- Install script to automate the setup process
- Ansible Playbook or Role   
