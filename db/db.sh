rake db:create
rake db:seed
mysqlimport -u root --fields-terminated-by=, cancer_karyotypes -L cancer_lookup.txt
mysqlimport -u root --ignore-lines=4 cancer_karyotypes -L chromosome_bands.txt
