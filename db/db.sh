mysql -uroot < create.sql
rake db:seed
mysqlimport -u root --fields-terminated-by=, cancer_karyotypes -L *.txt