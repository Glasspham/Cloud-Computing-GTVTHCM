import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
    // Test với 100 user cùng lúc
    vus: 500,         // Chạy 100 user cùng lúc
    duration: '3m',  // Chạy trong 1 phút
};

export default function () {
    // API lấy danh sách dữ liệu public của bạn
    // Gọi thẳng vào /api/ để Spring Boot phải làm việc!
    const url = 'http://20.235.122.97/courses/find-all?page=1&limit=6'; // Thay bằng API của bạn, nhớ thêm query param để nó phải xử lý nặng nề hơn

    let res = http.get(url);
    
    // Kiểm tra xem Backend có sống sót trả về mã 200 không
    check(res, {
        'API tra ve thanh cong': (r) => r.status === 200,
    });

    // Mô phỏng user lướt xem 1 giây rồi lại đổi trang (hoặc F5)
    sleep(1); 
}