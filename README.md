| :warning: This has not been fully tested with Docker v28 yet. v28 has some serious issues and some big changes on networking... I suggest for now you limit updates to v27.5.1 and below. |
| --- |


# synology-docker
| :page_facing_up: Originally forked from [telnetdoogie/synology-docker](https://github.com/telnetdoogie/synology-docker) |
| --- |


<!-- Tagline -->
<p align="center">
    <b>An Unofficial Script to Update or Restore Docker Engine and Docker Compose on Synology NAS</b>
    <br />
</p>


<!-- Badges -->
<p align="center">
    <a href="https://github.com/mrkhachaturov/synology-docker/commits/master" alt="Last commit">
        <img src="https://img.shields.io/github/last-commit/mrkhachaturov/synology-docker.svg" />
    </a>
    <a href="https://github.com/mrkhachaturov/synology-docker/issues" alt="Issues">
        <img src="https://img.shields.io/github/issues/mrkhachaturov/synology-docker.svg" />
    </a>
    <a href="https://github.com/mrkhachaturov/synology-docker/pulls" alt="Pulls">
        <img src="https://img.shields.io/github/issues-pr-raw/mrkhachaturov/synology-docker.svg" />
    </a>
    <a href="https://github.com/mrkhachaturov/synology-docker/blob/master/LICENSE" alt="License">
        <img src="https://img.shields.io/github/license/mrkhachaturov/synology-docker.svg" />
    </a>
</p>


## About
| :warning: The repository 'Synology-Docker' is not supported by Synology and can potentially lead to malfunctioning of your NAS. Use this script at your own risk. Please keep a backup of your files. |
| --- |

| :warning: If you're using the Nvidia driver on your synology, you may need to re-start the Nvidia driver, or re-run `nvidia-ctk runtime configure` to re-add the nvidia runtime after each run of this script in order for the driver to get re-added to docker. |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

| :exclamation: Portainer Users - Portainer currently has an [issue](https://github.com/portainer/portainer/issues/10462) where it persists the first-used logging driver alongside container definitions. You will have to completely recreate (or duplicate and edit) containers created in portainer to use the `local` log driver. It would be best to do that with all of your containers BEFORE running this update. Portainer has created some challenges for users migrating from one log driver to another. It also has created problems with networks and port definitions not translating... You will have to spend way more time re-creating and troubleshooting containers after this update if you're trying to use portainer. So... if you're using portainer and you use this update... you have been warned... change the container loggers FIRST and validate they've all been changed by using the `./syno_docker_list_containers.sh` script.
| --- |

[Synology][synology_url] is a popular manufacturer of Network Attached Storage (NAS) devices that supports Docker on selected [models]

[synology_docker](https://github.com/telnetdoogie/synology-docker/) is a POSIX-compliant shell script designed to update Docker Engine and Docker Compose on your NAS to the latest or a specified version.

## Getting this script on your NAS
Deployment of *Synology-Docker* is a matter of cloning the GitHub repository. Login to your NAS terminal via SSH first.
Assuming you are in the working folder of your choice (assume `/volume1/homes/admin`), clone the repository files.
Git automatically creates a new folder `synology-docker` and copies the files to this directory. Once the repo has been cloned,
change your current folder to the location of the script. (`cd synology-docker`) before running the script.

```console
git clone https://github.com/mrkhachaturov/synology-docker.git
cd synology-docker
```

## Recommended Update Steps for "First Time" upgrade

| :exclamation: Please Note: recommended update method has changed... I've attempted to lay out new instructions to make this smoother. Deal with loggers for containers FIRST and your life will be so much easier :)
| --- |

To ensure a smooth update, it is highly recommended to follow these steps in order:

1. **Update the logger** to replace Synology's default log driver (`db`) with the `local` log driver. Running this step before anything else will make for a much smoother transition.
   ```console
   sudo ./syno_docker_update.sh logger
   ```
   This script will update the `dockerd.json` file and will make the `local` logger default. It will then restart docker on your synology. 
   After restarting (all containers should come back up) you can identify which containers are using the `db` log driver by running:
   ```console
   ./syno_docker_list_containers.sh
   ```
   This will give output similar to the following:
   ```console
   Container            Compose_Location                                       Logger
   -------------------  ------------------------------------------------------ -------
   /jetbrains_postgres  !---not_managed_by_compose---!                         local
   /transmission        /volume1/docker/downloaderstack_vpn/docker-compose.yml db
   /dozzle              /volume1/docker/dozzle/docker-compose.yml              db
   /flaresolverr        /volume1/docker/flaresolverr/docker-compose.yml        db
   /inadyn              /volume1/docker/inadyn/docker-compose.yml              db
   /iPerf3              /volume1/docker/iPerf/docker-compose.yml               db
   /jellyfin            /volume1/docker/jellyfin/docker-compose.yml            db
   ```
   
2. **Recreate Containers one by one until they all show that they're using the `local` Logger**:
    - For **each** `docker-compose` managed container using the `db` log driver, recreate it with:
      ```console
      cd /volume1/docker/dozzle/  # change to the location of the compose project shown
      docker-compose up -d --force-recreate
      ```
   Any portainer managed containers here or containers managed any other way, you will need to understand how to recreate those so that they use the `local` logger. 
      Proceeding beyond this point with containers still showing as using the `db` logger will result in failures to start container after the update.
   - You can run `./syno_docker_list_containers.sh` as many times as you need to, to see which containers still need to switch to the `local` logger.
   - If the containers were created with a `docker run` command, this script will provide a suggestion about how to recreate that container after a `docker container rm` - 
   however, this is a 'best guess' and may not be 100% accurate.


3. Once all containers now use `local` logger, **run the `update` script** to update Docker and Docker Compose to the latest version.
   ```console
   sudo ./syno_docker_update.sh -d 27.5.1 -c 2.33.1 update  
   ```
   This command updates Docker to version `27.5.1` and Docker Compose to `2.33.1`. Feel free to use alternative versions. If you omit the `-d` and/or `-c` flags, the script will attempt to install the latest available versions — but be aware that Docker `v28` is not yet recommended due to ongoing issues.

4. If all containers were switched to the `local` logger before the update is complete, all containers should spin up as part of the update script.

## Updating AFTER the first time

Once you've successfully updated your docker version with this script, subsequent updates - to continue updating to newer `docker` versions - are very simple.

```console
cd synology-docker
git pull
sudo ./syno_docker_update.sh update
```

The biggest 'hump' is the initial shift to the `local` loggers. After the first successful update, each update beyond that is very simple.
The above commands will update to the latest version of docker if one is available, and will restart docker once the update is complete.

---

## Usage
*Synology-Docker* requires `sudo` rights. Use the following command to invoke *Synology-Docker* from the command line.

```console
sudo ./syno_docker_update.sh [OPTIONS] COMMAND
```



### Commands
*Synology-Docker* supports the following commands. 

| Command        | Argument  | Description |
|----------------|-----------|-------------|
| **`backup`**   |           | Create a backup of Docker binaries (including Docker Compose), `dockerd` configuration, and Synology's `start-stop-status` script |
| **`download`** | PATH      | Download Docker and Docker Compose binaries to *PATH* |
| **`install`**  | PATH      | Update Docker and Docker Compose from files on *PATH* |
| **`restore`**  |           | Restore Docker and Docker Compose from a backup |
| **`logger`**   |           | Update ONLY the logging-driver. This is a good first step to remove the dependency on the synology logger |
| **`update`**   |           | Update Docker and Docker Compose to a target version (creates a backup first) |


Under the hood, the six different commands invoke a specific workflow or sequence of steps. The below table shows the workflows and the order of steps for each of the commands.

| #  | Workflow step               | backup | download | install | restore | logger | update  |
|----|-----------------------------|--------|----------|---------|---------|--------|---------|
| A) | Download Docker binary      |        | Step 1   |         |         |        | Step 1  |
| B) | Download Compose binary     |        | Step 2   |         |         |        | Step 2  |
| C) | Extract files from backup   |        |          |         | Step 1  |        |         |
| D) | Stop Docker daemon          | Step 1 |          | Step 1  | Step 2  | Step 1 | Step 3  |
| E) | Backup current files        | Step 2 |          | Step 2  |         | Step 2 | Step 4  |
| F) | Extract downloaded binaries |        |          | Step 3  |         |        | Step 5  |
| G) | Restore Docker binaries     |        |          |         | Step 3  |        |         |
| H) | Install Docker binaries     |        |          | Step 4  |         |        | Step 6  |
| I) | Update log driver           |        |          | Step 5  |         | Step 3 | Step 7  |
| J) | Restore log driver          |        |          |         | Step 4  |        |         |
| K) | Update Docker script        |        |          | Step 5  |         |        | Step 8  |
| L) | Restore Docker script       |        |          |         | Step 5  |        |         |
| M) | Start Docker daemon         | Step 3 |          | Step 6  | Step 6  | Step 4 | Step 9  |
| N) | Clean temp folder           |        |          |         |         |        | Step 10 |

