# Docker based automation that organizes pictures and videos that are then sorted into structured directories for external Immish libraries.

[![Docker Hub](https://img.shields.io/docker/pulls/golfhou/photosorter?style=for-the-badge)](https://hub.docker.com/r/golfhou/photosorter)

This project provides a fully automated, Docker-based service to watch a directory for new photos and videos and move them into a structured library based on their creation date. Build to be used with Unraid, Syncthing, and Immish external libraries.

It's designed to be a "set it and forget it" solution for keeping your media library organized.

## Key Features

- **Automated Sorting**: Runs in the background and automatically processes new
  files as they are added.
- **Date-Based Organization**: Sorts files into a `YYYY/MM` folder structure.
- **Intelligent Renaming**: Renames files to a `YYYY-MM-DD_HH-MM-SS` format
  based on metadata.
- **Robust Fallbacks**: If a primary date tag (like `DateTimeOriginal`) is not
  found, it intelligently falls back to other tags (`CreateDate`,
  `FileModifyDate`, etc.).
- **Duplicate Handling**: Detects if a file with the same name already exists at
  the destination and moves the new file to a `duplicates` folder to prevent
  data loss.
- **Error Handling**: Files that have no readable date information are moved to
  a `failed_sort` folder for manual review.
- **Cross-Platform**: Runs as a Docker container, making it compatible with any
  system that supports Docker, including Unraid, Synology, and other Linux
  servers.

## Installation

There are two ways to install and run this service, depending on your needs.

### 1. Easy Installation (via Docker Hub)

This is the recommended method for most users who want to use the default sorting logic without any customization.

**Step 1: Create `docker-compose.yml`**

On your server, create a file named `docker-compose.yml` and paste the following content into it:

```yaml
services:
  photosorter:
    image: golfhou/photosorter:latest
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

**Step 2: Configure Paths**

Edit the `volumes` section in your `docker-compose.yml` to point to your media library. For example, if your photos are in `/mnt/user/MyMedia`, change `- /path/on/your/host:/media` to `- /mnt/user/MyMedia:/media`.

**Step 3: Run the Service**

In the same directory as your `docker-compose.yml` file, run the following command. This will download the image from Docker Hub and start the service.

```bash
docker-compose up -d
```

**Step 4: Check the Logs**

To confirm the sorter is running and processing files, view its logs in real-time:
```bash
docker-compose logs -f photosorter
```
Press `Ctrl+C` to exit the log view.

### 2. Advanced Installation & Customization (from Source)

This method is for users who want to modify the sorting logic (e.g., change the folder structure or filename format) in the `sort.sh` script.

**Step 1: Get the Project Files**

You can get the project files onto your server using one of the following methods:

*   **Using Git (Recommended for advanced users)**: If you have Git installed, you can clone the repository:
    ```bash
    git clone https://github.com/golfhou/photosorter.git
    cd photosorter
    ```
    This will create a `photosorter` folder containing all the project files.

*   **Using `wget` or `curl` (for command-line download)**: If you don't have Git but are comfortable with the command line, you can download the ZIP archive:
    ```bash
    wget https://github.com/golfhou/photosorter/archive/refs/heads/main.zip -O photosorter.zip
    # Or using curl:
    # curl -L https://github.com/golfhou/photosorter/archive/refs/heads/main.zip -o photosorter.zip
    unzip photosorter.zip
    mv photosorter-main photosorter # Rename the unzipped folder
    cd photosorter
    ```
    This will create a `photosorter` folder containing all the project files.

*   **Manual Download (for GUI users)**:
    1.  Go to the project's GitHub page: [https://github.com/golfhou/photosorter](https://github.com/golfhou/photosorter)
    2.  Click the green **`< > Code`** button and select **"Download ZIP"**.
    3.  Unzip the file on your server. This will create a `photosorter-main` folder containing all the project files. Rename it to `photosorter` for consistency.

**Step 2: Customize (Optional)**

Navigate into the `photosorter-main` folder and open `sort.sh` with a text editor. You can now modify the `exiftool` commands or any other part of the script to fit your needs.

*   **Need help with customization?** If you're unsure how to modify the `sort.sh` script to achieve a specific sorting logic, feel free to ask Gemini for assistance!

**Step 3: Configure and Build**

1.  Open the `docker-compose.yml` file that came with the project.
2.  Edit the `volumes` section to point to your media library, just like in the "Easy Installation" method.
3.  In the same directory, run the following command. The `--build` flag is important, as it tells Docker to build your image locally using your (potentially modified) files.

    ```bash
    docker-compose up -d --build
    ```

---

## Common Steps

### Checking the Logs

To see if the sorter is working correctly, you can view its logs in real-time:
```bash
docker-compose logs -f photosorter
```
Press `Ctrl+C` to exit the log view.

## Development Notes

This project went through several debugging steps to ensure it was robust and
reliable. Key procedures included:

- **Verifying Docker Networking**: When the Docker build failed to download
  packages, we confirmed the host's Docker networking was functional by running
  an interactive container (`docker run --rm -it alpine:3.18 sh`) and
  successfully running `apk update` inside it. This isolated the problem to the
  `docker build` process itself.

- **Manual Package Installation**: To identify the correct package names for
  `exiftool` on Alpine Linux, we manually ran `apk add ...` commands inside an
  interactive container until the correct packages (`perl-image-exiftool` and
  `exiftool`) were found.

- **Shell Script Debugging**: To diagnose a silent crash in the `sort.sh`
  script, we temporarily added `set -x` to the top of the script. This enabled
  debug tracing, which printed every command to the log and allowed us to
  pinpoint the exact line causing the failure.

## Original Use Case

This project was initially developed to serve as a robust media ingestion and
organization layer within a home lab environment, specifically tailored for:

- **Unraid**: Running the Docker container on an Unraid server provides a stable
  and always-on platform for media processing. Volumes are mapped directly to
  Unraid shares, allowing seamless access to media storage.
- **Syncthing**: Files are initially synced from various devices (e.g., mobile
  phones, cameras) into the `INPUT_DIR` (e.g., `/media/new_uploads`) using
  Syncthing. This ensures that new media is automatically transferred to the
  server.
- **Immich**: Once sorted into the `OUTPUT_DIR` (e.g., `/media/ALL_PHOTOS`),
  this organized folder structure is ideal for use as an **external library** in
  media management applications like Immich. While Immich has its own excellent
  mobile backup solution for its internal library, this sorter provides a
  powerful way to automatically ingest and organize media from other sources
  (e.g., dedicated cameras, shared family folders) into a clean, date-structured
  external library that Immich can then scan.

This setup creates a fully automated pipeline for external media: New files from
various sources -> Syncthing -> Photo Sorter -> Organized External Library ->
Immich.

## Acknowledgments

This project makes use of the following excellent open-source tools:

- **ExifTool**: A powerful and flexible utility for reading, writing, and
  editing meta information in a wide variety of files.
  [ExifTool Website](https://exiftool.org/)
- **inotify-tools**: A C library and a set of command-line programs for Linux
  providing a simple interface to inotify.
  [inotify-tools GitHub](https://github.com/rvoicilas/inotify-tools)
- Special thanks to **Gemini** for assistance in developing, debugging, and
  refining this project.

## License

This project is open source and available under the [MIT License](LICENSE).
