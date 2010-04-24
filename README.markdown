Boxroom
=========
Boxroom is an open source project that aims to develop 
a web application for sharing and managing files online. 
The goal is to let a group of people share their files 
with eachother. To make this possible the application 
lets users create folders and upload and download files 
in a web browser. Furthermore for administrators it will 
be possible to create users, user groups and the CRU/D 
rights these groups will have on folders.


Thank you for trying Boxroom!

[Installation instructions](http://boxroom.rubyforge.org/how-to-install.html)


About kerinin's fork
-----------------
I wanted to use boxroom on Heroku, which presented two 
major challenges: Heroku uses a read-only filesystem and
doesn't support ferret.  

This fork uses the excellent Paperclip library to handle 
file storage, allowing S3 to be used as a backend.  Using
paperclip also makes defining image thumbnails and previews 
trivial.

Full-text search has been made more modular; you can now
use either Ferret or PostgreSQL's full-text indexing for
search (and implementing other libraries such as Solr would
be pretty easy).


