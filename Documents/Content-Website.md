# Drug Use Prevention Support System

## 📝Nội Dung Đề Tài

Phần mềm hỗ trợ phòng ngừa sử dụng ma túy

```
Guest
Member
Staff
Consultant
Manager
Admin
```

Phần mềm hỗ trợ phòng ngừa sử dụng ma túy trong cộng đồng của 01 tổ chức tình nguyện.

- Trang chủ giới thiệu thông tin tổ chức, blog chia sẽ kinh nghiệm, …
- Chức năng cho phép người dùng tìm kiếm và đăng ký các khóa học đào tạo online về ma túy (nhận thức ma túy, kỹ năng phòng tránh, kỹ năng từ chối, …), nội dung được phân theo độ tuổi (học sinh, sinh viên, phụ huynh, giáo viên, ...).
- Chức năng cho phép người dùng làm bài khảo sát trắc nghiệm như ASSIST, CRAFFT, ... để xác định mức độ nguy cơ sử dụng ma túy. Dựa trên kết quả đánh giá này hệ thống đề xuất hành động phù hợp cho người dùng (tham gia khóa đào tạo, gặp chuyên viên tư vấn, ...).
- Chức năng cho phép người dùng đặt lịch hẹn trực tuyến với chuyên viên tư vấn để hỗ trợ.
- Quản lý các chương trình truyền thông và giáo dục cộng đồng về ma túy. Ngoài ra hệ thống còn cho phép người dùng thực hiện các bài khảo sát trước/sau tham gia chương trình nhằm rút kinh nghiệm cải tiến chương trình.
- Quản lý thông tin chuyên viên tư vấn: thông tin chung, bằng cấp, chuyên môn, lịch làm việc, ...
- Quản lý hồ sơ người dùng, lịch sử đặt lịch hẹn trực tuyến, lịch sử tham gia các chương trình truyền thông và giáo dục cộng đồng.
- Dashboard & Report.

---

## 💻Languages and Tools

### Languages

> ⚛️Front-End

| React | TypeScript | JavaScript |
| :---: | :--------: | :--------: |
| <img src="https://github.com/devicons/devicon/blob/master/icons/react/react-original.svg" width="55" height="55"/> | <img src="https://github.com/devicons/devicon/blob/master/icons/typescript/typescript-original.svg" width="55" height="55"/> | <img src="https://github.com/devicons/devicon/blob/master/icons/javascript/javascript-original.svg" width="55" height="55"/> |

> 🛠️Back-End

| Java | Spring-boot |
| :--: | :---------: |
| <img src="https://github.com/devicons/devicon/blob/master/icons/java/java-original.svg" width="55" height="55"/> | <img src="https://github.com/devicons/devicon/blob/master/icons/spring/spring-original.svg" width="55" height="55"/> |

> 🛢Database

| MySQL |
| :---: |
| <img src="https://github.com/devicons/devicon/blob/master/icons/mysql/mysql-original.svg" width="55" height="55"/> |

> 🔧Tools

| Maven | Docker | Git |
| :---: | :----: | :-: |
| <img src="https://github.com/devicons/devicon/blob/master/icons/maven/maven-original.svg" width="55" height="55"/> | <img src="https://github.com/devicons/devicon/blob/master/icons/docker/docker-original.svg" width="55" height="55"/> | <img src="https://github.com/devicons/devicon/blob/master/icons/git/git-original.svg" width="55" height="55"/> |

> IDE/Text Editor

| Vscode | Intellij |
| :----: | :------: |
| <img src="https://github.com/devicons/devicon/blob/master/icons/vscode/vscode-original.svg" width="55" height="55"/> | <img src="https://github.com/devicons/devicon/blob/master/icons/intellij/intellij-original.svg" width="55" height="55"/> |

---

## 🚀Hướng dẫn chạy

1. **Yêu cầu môi trường:**

   - Docker Desktop

2. **Chạy Docker Compose:**

   - Ở thư mục gốc project, chạy lệnh:
     ```pwsh
     docker-compose up -d --build
     ```
   - Docker sẽ tự động build và chạy cả Backend và Frontend.
   - Backend mặc định chạy ở `http://localhost:8080`, Frontend ở `http://localhost:80`.

3. **Dừng các container:**
   - Nhấn `Ctrl+C` trong terminal hoặc chạy:
     ```pwsh
     docker-compose down
     ```

---

## Tổng quan về dự án

Đọc file [Project-Overview.md](Project-Overview.md)