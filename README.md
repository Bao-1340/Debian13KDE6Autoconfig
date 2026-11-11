# Debian 13 KDE 6 Auto Config

Bộ script cài lại ứng dụng và khôi phục cấu hình Debian 13 KDE hiện tại trên máy mới hoặc máy ảo.

## Yêu cầu

- Debian 13 `trixie` với KDE Plasma.
- Tài khoản người dùng có quyền `sudo`.
- Kết nối Internet.
- Git (`sudo apt install -y git`).

## Cài đặt

Chạy bằng tài khoản người dùng bình thường, không chạy bằng `root`:

```bash
git clone https://github.com/Bao-1340/Debian13KDE6Autoconfig.git
cd Debian13KDE6Autoconfig
chmod +x bootstrap.sh
./bootstrap.sh
sudo reboot
```

## Script sẽ làm gì?

- Khôi phục nguồn APT và cài lại các package đã lưu.
- Cài lại ứng dụng Flatpak và extension VSCodium.
- Khôi phục cấu hình KDE Plasma, Konsole, Zsh, GTK và Wireshark.
- Enable lại các systemd service cần thiết.
- Backup cấu hình cũ và ghi log các package không thể tự động cài.
- Chỉ cài driver NVIDIA khi máy có GPU NVIDIA.
