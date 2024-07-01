# Automate Palword Server Restart With Discord Notification

This bash script automates periodic restarts of a Palworld dedicated server on `LINUX` and sends Discord notifications about these restarts.

## Features

- Automatic periodic server restarts
- Discord notifications for restart warnings and completions
- Customizable restart intervals and notification timings

## Installation

1. Clone this repository or download the script to your Palworld server folder.
2. Make the script executable:
   ```
   chmod +x palworld_restart_notify.sh
   ```

## Configuration

The script uses environment variables for configuration. You can set these variables before running the script or include them in your system's environment.

Available variables and their defaults:

- `DISCORD_WEBHOOK`: Your Discord webhook URL for notifications
  Default: "" (Discord notifications are disabled if not set)
- `DISCORD_ROLE_ID`: The Discord role ID to mention in notifications
  Default: "" (No role mention if not set)
- `RESTART_INTERVAL`: How long the server runs before restarting (in seconds)
  Default: 20700 (5 hours and 45 minutes)
- `RESTART_WARNING_TIME`: How long before a restart to send a warning notification (in seconds)
  Default: 900 (15 minutes)
- `PALWORLD_START_CMD`: Command to start your Palworld server
  Default: "./PalServer.sh -publiclobby -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS"


## Usage

To run the script with default settings:

```
./palworld_restart_notify.sh
```


It's recommended to run this script using a process manager like `systemd` or `screen` to keep it running after you log out.


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
