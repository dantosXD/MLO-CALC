@echo off
cd /d "C:\Users\207ds\Desktop\Apps\MLO-CALC"
start "" python -m http.server 8080 --directory build/web
