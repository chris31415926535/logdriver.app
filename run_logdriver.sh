docker run -d -p 8000:8000 -p 8080:8080 --mount type=bind,source=/home/christopher/R/logdriver.app/logs,target=/root/logs logdriver:dev2
