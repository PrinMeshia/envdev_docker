# tools to create php environment for symfony or laravel
---
COMPATIBILITY :
* tested on raspberryPi 4
* tested on wsl2 Ubuntu 22

---
WARNING:
for Laravel, some authorization is necessary

---
COMPONENTS

- PHP ^8.0
- mariaDB for RPI
- mysql for x86/64
- phpmyadmin
- maildev
- symfony or Laravel

REQUIRE 
 - whiptail

For the first launch execute `Init.sh`
---

For symfony 
The command `php bin/console`  can be launched by entering the command `symfony` 

for laravel 
The command `php artisan`  can be launched by entering the command `artisan` 
---

todo : 
- remove user password required 
- log installation => less information in screen
- show log in final
