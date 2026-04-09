# Stage 1: Build
FROM golang:1.24-alpine AS builder

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache git make

# Copy source
COPY . .

# Build vsp
RUN go build -o vsp ./cmd/vsp

# Stage 2: Runtime
FROM alpine:latest

# Install runtime dependencies (minimal)
RUN apk add --no-cache ca-certificates bash jq

# Copy binary from builder
COPY --from=builder /build/vsp /usr/local/bin/vsp

# Copy MCP manifest and registration scripts
COPY .mcp-manifest.json /mcp-manifest.json
COPY register-mcp.sh /usr/local/bin/register-mcp
COPY register-docker-entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/register-mcp /usr/local/bin/entrypoint

# Create working directory
WORKDIR /app

# Custom entrypoint allows both MCP server mode and registration mode
ENTRYPOINT ["/usr/local/bin/entrypoint"]

# Default to MCP server mode with hyperfocused tool
# (can be overridden with --mode focused or --mode expert, or 'register' for setup)
CMD ["--mode", "hyperfocused"]
