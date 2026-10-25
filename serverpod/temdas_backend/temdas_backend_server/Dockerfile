# Build from the project root with:
# docker build -f temdas_backend_server/Dockerfile .

# Build stage
FROM dart:3.8.0 AS build

# Create a minimal workspace that preserves locked server dependency versions.
WORKDIR /app
COPY pubspec.lock .
COPY temdas_backend_server temdas_backend_server
RUN printf '%s\n' \
  'name: _' \
  'environment:' \
  '  sdk: ^3.8.0' \
  'workspace:' \
  '  - temdas_backend_server' \
  > pubspec.yaml
RUN dart pub get

# Compile the server executable.
WORKDIR /app/temdas_backend_server
RUN dart compile exe bin/main.dart -o bin/server

# Add a fallback for the copy of possibly missing directories.
RUN mkdir -p config web migrations

# Final stage
FROM alpine:latest
WORKDIR /app

# Environment variables
ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith

# Copy runtime dependencies
COPY --from=build /runtime/ /

# Copy compiled server executable
COPY --from=build /app/temdas_backend_server/bin/server server

# Copy only the production configuration. Development, test, and local password
# files are not part of the production image.
COPY --from=build /app/temdas_backend_server/config/production.yaml config/production.yaml
COPY --from=build /app/temdas_backend_server/web/ web/
COPY --from=build /app/temdas_backend_server/migrations/ migrations/

# This file is required to enable the endpoint log filter in Insights.
COPY --from=build /app/temdas_backend_server/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml

# Expose ports
EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

# Keep the normal server process replaceable by Railway's pre-deploy command,
# which runs one-off maintenance migrations before starting the API container.
CMD ["sh", "-c", "exec ./server --mode=$runmode --server-id=$serverid --logging=$logging --role=$role"]
