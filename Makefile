MD_FILE_LIST=index.md $(wildcard [0-9][0-9]*.md)
RMD_FILE_LIST=$(patsubst %.md,%.Rmd,$(MD_FILE_LIST))


all: Rmd

.PHONY: all Rmd

Rmd: $(RMD_FILE_LIST)

%.Rmd: %.md
	ln -sf $^ $@

.PHONY: html
html: Rmd
	Rscript -e "rmarkdown::render_site(output_format = 'bookdown::gitbook', encoding = 'UTF-8')"
	rm -rf html;
#	cd _book/; cp A-preambule.html index.html; cd ..
	mv _book/ html

.PHONY: pdf
pdf: Rmd
	Rscript -e "rmarkdown::render_site(output_format = 'bookdown::pdf_book', encoding = 'UTF-8')" || true;
	sed -i -e 's/\\BREAKME//g'  \
	    -e 's|documentclass\(.*\){book}|documentclass\1{latex/krantz}|g' \
	    -e 's|^.*usepackage.*geometry.*$$||g' \
	    -e 's|begin{center}\\large#1\\end{center}|begin{center}\\Large#1\\end{center}|g' \
	    -e 's|\\addcontentsline{toc}{chapter}{.*}||g' \
	    -e 's|author{\(.*\)Facilitatrice|author{\1\\\\\\medskip Facilitratice|g' \
	    booksprintrr.tex
	cp booksprintrr.tex booksprintrr.tex.bak
	cat booksprintrr.tex.bak |   \
	     perl -e 'while(<>) { if($$_=~/Redefines \\(sub\\)paragraphs/) {foreach $$i (1..8) {<>;}; next}; print($$_);}' |   \
	     perl -e 'while(<>) { if($$_=~/hypertarget\{section\}/) {<>; next}; print($$_);}'  \
	    > booksprintrr.tex
	xelatex booksprintrr.tex
	bibtex booksprintrr.aux
	xelatex booksprintrr.tex
	xelatex booksprintrr.tex

.PHONY: clean distclean
clean::
	#rm -rf booksprintrr.* _book/ rm -f *.Rmd;
	Rscript -e "rmarkdown::clean_site(encoding = 'UTF-8')"
	$(RM) *.Rmd
	$(RM) booksprintrr.aux booksprintrr.log booksprintrr.toc \
	  booksprintrr.blg booksprintrr.out booksprintrr.tex.bak

distclean:: clean
	rm -rf html

.PHONY: zip
zip: pdf html
	zip -r bookrr.zip html/ booksprintrr.pdf