* **A) Download Docker binary** - Downloads an archive containing Docker Engine binaries from `https://download.docker.com/linux/static/stable/x86_64/docker-${VERSION}.tgz`. The binaries are compatible with the Intel x86 (64 bit) architecture. Unless a specific version is specified by the `--docker` flag, *Synology-Docker* pulls the latest stable version available.
* **B) Download Compose binary** - Downloads the Docker Compose binary from `https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-Linux-x86_64`. Unless a specific version is specified by the `--compose` flag, *Synology-Docker* pulls the latest stable version available.
* **C) Extract files from backup** - Extracts the files from a backup archive specified by the `--backup` flag to the temp directory (`/tmp/docker_update`). 
* **D) Stop Docker daemon** - Stops the Docker daemon by invoking `synoservicectl --stop pkgctl-Docker`.
* **E) Backup current files** - Creates a backup of the current Docker binaries, including Docker Compose. The configuration of the logging driver and Synology's `start-stop-status` script are included in the archive too. The files included refer to `/var/packages/Docker/target/usr/bin/*`, `/var/packages/Docker/etc/dockerd.json`, and `/var/packages/Docker/scripts/start-stop-status`.
* **F) Extract downloaded binaries** - Extracts the files from a downloaded archive to the temp directory (`/tmp/docker_update`). 
* **G) Restore Docker binaries** - Restores the Docker binaries in `/var/packages/Docker/target/usr/bin/*` with the binaries extracted from a backup archive.
* **H) Install Docker binaries** - Installs downloaded and extracted Docker binaries (including Docker Compose) to the folder `/var/packages/Docker/target/usr/bin/`.
* **I) Update log driver** - Replaces Synology's log driver with a default log driver `local` to improve compatibility while optimizing writes and limiting log file growth. The configuration is updated at `/var/packages/Docker/etc/dockerd.json`
* **J) Restore log driver** - Restores the log driver (`/var/packages/Docker/etc/dockerd.json`) from the configuration within a backup archive.
* **K) Update Docker script** - Updates Synology's `start-stop-status` script for Docker to enable IP forwarding. This ensures containers can be properly reached in bridge networking mode. The script is updated at the location `/var/packages/Docker/scripts/start-stop-status`.
* **L) Restore Docker script** - Restores the `start-stop-status` script (`/var/packages/Docker/scripts/start-stop-status`) from the file within a backup archive.
* **M) Start Docker daemon** - Starts the Docker daemon by invoking `synoservicectl --start pkgctl-Docker` (or `synopkg start ContainerManager` on DSM 7).
* **N) Clean temp folder** - Removes files from the temp directory (`/tmp/docker_update`). The temporary files are created when extracting a downloaded archive or extracting a backup.


