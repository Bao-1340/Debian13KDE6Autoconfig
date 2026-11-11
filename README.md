# Debian 13 KDE 6 Auto Config

Bộ script tái tạo môi trường Debian 13 KDE hiện tại từ manifest và các cấu hình đã chọn lọc. Phù hợp để thử trên máy ảo hoặc dựng lại máy mới mà không phải cài và chỉnh từng ứng dụng bằng tay.

> Repo này là bản sao cấu hình, không phải disk image và không thay thế backup dữ liệu cá nhân.

## Yêu cầu

- Debian 13 `trixie` với KDE Plasma đã cài sẵn;
- tài khoản desktop thông thường có quyền `sudo`;
- kết nối Internet;
- Git đã được cài đặt.

Nếu máy mới chưa có Git:

```bash
sudo apt update
sudo apt install -y git
```

## Install

Chạy bằng tài khoản desktop bình thường, **không chạy bằng `root`**:

```bash
git clone https://github.com/Bao-1340/Debian13KDE6Autoconfig.git
cd Debian13KDE6Autoconfig
chmod +x bootstrap.sh
./bootstrap.sh
```

Nếu repository đang để private, GitHub sẽ yêu cầu đăng nhập hoặc Personal Access Token khi clone.

Sau khi script hoàn tất:

```bash
sudo reboot
```

## Script sẽ làm gì?

1. Xác nhận máy đang chạy Debian 13 `trixie`.
2. Backup nguồn APT hiện có trước khi thay đổi.
3. Khôi phục nguồn APT và public signing key đã lưu.
4. Cài lại các package APT thủ công còn khả dụng.
5. Cài lại ứng dụng Flatpak và extension VSCodium.
6. Backup cấu hình hiện tại rồi khôi phục KDE, Plasma, Konsole, Zsh, GTK, Wireshark và các dotfile đã chọn.
7. Enable lại các systemd service còn tồn tại trên máy mới.
8. Ghi log và danh sách package cần xử lý thủ công vào thư mục `.state/`.

Driver NVIDIA chỉ được cài khi máy đích thực sự phát hiện GPU NVIDIA.

## Kiểm tra snapshot trước khi dùng

```bash
./verify.sh
```

Kết quả hợp lệ phải kết thúc bằng:

```text
Secret scan passed.
Verification passed.
```

## Cập nhật snapshot từ máy nguồn

Khi đã thay đổi ứng dụng hoặc cấu hình trên máy chính:

```bash
cd Debian13KDE6Autoconfig
git pull --ff-only
./export-current-state.sh
./verify.sh
git add -A
git commit -m "Update Debian KDE snapshot"
git push
```

## Khôi phục lại trên máy ảo đã clone trước đó

```bash
cd Debian13KDE6Autoconfig
git pull --ff-only
./bootstrap.sh
sudo reboot
```

## Những thứ cố ý không đưa lên Git

- Documents, Downloads, OneDrive, ảnh, video và dữ liệu cá nhân;
- SSH/GPG private key, KWallet và KeePass database;
- token của trình duyệt, Insync, Remmina, Electerm, Codex/ChatGPT và Postman;
- browser profile, cookie, mật khẩu và lịch sử;
- binary lớn, AppImage và nội dung máy ảo;
- `/etc/fstab` và UUID ổ đĩa.

Những dữ liệu này cần được backup mã hóa riêng. Nên để repository ở chế độ **private** dù snapshot có kèm bước kiểm tra bí mật.

## Giới hạn

- VSCodium, Zoom, Electerm và VirtualBox được cài từ `.deb` thủ công có thể cần tải lại từ nhà cung cấp nếu repository tương ứng không còn hoạt động.
- Postman CLI trong `~/.local/bin` không được đưa vào Git vì binary lớn và có thể chứa trạng thái đăng nhập.
- APT key hoặc source bên thứ ba có thể hết hạn. Nếu `apt update` báo lỗi chữ ký, hãy cập nhật key từ nhà cung cấp; không tắt kiểm tra chữ ký.
- Layout Plasma phụ thuộc độ phân giải và số màn hình, vì vậy có thể cần chỉnh lại panel/widget trên phần cứng khác.

## Thư mục quan trọng

```text
bootstrap.sh                 Cài ứng dụng và khôi phục cấu hình
export-current-state.sh      Xuất lại trạng thái máy nguồn
verify.sh                    Kiểm tra script, manifest và bí mật
manifests/                   Danh sách package, Flatpak, extension, service
dotfiles/home/               Cấu hình người dùng đã chọn
system/apt/                  APT source và public signing key
scripts/                     Các bước phục hồi riêng lẻ
```
