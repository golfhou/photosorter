#  Docker based automation that organizes pictures and videos that are then sorted into structured directories for external Immish libraries. 

This project provides a fully automated, Docker-based service to watch a directory for new photos and videos and move them into a structured library based on their creation date. Build to be used with Unraid, Syncthing, and Immish external libraries.


It's designed to be a "set it and forget it" solution for keeping your media library organized.

## Key Features

- **Automated Sorting**: Runs in the background and automatically processes new files as they are added.
- **Date-Based Organization**: Sorts files into a `YYYY/MM` folder structure.
- **Intelligent Renaming**: Renames files to a `YYYY-MM-DD_HH-MM-SS` format based on metadata.
- **Robust Fallbacks**: If a primary date tag (like `DateTimeOriginal`) is not found, it intelligently falls back to other tags (`CreateDate`, `FileModifyDate`, etc.).
- **Duplicate Handling**: Detects if a file with the same name already exists at the destination and moves the new file to a `duplicates` folder to prevent data loss.
- **Error Handling**: Files that have no readable date information are moved to a `failed_sort` folder for manual review.
- **Cross-Platform**: Runs as a Docker container, making it compatible with any system that supports Docker, including Unraid, Synology, and other Linux servers.

## Quick Start

1.  **Prerequisites**: You must have Docker and Docker Compose installed.

2.  **Configuration**:
    Copy the `docker-compose.yml` file to your server. You will need to edit the `volumes` and `environment` sections to match your directory structure.

    ```yaml
    services:
      photosorter:
        build: .
        container_name: photosorter
        volumes:
          # Mount your main photos directory here.
          # This example maps '/path/on/your/host' to '/media' inside the container.
          - /path/on/your/host:/media
        environment:
          # Directory for sorted photos (e.g., /media/ALL_PHOTOS/2025/11)
          - OUTPUT_DIR=/media/ALL_PHOTOS
          # Directory to watch for new files to sort
          - INPUT_DIR=/media/new_uploads
          # Optional: Directory for files that fail to sort
          - FAILED_DIR=/media/ALL_PHOTOS/failed_sort
          # Optional: Directory for duplicate files
          - DUPLICATE_DIR=/media/ALL_PHOTOS/duplicates
        restart: unless-stopped
    ```

    **Important**:
    - Replace `/path/on/your/host` with the actual path to your main photos directory on your server (e.g., `/mnt/user/photos`).
    - The `INPUT_DIR` and `OUTPUT_DIR` paths should be subdirectories within the main path you mounted. Make sure the `INPUT_DIR` folder (e.g., `new_uploads`) exists on your host system.

3.  **Run the Service**:
    In the same directory as your `docker-compose.yml`, run the following command:
    ```bash
    docker-compose up -d --build
    ```
    The service will now start and begin processing any existing files in your `INPUT_DIR`, then continue to watch for new ones.

## Beginner's Installation Guide

If you are new to Docker or Git, this guide will walk you through the entire setup process from start to finish.

### Step 1: Get the Project Files

First, you need to download the project files onto the server where you plan to run the sorter (e.g., your Unraid server).

1.  Go to the project's GitHub page: [https://github.com/golfhou/photosorter](https://github.com/golfhou/photosorter)
2.  Click the green **`< > Code`** button.
3.  In the dropdown menu, click **"Download ZIP"**.
4.  Unzip the downloaded file (`photosorter-main.zip`) into a location of your choice on your server. This will create a folder named `photosorter-main` which contains all the necessary files (`docker-compose.yml`, `Dockerfile`, etc.).

### Step 2: Install Docker

This service runs in a Docker container, so you need to have Docker and Docker Compose installed.