### Options
*Synology-Docker* supports the following options. 

| Option      | Alias        | Argument   | Description |
|-------------|--------------|------------|-------------|
| `-b`        | `--backup`   | `NAME`     | Name of the backup (defaults to `docker_backup_YYMMDDHHMMSS.tgz`) |
| `-c`        | `--compose`  | `VERSION`  | Specify the Docker Compose target version (defaults to latest available on github.com) |
| `-d`        | `--docker`   | `VERSION`  | Specify the Docker target version (defaults to latest available on docker.com) |
| `-f`        | `--force`    |            | Force the update and bypass compatibility check / confirmation check |
| `-p`        | `--path`     |            | Path of the backup (defaults to current directory) |
| `-s`        | `--stage`    |            | Stage only, do not replace binaries or the configuration of log driver |

<!--
### Known Issues
This [link][known_issues] contains an overview of known issues, including available workarounds.
-->

## Contributing
1. Fork the repository and create a new branch 
2. Make and test the changes
3. Submit a Pull Request with a comprehensive description of the changes back to this repository


## License
<a href="https://github.com/mrkhachaturov/synology-docker/blob/master/LICENSE" alt="License">
    <img src="https://img.shields.io/github/license/mrkhachaturov/synology-docker.svg" />
</a>

## Origin
Forked from [telnetdoogie/synology-docker](https://github.com/telnetdoogie/synology-docker)
<!-- MARKDOWN PUBLIC LINKS -->
[synology_url]: https://www.synology.com
[synology_docker]: https://www.synology.com/en-us/dsm/packages/Docker
[docker_url]: https://www.docker.com/

