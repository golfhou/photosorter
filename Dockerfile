# Start from a clean Alpine Linux image
FROM alpine:3.18

# Sanitize the Perl environment by unsetting potentially problematic
# environment variables that might be passed from the host.
ENV PERL5LIB=""
ENV PERL_MB_LIB=""

# Install dependencies by explicitly specifying the repositories.
RUN apk add --no-cache --update \
    --repository=http://dl-cdn.alpinelinux.org/alpine/v3.18/main \
    --repository=http://dl-cdn.alpinelinux.org/alpine/v3.18/community \
    perl-image-exiftool \
    exiftool \
    inotify-tools

# Copy the sorting script into the container
COPY sort.sh /usr/local/bin/sort.sh

# Make the script executable
RUN chmod +x /usr/local/bin/sort.sh

# Set the entrypoint to be our script, so it runs when the container starts
ENTRYPOINT ["/usr/local/bin/sort.sh"]

# Add a healthcheck to monitor the inotifywait process
HEALTHCHECK --interval=5m --timeout=30s --start-period=1m \
  CMD pgrep inotifywait || exit 1

# Clear the CMD
CMD []
