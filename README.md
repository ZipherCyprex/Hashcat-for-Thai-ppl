# Hashcat for Thai ppl

สคริปต์ `.bat` สำหรับรัน Hashcat กับไฟล์ WiFi handshake (`.hc22000`) โดยจัดลำดับ wordlist/mask ให้เข้ากับแพตเทิร์นที่เจอบ่อยในไทย

[English README](en/README.md)

## ต้องมี

- Windows
- `hashcat.exe` v6 ขึ้นไป
- ไฟล์ handshake แบบ `.hc22000` (WPA/WPA2)
- `rockyou.txt` สำหรับ dictionary phase
- `rules\best66.rule` สำหรับ rules phase

วาง `CRACK_V2.bat` ไว้โฟลเดอร์เดียวกับ `hashcat.exe`

## ใช้งาน

ลากไฟล์ `.hc22000` ไปวางบน `CRACK_V2.bat`

หรือรันผ่าน command line:

```cmd
CRACK_V2.bat your_capture.hc22000
```

ตอนเริ่มโปรแกรมจะให้เลือก:

- `START` ใช้ค่า default: auto device + Standard
- `SETTINGS` เลือก GPU/CPU และระดับการค้นหาเอง

## ระดับการค้นหา

| Level | ชื่อ | สิ่งที่รัน |
| --- | --- | --- |
| 1 | Fast | `rockyou.txt`, วันเกิด, เลข 8 หลัก, เบอร์มือถือไทย |
| 2 | Standard | Fast + `best66.rule`, เลข 9 หลัก |
| 3 | Extended | Standard + เลข 10 หลัก |
| 4 | Extreme | Extended + เลข 11-12 หลัก |

Hashcat key:

- `S` ดูสถานะ
- `P` pause
- `B` ข้าม phase
- `Q` ออก

## ไฟล์ที่สคริปต์สร้าง

- `thaiprefix.txt`
- `birthdate_patterns.txt`
- `hashcat.potfile`
- `temp_devices.txt` ชั่วคราว

## แก้ปัญหาสั้นๆ

- `hashcat.exe not found`: วางสคริปต์ไว้โฟลเดอร์เดียวกับ `hashcat.exe`
- ได้ไฟล์ `.cap` หรือ `.pcap`: แปลงเป็น `.hc22000` ก่อนที่ <https://hashcat.net/cap2hashcat/>
- `rockyou.txt` หรือ `best66.rule` ไม่มี: phase นั้นจะถูกข้ามหรือดาวน์โหลดไม่สำเร็จ ให้วางไฟล์เอง
- ช้ามาก: เช็กว่า Hashcat เห็น GPU และไดรเวอร์พร้อม

## หมายเหตุ

ใช้กับเครือข่ายของตัวเองหรือที่ได้รับอนุญาตเท่านั้น ผู้พัฒนาไม่รับผิดชอบต่อการนำไปใช้ผิดกฎหมาย

## เครดิต

- Hashcat: <https://hashcat.net/>
- RockYou wordlist: <https://github.com/brannondorsey/naive-hashcat>
