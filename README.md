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
