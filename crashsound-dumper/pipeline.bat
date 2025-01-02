@echo off
python a.py intermediates/%1.wav
python b.py intermediates/%1.bin
mv intermediates\*.gba .
python c.py out*.gba