# Cron processor

The cron processor is an addition for cron to handle the output of cronjobs 
via a database and a web interface instead of email.

It is not replacement of cron. 

If you manage one or more server and you have cronjobs, 
they send you an output by email. 
This can lead to flood your mailbox and important information can be overseen.

The cron processor stores all cron emails in a database 
and you will get a web interface to view all of your cronjobs 
searchable by status, title, hostname and by date.

Additionally you can send a digest of all jobs once per day by email.

See more information <a href="https://github.com/virtexxa/cronprocessor/wiki">here</a>
