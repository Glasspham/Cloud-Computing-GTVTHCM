# Dockerfile siêu nhẹ cho Frontend
FROM nginx:alpine

# Xóa file cấu hình Nginx mặc định của Docker
RUN rm /etc/nginx/conf.d/default.conf

# Copy file nginx.conf của bạn vào
COPY nginx.conf /etc/nginx/conf.d/

# Dòng phép thuật: Tiêu diệt ký tự \r của Windows
RUN sed -i 's/\r$//' /etc/nginx/conf.d/nginx.conf

# Copy thư mục build đã làm sẵn ở nhà vào thư mục web của Nginx
COPY build /usr/share/nginx/html

# [BẮT BUỘC THÊM DÒNG NÀY]: Cấp quyền đọc công khai cho toàn bộ file tĩnh
RUN chmod -R 755 /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]