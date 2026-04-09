# Hashcat WiFi Cracker - Thai Optimized Edition

Automated WiFi password cracking tool optimized for Thai networks using Hashcat. Features intelligent attack sequencing, time tracking, and clean output.

## Features

- ✅ **Optimized for Thai WiFi Networks** - Prioritizes common Thai password patterns
- ⏱️ **Time Tracking** - Monitors total cracking duration with detailed timestamps
- 🎯 **Smart Attack Sequence** - Starts with fastest methods first
- 🔍 **Duplicate Detection** - Skips already-cracked hashes automatically
- 📊 **Clean Output** - Minimal logging with periodic status updates
- 🇹🇭 **Thai Mobile Patterns** - Includes all Thai mobile prefixes (061-069, 080-099)

## Requirements

### Software
- **Hashcat** (v6.0.0 or higher)
- **Windows** (Batch script for Windows)
- **GPU** (NVIDIA/AMD recommended for faster cracking)

### Files Needed
- `hashcat.exe` - Main Hashcat executable
- `rockyou.txt` - Password wordlist ([Download here](https://github.com/brannondorsey/naive-hashcat/releases))
- `rules/best64.rule` - Rule file (included with Hashcat)
- `.hc22000` file - Your captured WiFi handshake

## Installation

1. **Download Hashcat**
   ```
   https://hashcat.net/hashcat/
   ```
   Extract to a folder (e.g., `C:\hashcat-7.1.2\`)

2. **Download rockyou.txt wordlist**
   ```
   https://github.com/brannondorsey/naive-hashcat/releases
   ```
   Place in the same folder as `hashcat.exe`

3. **Download this script**
   - Save `hashcat_wifi_cracker_optimized.bat` to your Hashcat folder

4. **Capture WiFi Handshake**
   - Use tools like `aircrack-ng`, `hcxdumptool`, or `Wireshark`
   - Convert to `.hc22000` format if needed

## Usage

### Method 1: Drag and Drop (Easiest)
1. Drag your `.hc22000` file onto `hashcat_wifi_cracker_optimized.bat`
2. Wait for the cracking process to complete

### Method 2: Command Line
```cmd
cd C:\hashcat-7.1.2
hashcat_wifi_cracker_optimized.bat your_capture.hc22000
```

### Method 3: Double-click (Manual Input)
1. Double-click the `.bat` file
2. It will show an error with usage instructions
3. Follow the instructions to provide your hash file

## Attack Phases

The script runs 6 phases in order of speed and probability:

| Phase | Attack Type | Keyspace | Est. Time* | Priority |
|-------|-------------|----------|------------|----------|
| 1 | Dictionary (rockyou.txt) | 14M passwords | 0.5 min | ⭐⭐⭐⭐⭐ |
| 2 | Dictionary + best64 rules | 896M combinations | 33.7 min | ⭐⭐⭐⭐⭐ |
| 3 | Birthdate patterns (DDMMYYYY) | ~14,600 | <1 sec | ⭐⭐⭐⭐ |
| 4 | 8-digit numbers | 100M | 3.7 min | ⭐⭐⭐⭐ |
| 5 | Thai mobile numbers | 290M | 10.6 min | ⭐⭐⭐⭐ |
| 6 | 9-digit numbers | 1B | 36.7 min | ⭐⭐ |

**Total estimated time: ~85 minutes (1h 25m)** if running all phases

*Times based on ~454 KH/s (typical mid-range GPU). Your speed may vary.

## Output Examples

### Success (Password Found)
```
===================================================
  PASSWORD FOUND - CRACKING SUCCESSFUL
===================================================

[RESULT] Password recovered:
------------------------------------------------
MyWiFi_5G:0812345678
------------------------------------------------

===================================================
[SUCCESS] Password saved to hashcat.potfile
[TIME] Total duration: 0h 15m 32s
[STARTED] 14:30:15.23
[FINISHED] 14:45:47.89
===================================================
```

### Already Cracked
```
===================================================
  PASSWORD ALREADY CRACKED (Found in potfile)
===================================================

[RESULT] Password recovered:
------------------------------------------------
MyWiFi_5G:0812345678
------------------------------------------------

[INFO] This hash was cracked in a previous session
[INFO] No need to run cracking again
```

### No Password Found
```
===================================================
     ALL CRACKING PHASES COMPLETED
===================================================

[TIME] Total duration: 1h 25m 18s
[STARTED] 14:30:15.23
[FINISHED] 15:55:33.41

[FAILED] No passwords found in any phase

Recommendations:
- Verify the handshake capture is valid
- Try additional wordlists
- Use more specific masks
```

## Generated Files

The script automatically creates these files:

- `thaiprefix.txt` - Thai mobile number patterns (29 prefixes)
- `birthdate_patterns.txt` - Date patterns for B.E. and C.E. years
- `hashcat.potfile` - Stores all cracked passwords
- `temp_*.txt` - Temporary files (auto-deleted)

## Thai Mobile Prefixes Included

The script tests all active Thai mobile prefixes:

**AIS:** 061-069, 080-083, 084-089  
**DTAC:** 090-099  
**TrueMove H:** 061-069, 092-094

Total: 29 prefixes × 10 million numbers = 290 million combinations

## Birthdate Patterns

Tests common birthdate formats:
- **Buddhist Era (B.E.):** 2500-2599 (1957-2056 CE)
- **Christian Era (C.E.):** 1900-1999, 2000-2099
- **Format:** DDMMYYYY (e.g., 01012540, 25121990)

## Performance Tips

### Faster Cracking
- Use a dedicated GPU (NVIDIA RTX/AMD RX series)
- Close other GPU-intensive applications
- Use `-w 4` workload profile (already set)
- Enable `-O` optimized kernels (already set)

### Speed Estimates by GPU
| GPU | Approx. Speed | 8-digit Time | Full Script Time |
|-----|---------------|--------------|------------------|
| RTX 4090 | 2-3 MH/s | <1 min | ~20 min |
| RTX 3080 | 1-1.5 MH/s | 1-2 min | ~40 min |
| RTX 2060 | 400-600 KH/s | 3-5 min | ~90 min |
| GTX 1660 | 300-400 KH/s | 5-7 min | ~120 min |
| CPU only | 10-50 KH/s | 30-150 min | 8-40 hours |

## Troubleshooting

### "hashcat.exe not found"
- Make sure the script is in the same folder as `hashcat.exe`
- Or provide full path: `C:\hashcat\hashcat.exe`

### "rockyou.txt not found"
- Download from: https://github.com/brannondorsey/naive-hashcat/releases
- Place in the same folder as the script
- Or the script will skip dictionary phases

### "rules\best64.rule not found"
- This file comes with Hashcat installation
- Check `hashcat\rules\` folder
- Or download Hashcat again

### "No hashes loaded"
- Your `.hc22000` file may be corrupted
- Verify with: `hashcat.exe -m 22000 your_file.hc22000 --show`
- Recapture the handshake

### Very Slow Speed
- Check if GPU is being used: Look for "Device #1" in output
- Update GPU drivers
- Close other applications
- Check GPU temperature (may throttle if overheating)

### "All hashes found as potfile"
- This hash was already cracked
- Check results with: `hashcat.exe -m 22000 --show your_file.hc22000`
- To re-crack: Delete or rename `hashcat.potfile`

## Advanced Usage

### Skip Phases
Edit the `.bat` file and comment out phases you don't want:
```batch
:: echo [*] Running Phase 6...
:: hashcat.exe -m 22000 -a 3 -O -w 4 --quiet --status --status-timer=30 %HASHFILE% ?d?d?d?d?d?d?d?d?d
```

### Add Custom Wordlists
Add after Phase 2:
```batch
if exist custom_thai.txt (
    echo [*] Running custom Thai wordlist...
    hashcat.exe -m 22000 -a 0 -O -w 4 --quiet --status --status-timer=15 %HASHFILE% custom_thai.txt
    call :check_cracked
)
```

### Change Status Update Frequency
Modify `--status-timer=15` to your preferred seconds (e.g., `--status-timer=30` for every 30 seconds)

### Adjust Workload
Change `-w 4` to:
- `-w 1` - Low (desktop usable)
- `-w 2` - Medium
- `-w 3` - High
- `-w 4` - Nightmare (maximum speed, system may lag)

## Security & Legal Notice

⚠️ **IMPORTANT:** This tool is for educational and authorized security testing only.

**Legal Use Cases:**
- Testing your own WiFi network security
- Authorized penetration testing with written permission
- Security research in controlled environments
- Educational purposes in cybersecurity courses

**Illegal Use:**
- Cracking WiFi passwords without authorization
- Accessing networks you don't own or have permission to test
- Any unauthorized network intrusion

**Disclaimer:** The author is not responsible for misuse of this tool. Always obtain proper authorization before testing any network security.

## FAQ

**Q: How long does it take to crack a password?**  
A: Depends on password complexity and your GPU. Simple passwords (dictionary): minutes. 8-digit numbers: 3-30 minutes. 9-digit numbers: 30-120 minutes.

**Q: Will this work on WPA3?**  
A: No, this is for WPA/WPA2 only. WPA3 uses a different protocol (SAE) that's much harder to crack.

**Q: Can I stop and resume later?**  
A: Yes! Hashcat saves progress. Press `Ctrl+C` to stop, then run again to resume. Already-cracked hashes are saved in `hashcat.potfile`.

**Q: Why is my GPU not being used?**  
A: Make sure you have proper GPU drivers installed. Check Hashcat output for "Device #1" - it should show your GPU name.

**Q: Can I use multiple GPUs?**  
A: Yes! Hashcat automatically detects and uses all available GPUs.

**Q: What if the password isn't found?**  
A: Try additional wordlists, custom masks based on target info, or longer brute-force attacks. Some passwords may be too complex to crack in reasonable time.

## Credits

- **Hashcat** - https://hashcat.net/
- **RockYou Wordlist** - https://github.com/brannondorsey/naive-hashcat
- **Script Author** - Optimized for Thai WiFi networks

## Version History

- **v1.0** - Initial release with 6 attack phases
- **v1.1** - Added time tracking and duplicate detection
- **v1.2** - Improved output formatting and error handling
- **v1.3** - Added Thai mobile prefix optimization

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Verify your Hashcat installation: `hashcat.exe --version`
3. Test your hash file: `hashcat.exe -m 22000 --show your_file.hc22000`
4. Check Hashcat documentation: https://hashcat.net/wiki/

---

**Happy (Ethical) Hacking! 🔐**
