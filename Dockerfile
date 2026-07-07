# The dedicated mcr.microsoft.com/powershell images are deprecated; Microsoft's
# guidance is to use the .NET SDK images, which bundle the latest stable PowerShell
# (7.6.x on .NET 10). Ideally we would use Windows Server Core for full fidelity,
# but specific WMI calls won't work there anyway.
# This Dockerfile is primarily for unit testing logic that doesn't depend on
# Windows APIs (Config, Utils).

FROM mcr.microsoft.com/dotnet/sdk:10.0

# Set working directory
WORKDIR /app

# Copy source
COPY . .

# Install Pester
RUN pwsh -Command "Install-Module Pester -Force -SkipPublisherCheck"

# Define entrypoint as test runner
ENTRYPOINT ["pwsh", "-Command", "Invoke-Pester -Path ./tests -Output Detailed"]
