# Debian KDE Bootstrap

Repo này tái tạo môi trường Debian 13 KDE hiện tại bằng manifest và cấu hình có chọn lọc. Nó không phải ảnh đĩa và không thay thế backup dữ liệu cá nhân.

## Phục hồi trên máy mới

Yêu cầu: Debian 13 `trixie` với KDE, kết nối mạng và tài khoản có quyền `sudo`.

```bash
git clone <URL-REPO-RIÊNG-TƯ> debian-kde-bootstrap
cd debian-kde-bootstrap
./bootstrap.sh
```

Script sẽ:

1. kiểm tra Debian/KDE và xin quyền `sudo`;
2. phục hồi các nguồn APT cùng public signing key đã xuất;
3. cài lại các package APT thủ công còn khả dụng;
4. cài lại Flatpak và extension VSCodium;
5. backup cấu hình hiện có rồi phục hồi KDE, Konsole, Zsh và các dotfile đã chọn;
6. khôi phục trạng thái enable của các service còn tồn tại trên máy mới;
7. tạo báo cáo những package không thể tự động cài.

Sau khi chạy xong, đăng xuất/đăng nhập lại hoặc reboot để Plasma nạp đầy đủ cấu hình.

## Cập nhật snapshot từ máy nguồn

```bash
./export-current-state.sh
./verify.sh
git add -A
git commit -m "Update Debian KDE snapshot"
git push
```

## Những thứ cố ý không đưa lên Git

- dữ liệu trong Documents, Downloads, OneDrive, ảnh và video;
- SSH/GPG private key, KWallet, KeePass database;
- token của trình duyệt, Insync, Remmina, Electerm, Codex/ChatGPT, Postman;
- browser profile, cookie, mật khẩu và lịch sử;
- binary lớn/AppImage và nội dung máy ảo;
- `/etc/fstab` và UUID ổ đĩa để phục hồi tự động.

Những dữ liệu trên phải dùng backup mã hóa riêng. Nên để repo này ở chế độ **private** dù đã có kiểm tra bí mật.

## Giới hạn

- Package cài bằng `.deb` thủ công nhưng không có repository, hiện gồm VSCodium, Zoom, Electerm và VirtualBox, sẽ xuất hiện trong báo cáo thiếu và cần cài lại từ nhà cung cấp.
- Postman CLI trong `~/.local/bin` chỉ được ghi vào inventory vì binary quá lớn và có thể chứa trạng thái đăng nhập; nó không được đưa lên Git.
- Driver NVIDIA chỉ được cài nếu máy đích thực sự phát hiện GPU NVIDIA.
- APT key/source có thể hết hạn theo thời gian; nếu `apt update` báo lỗi chữ ký, hãy cập nhật key từ nhà cung cấp thay vì bỏ kiểm tra chữ ký.
