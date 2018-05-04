wget "https://sourceforge.net/projects/casparcg/files/CasparCG_Server/CasparCG%20Server%202.1.0%20Beta%201%20for%20Linux.tar.gz/download"
if [ "$?" -eq 0 ]; then
	tar -zxvf download
	rm -rf download
	mkdir CasparCGServer
	mv -T CasparCG\ Server CasparCGServer
	cp casparcg.config CasparCGServer
else
	printf "error dowloading file\n"
fi