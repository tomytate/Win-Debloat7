# Use official PowerShell image (Ubuntu based for fast CI)
# Ideally we would use Windows Server Core for full fidelity, but specific WMI calls won't work there anyway.
# This Dockerfile is primarily for unit testing logic that doesn't depend on Windows APIs (Config, Utils).

FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

# Set working directory
WORKDIR /app

# Copy source
COPY . .

# Install Pester
RUN pwsh -Command "Install-Module Pester -Force -SkipPublisherCheck"

# Define entrypoint as test runner
ENTRYPOINT ["pwsh", "-Command", "Invoke-Pester -Path ./tests -Output Detailed"]
