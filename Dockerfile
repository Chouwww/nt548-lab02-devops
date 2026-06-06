FROM nginx:alpine

RUN apk update && apk upgrade --no-cache

RUN echo "<h1>NT548 - LAB02 - DEVOPS</h1><p>Hoan thanh Noi dung bai lab02!</p>" > /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]