# Hashcat for Thai ppl

A Windows batch script for running Hashcat against WiFi handshake files (`.hc22000`) with wordlist/mask phases ordered around common Thai password patterns.

[อ่านภาษาไทย](../README.md)

## Requirements

- Windows
- `hashcat.exe` v6 or newer
- `.hc22000` handshake file (WPA/WPA2)
- `rockyou.txt` for the dictionary phase
- `rules\best66.rule` for the rules phase

Place `CRACK_V2.bat` in the same folder as `hashcat.exe`.

## Usage

Drag a `.hc22000` file onto `CRACK_V2.bat`.

Or run it from cmd:

```cmd
CRACK_V2.bat your_capture.hc22000
```

Startup options:

- `START`: default run, auto device + Standard level
- `SETTINGS`: choose GPU/CPU and attack level

## Attack Levels

| Level | Name | Runs |
| --- | --- | --- |
| 1 | Fast | `rockyou.txt`, birthdates, 8 digits, Thai mobile numbers |
| 2 | Standard | Fast + `best66.rule`, 9 digits |
| 3 | Extended | Standard + 10 digits |
| 4 | Extreme | Extended + 11-12 digits |

Hashcat keys:

- `S` show status
- `P` pause
- `B` bypass phase
- `Q` quit

## Generated Files

- `thaiprefix.txt`
- `birthdate_patterns.txt`
- `hashcat.potfile`
- `temp_devices.txt` temporary file

## Quick Troubleshooting

- `hashcat.exe not found`: keep the script in the same folder as `hashcat.exe`
- Got `.cap` or `.pcap`: convert it to `.hc22000` at <https://hashcat.net/cap2hashcat/>
- Missing `rockyou.txt` or `best66.rule`: that phase may be skipped or the download failed; place the file manually
- Very slow: confirm Hashcat detects your GPU and drivers are installed

## Note

Use only on networks you own or are authorized to test. The author is not responsible for misuse.

## Credits

- Hashcat: <https://hashcat.net/>
- RockYou wordlist: <https://github.com/brannondorsey/naive-hashcat>
