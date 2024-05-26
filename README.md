# synology-docker

<!-- Tagline -->
<p align="center">
    <b>An Unofficial Script to Update or Restore Docker Engine and Docker Compose on Synology NAS</b>
    <br />
</p>


<!-- Badges -->
<p align="center">
    <a href="https://github.com/markdumay/synology-docker/commits/master" alt="Last commit">
        <img src="https://img.shields.io/github/last-commit/markdumay/synology-docker.svg" />
    </a>
    <a href="https://github.com/markdumay/synology-docker/issues" alt="Issues">
        <img src="https://img.shields.io/github/issues/markdumay/synology-docker.svg" />
    </a>
    <a href="https://github.com/markdumay/synology-docker/pulls" alt="Pulls">
        <img src="https://img.shields.io/github/issues-pr-raw/markdumay/synology-docker.svg" />
    </a>
    <a href="https://github.com/markdumay/synology-docker/blob/master/LICENSE" alt="License">
        <img src="https://img.shields.io/github/license/markdumay/synology-docker.svg" />
    </a>
</p>

<!-- Table of Contents -->
<p align="center">
  <a href="#about">About</a> •
  <a href="#built-with">Built With</a> •
  <a href="#prerequisites">Prerequisites</a> •
  <a href="#deployment">Deployment</a> •
  <a href="#usage">Usage</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#credits">Credits</a> •
  <a href="#donate">Donate</a> •
  <a href="#license">License</a>
</p>


## About
| :warning: The repository 'Synology-Docker' is not supported by Synology and can potentially lead to malfunctioning of your NAS. Use this script at your own risk. Please keep a backup of your files. |
| --- |

[Synology][synology_url] is a popular manufacturer of Network Attached Storage (NAS) devices. It provides a web-based user interface called Disk Station Manager (DSM). Synology also supports Docker on selected [models][synology_docker]. Docker is a lightweight virtualization application that gives you the ability to run containers directly on your NAS. The add-on package provided by Synology to install Docker is typically a version behind on the latest available version from Docker. *Synology-Docker* is a POSIX-compliant shell script to update both the Docker Engine and Docker Compose on your NAS to the latest version or a specified version.

<!-- TODO: add tutorial deep-link 
Detailed background information is available on the author's [personal blog][blog].
-->

## Built With
The project uses [Docker][docker_url], a lightweight virtualization application.

## Prerequisites
*Synology-Docker* runs on a Synology NAS with DSM 6 or DSM 7. The script has been tested with a DS918+ running DSM 6.2.4-25556, DSM 7.0.1-42218, and DSM 7.2.1-69057. Other prerequisites are:

* **SSH admin access is required** - *Synology-Docker* runs as a shell script on the terminal. You can enable SSH access in DSM under `Control Panel ➡ Terminal & SNMP ➡ Terminal`.

* **Docker is required** - *Synology-Docker* updates the binaries of an existing Docker installation only. Install Docker on your NAS in DSM via `Package Center ➡ All Packages ➡ Docker` and ensure the status is `Running`.

* **SynoCommunity/Git is required** - *Synology-Docker* needs the [Git package](https://synocommunity.com/package/git) from [SynoCommunity](https://synocommunity.com) installed on your NAS. Install Git on your NAS by adding the SynoCommunity package repository (described [here](https://synocommunity.com/#easy-install)) and installing the Git package in DSM via `Package Center ➡ Community ➡ Git`.

## Deployment
Deployment of *Synology-Docker* is a matter of cloning the GitHub repository. Login to your NAS terminal via SSH first. Assuming you are in the working folder of your choice, clone the repository files. Git automatically creates a new folder `synology-docker` and copies the files to this directory. Then change your current folder to simplify the execution of the shell script.

```console
$ git clone https://github.com/markdumay/synology-docker.git
$ cd synology-docker
```

<!-- TODO: TEST CHMOD -->

## Preparation before upgrade
If you're using *compose* for your containers, I highly recommend that before you run the upgrade (or restore, if you're going back to the original version) you go through and stop each running container.
```console
$ cd /volume1/docker/{my_container}
$ docker-compose down
```
Because this upgrade modifies the default logger for docker, stopping (removing) and re-starting each container is required, since the logging mechanism is persisted during a compose docker build / start. You don't HAVE to do this before the upgrade, however if you don't, you'll get errors related to the logger for your containers, and will have to stop and start each container / stack after the upgrade anyway.

Stopping all the containers prior to the upgrade / restore will also make the upgrade a lot faster, since the service stop and restart normally has to do the work of stopping and starting all containers.

For a convenient way of enumerating all of the running *compose* projects, you can execute the following:

```console
for c in $(docker ps -q); do \
    docker inspect "$c" --format \
    '{{.Name}} {{if index .Config.Labels "com.docker.compose.project.config_files"}}{{index .Config.Labels "com.docker.compose.project.config_files"}}{{else}}!---not_managed_by_compose---!{{end}}'; \
done \
| sort -u -t " " -k 2 \
| column -t -N Container,Compose_Location
```
...if you see a container with `!---not_managed_by_compose---!` you'll need to make sure you know how to recreate this container after the upgrade.


