#Just copy this cmd line and run in shell
rpm -e `rpm -qa dstat` && cd zstat && tar -zxvf dstat-master.gz; cd dstat-master/ && make install && cd .. && cp bin/* /usr/bin && echo 'zstat installed !'

