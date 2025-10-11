#!/usr/bin/env bash

# Change ownership of the .dotnet directory to the vscode user (to avoid permission errors)
sudo chown -R vscode:vscode /home/vscode/.dotnet

# If there is no development certificate, this command will generate a new one
dotnet dev-certs https --trust