*   **For Unraid users**: Docker and Docker Compose are already built into the Unraid operating system, so you can skip this step!
*   **For other Linux users (like Debian, Ubuntu, CentOS)**: The best way to install is to follow the official guides, as the commands can vary.
    *   [Install Docker Engine](https://docs.docker.com/engine/install/#server) (select your OS from the list)
    *   [Install Docker Compose](https://docs.docker.com/compose/install/)

### Step 3: Configure the Sorter

This is the most important step. You need to tell the sorter where your photo directories are.

1.  Navigate into the `photosorter-main` folder you unzipped earlier.
2.  Open the `docker-compose.yml` file with a text editor.
3.  You need to edit the `volumes` and `environment` sections to match your server's folder structure.

    ```yaml
    services:
      photosorter:
        build: .
        # ... (other settings) ...
        volumes:
          # CHANGE THIS LINE:
          # Replace '/path/on/your/host' with the path to your main photos folder.
          - /path/on/your/host:/media
        environment:
          # These should be sub-folders inside the path you mounted above.
          - OUTPUT_DIR=/media/ALL_PHOTOS
          - INPUT_DIR=/media/new_uploads
    ```

    For example, if all your photos are stored in `/mnt/user/MyMedia/`, you would change the `volumes` line to:
    `- /mnt/user/MyMedia:/media`

    In this example, the sorter will watch for new files in `/mnt/user/MyMedia/new_uploads` and move them into `/mnt/user/MyMedia/ALL_PHOTOS`. Make sure the `new_uploads` folder exists.

### Step 4: Run the Service

1.  Open a terminal on your server.
2.  Navigate to the `photosorter-main` directory where your `docker-compose.yml` file is located.
3.  Run the following command:
    ```bash
    docker-compose up -d --build
    ```
4.  **Check the Logs**: To see if the sorter is working correctly and processing your files, you can view its logs in real-time:
    ```bash
    docker-compose logs -f photosorter
    ```
    You should see messages indicating files being processed, moved, or handled as duplicates/failed sorts. Press `Ctrl+C` to exit the log view.

That's it! The photo sorter will now start, build the necessary container, and begin watching your `INPUT_DIR` for new files.

## Development Notes

This project went through several debugging steps to ensure it was robust and reliable. Key procedures included:

*   **Verifying Docker Networking**: When the Docker build failed to download packages, we confirmed the host's Docker networking was functional by running an interactive container (`docker run --rm -it alpine:3.18 sh`) and successfully running `apk update` inside it. This isolated the problem to the `docker build` process itself.

*   **Manual Package Installation**: To identify the correct package names for `exiftool` on Alpine Linux, we manually ran `apk add ...` commands inside an interactive container until the correct packages (`perl-image-exiftool` and `exiftool`) were found.

*   **Shell Script Debugging**: To diagnose a silent crash in the `sort.sh` script, we temporarily added `set -x` to the top of the script. This enabled debug tracing, which printed every command to the log and allowed us to pinpoint the exact line causing the failure.

## Original Use Case

This project was initially developed to serve as a robust media ingestion and organization layer within a home lab environment, specifically tailored for:

*   **Unraid**: Running the Docker container on an Unraid server provides a stable and always-on platform for media processing. Volumes are mapped directly to Unraid shares, allowing seamless access to media storage.
*   **Syncthing**: Files are initially synced from various devices (e.g., mobile phones, cameras) into the `INPUT_DIR` (e.g., `/media/new_uploads`) using Syncthing. This ensures that new media is automatically transferred to the server.
*   **Immich**: Once sorted into the `OUTPUT_DIR` (e.g., `/media/ALL_PHOTOS`), this organized folder structure is ideal for use as an **external library** in media management applications like Immich. 

This setup creates a fully automated pipeline for external media: New files from various sources -> Syncthing -> Photo Sorter -> Organized External Library -> Immich.

## Acknowledgments

This project makes use of the following excellent open-source tools:

-   **ExifTool**: A powerful and flexible utility for reading, writing, and editing meta information in a wide variety of files. [ExifTool Website](https://exiftool.org/)
-   **inotify-tools**: A C library and a set of command-line programs for Linux providing a simple interface to inotify. [inotify-tools GitHub](https://github.com/rvoicilas/inotify-tools)
-   Special thanks to **Gemini** for assistance in developing, debugging, and refining this project.  
## License

This project is open source and available under the [MIT License](LICENSE).
# photosorter
# photosorter
