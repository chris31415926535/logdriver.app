FROM rhub/r-minimal

RUN apk add --no-cache --update-cache \
        --repository http://nl.alpinelinux.org/alpine/v3.11/main \
        autoconf=2.69-r2 \
        automake=1.16.1-r0 && \
    # repeat autoconf and automake (under `-t`)
    # to (auto)remove them after installation
    installr -d \
        -t "libsodium-dev curl-dev linux-headers autoconf automake" \
        -a libsodium \
        shiny
		
RUN installr -c && \
	apk add gfortran linux-headers &&\
	R -q -e 'install.packages(c("dplyr","dbplyr","DBI","RSQLite", "DT"), repos = "https://cloud.r-project.org")' && \
	rm -rf /usr/local/lib/R/library/*/html && \
	rm -rf /usr/local/lib/R/library/*/doc && \
	rm -rf /usr/local/lib/R/library/*/help && \
	apk del gcc musl-dev g++ linux-headers autoconf gfortran

RUN installr -c && \
	apk add libsodium-dev curl-dev gfortran linux-headers &&\
	R -q -e 'install.packages(c("plumber", "plotly"), repos = "https://cloud.r-project.org")'  && \
	rm -rf /usr/local/lib/R/library/*/html && \
	rm -rf /usr/local/lib/R/library/*/doc && \
	rm -rf /usr/local/lib/R/library/*/help && \
	apk del libsodium-dev curl-dev gcc musl-dev g++ linux-headers autoconf gfortran


RUN installr -c && \
	apk add gcc g++ libsodium-dev curl-dev gfortran linux-headers &&\
	R -q -e 'install.packages(c("lubridate"), repos = "https://cloud.r-project.org")'  && \
	rm -rf /usr/local/lib/R/library/*/html && \
	rm -rf /usr/local/lib/R/library/*/doc && \
	rm -rf /usr/local/lib/R/library/*/help && \
	apk del libsodium-dev curl-dev gcc musl-dev g++ linux-headers autoconf gfortran
	
RUN installr -c && \
	apk add cairo cairo-dev gcc g++ gfortran libsodium-dev curl-dev gfortran linux-headers libxt-dev &&\
	R -q -e 'install.packages(c("Cairo"), repos = "https://cloud.r-project.org")'  && \
	rm -rf /usr/local/lib/R/library/*/html && \
	rm -rf /usr/local/lib/R/library/*/doc && \
	rm -rf /usr/local/lib/R/library/*/help && \
	apk del cairo-dev gcc g++ gfortran libsodium-dev curl-dev gfortran linux-headers libxt-dev 

RUN apk add libxml2 cairo libx11 font-xfree86-type1
	
EXPOSE 8000 8080

COPY R/ R/
COPY * .

CMD ./start_plumber.sh & ./start_shiny.sh