 #!/bin/bash
 
 check=$(su -c "psql -d postgres -c \"SELECT state FROM pg_stat_replication where state='streaming'\"" postgres | grep streaming)
 
 if [ "$check" = "" ]; then
 	echo "1"
 else
 	echo "0"
 fi
