create user myMariadbUser@'%' identified by 'myMariadbPassword';
grant all privileges on *.* to myMariadbUser@'%';
flush privileges;
quit