## Usage
*Synology-Docker* requires `sudo` rights. Use the following command to invoke *Synology-Docker* from the command line.

```console
$ sudo ./syno_docker_update.sh [OPTIONS] COMMAND
```



### Commands
*Synology-Docker* supports the following commands. 

| Command        | Argument  | Description |
|----------------|-----------|-------------|
| **`backup`**   |           | Create a backup of Docker binaries (including Docker Compose), `dockerd` configuration, and Synology's `start-stop-status` script |
| **`download`** | PATH      | Download Docker and Docker Compose binaries to *PATH* |
| **`install`**  | PATH      | Update Docker and Docker Compose from files on *PATH* |
| **`restore`**  |           | Restore Docker and Docker Compose from a backup |
| **`update`**   |           | Update Docker and Docker Compose to a target version (creates a backup first) |

Under the hood, the five different commands invoke a specific workflow or sequence of steps. The below table shows the workflows and the order of steps for each of the commands.
| #  | Workflow step               | backup | download | install | restore | update  |
|----|-----------------------------|--------|----------|---------|---------|---------|
| A) | Download Docker binary      |        | Step 1   |         |         | Step 1  |
| B) | Download Compose binary     |        | Step 2   |         |         | Step 2  |
| C) | Extract files from backup   |        |          |         | Step 1  |         |
| D) | Stop Docker daemon          | Step 1 |          | Step 1  | Step 2  | Step 3  |
| E) | Backup current files        | Step 2 |          | Step 2  |         | Step 4  |
| F) | Extract downloaded binaries |        |          | Step 3  |         | Step 5  |
| G) | Restore Docker binaries     |        |          |         | Step 3  |         |
| H) | Install Docker binaries     |        |          | Step 4  |         | Step 6  |
| I) | Update log driver           |        |          | Step 5  |         | Step 7  |
| J) | Restore log driver          |        |          |         | Step 4  |         |
| K) | Update Docker script        |        |          | Step 5  |         | Step 8  |
| L) | Restore Docker script       |        |          |         | Step 5  |         |
| M) | Start Docker daemon         | Step 3 |          | Step 6  | Step 6  | Step 9  |
| N) | Clean temp folder           |        |          |         |         | Step 10 |

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

| Option      | Alias       | Argument   | Description |
|-------------|-------------|------------|-------------|
| `-b`        | `--backup`  | `NAME`     | Name of the backup (defaults to `docker_backup_YYMMDDHHMMSS.tgz`) |
| `-c`        | `--compose` | `VERSION`  | Specify the Docker Compose target version (defaults to latest available on github.com) |
| `-d`        | `--docker`  | `VERSION`  | Specify the Docker target version (defaults to latest available on docker.com) |
| `-f`        | `--force`   |            | Force the update and bypass compatibility check / confirmation check |
| `-p`        | `--path`    |            | Path of the backup (defaults to current directory) |
| `-s`        | `--stage`   |            | Stage only, do not replace binaries or the configuration of log driver |

### Known Issues
This [link][known_issues] contains an overview of known issues, including available workarounds.

## Contributing
1. Clone the repository and create a new branch 
    ```console
    $ git checkout https://github.com/markdumay/synology-docker.git -b name_for_new_branch
    ```
2. Make and test the changes
3. Submit a Pull Request with a comprehensive description of the changes

## Credits
*Synology-Docker* is inspired by this [gist][gist_mikado8231] from Mikado8231.

## Donate
<a href="https://www.buymeacoffee.com/markdumay" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/lato-orange.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;"></a>

## License
<a href="https://github.com/markdumay/synology-docker/blob/master/LICENSE" alt="License">
    <img src="https://img.shields.io/github/license/markdumay/synology-docker.svg" />
</a>

Copyright © [Mark Dumay][blog]



<!-- MARKDOWN PUBLIC LINKS -->
[synology_url]: https://www.synology.com
[synology_docker]: https://www.synology.com/en-us/dsm/packages/Docker
[gist_mikado8231]: https://gist.github.com/Mikado8231/bf207a019373f9e539af4d511ae15e0d

[acmesh_deploy]: https://github.com/acmesh-official/acme.sh/wiki/deployhooks
[acmesh_url]: https://acme.sh
[crontab_guru]: https://crontab.guru
[docker_url]: https://docker.com
[luka_wildcard]: https://www.blackvoid.club/lets-encrypt-docker-wild-card-certs/
[markus_renew]: https://lippertmarkus.com/2020/03/14/synology-le-dns-auto-renew/
[swarm_init]: https://docs.docker.com/engine/reference/commandline/swarm_init/
[xfelix_letsencrypt]: https://www.xfelix.com/2017/06/synology-letsencrypt-dns-01-cert-issue-and-install/
[portainer]: https://www.portainer.io
[known_issues]: https://github.com/markdumay/synology-docker/issues/42
[macvlan]: [https://blog.oddbit.com/post/2018-03-12-using-docker-macvlan-networks/]


<!-- MARKDOWN MAINTAINED LINKS -->
<!-- TODO: add blog link
[blog]: https://markdumay.com
-->
[blog]: https://github.com/markdumay
[repository]: https://github.com/markdumay/synology-docker.git
