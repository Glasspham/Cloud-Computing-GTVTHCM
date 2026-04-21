# Dockerfile siêu nhẹ cho Frontend
FROM nginx:alpine

# Xóa file cấu hình Nginx mặc định của Docker
RUN rm /etc/nginx/conf.d/default.conf

# Copy file nginx.conf của bạn vào
COPY nginx.conf /etc/nginx/conf.d/

# Copy thư mục build đã làm sẵn ở nhà vào thư mục web của Nginx
COPY build /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]